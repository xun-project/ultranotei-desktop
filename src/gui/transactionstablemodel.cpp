#include "transactionstablemodel.h"
#include "WalletAdapter.h"
#include "NodeAdapter.h"
#include "CurrencyAdapter.h"
#include "Message.h"
#include "DepositModel.h"
#include <QDateTime>
#include <QPixmap>
#include <QTextStream>
#include <QDebug>
#include <algorithm>
#include <QTextDocumentFragment>

namespace WalletGui {

TransactionsTableModel::TransactionsTableModel(QObject *parent) : QAbstractTableModel(parent),
    m_transactionDetailsTemplate(
        "<html><head><meta name=\"qrichtext\" content=\"1\" /><style type=\"text/css\">\n"
        "</style></head><body style=\" font-family:'Cantarell'; font-size:11pt; font-weight:400; font-style:normal;\">\n"
        "<span style=\" font-weight:600;\">Status: </span>%1</p><br>\n"
        "<span style=\" font-weight:600;\">Date: </span>%2</p><br>\n"
        "<span style=\" font-weight:600;\">To: </span>%4</p><br>\n"
        "<span style=\" font-weight:600;\">Amount: </span>%5</p><br>\n"
        "<span style=\" font-weight:600;\">Fee: </span>%6</p><br>\n"
        "<span style=\" font-weight:600;\">Transaction hash: </span>%8</p><br><br>\n"
        "<span style=\" font-weight:600;\">Messages: </span></p><br>%9<br><br>\n"
        "%10"
        "</body></html>")
{
}

int TransactionsTableModel::rowCount(const QModelIndex &index) const
{
    Q_UNUSED(index)
    return m_rowCount;
}

int TransactionsTableModel::columnCount(const QModelIndex &index) const
{
    Q_UNUSED(index)
    return ColumnName::Count;
}

QVariant TransactionsTableModel::data(const QModelIndex &index, int role) const
{
    const int col = index.column();
    const int row = index.row();

    QVariant out = QString();
    if ((0 > row) || (row >= m_transfers.size())) {
        return out;
    }

    const cn::TransactionId transactionId = m_transfers.value(row).first;
    const cn::TransferId transferId = m_transfers.value(row).second;

    cn::WalletLegacyTransaction transaction;
    cn::WalletLegacyTransfer transfer;
    if(!WalletAdapter::instance().getTransaction(transactionId, transaction) ||
            (transferId != cn::WALLET_LEGACY_INVALID_TRANSFER_ID &&
             !WalletAdapter::instance().getTransfer(transferId, transfer))) {
        return out;
    }

    cn::DepositId depositId = transaction.firstDepositId;
    cn::Deposit deposit;
    if (depositId != cn::WALLET_LEGACY_INVALID_DEPOSIT_ID) {
        if(!WalletAdapter::instance().getDeposit(depositId, deposit)) {
            return QVariant();
        }
    }

    switch (role) {
    case Qt::DisplayRole:
        switch (col) {
        case State: {
            const quint64 numberOfConfirmations = (transaction.blockHeight == cn::WALLET_LEGACY_UNCONFIRMED_TRANSACTION_HEIGHT ? 0 : NodeAdapter::instance().getLastKnownBlockHeight() - transaction.blockHeight + 1);
            out = stateIcon(numberOfConfirmations);
        }
            break;
        case Date: {
            const QDateTime date = (transaction.timestamp > 0 ? QDateTime::fromTime_t(static_cast<uint>(transaction.timestamp)) : QDateTime());
            out = (date.isNull() || !date.isValid() ? "-" : date.toString("yyyy-MM-dd HH:mm"));
        }
            break;
        case Amount: {
			const qint64 amount = getAmount(transaction, transfer, transferId, deposit);
			const QString amountStr = CurrencyAdapter::instance().formatAmount(qAbs(amount));
			out = (amount < 0 ? "-" + amountStr : amountStr);
        }
            break;
        case Address: {
            const TransactionType transactionType =
                    static_cast<TransactionType>(roleType(transaction,transfer));
            const QString transactionAddress = QString::fromStdString(transfer.address);
            if (transactionType == TransactionType::INPUT ||
                    transactionType == TransactionType::MINED ||
                    transactionType == TransactionType::INOUT) {
                return QString(tr("me (%1)").arg(WalletAdapter::instance().getAddress()));
            } else if (transactionAddress.isEmpty()) {
                return tr("(n/a)");
            }
            out = transactionAddress;
        }
            break;
        case Message:
            if (!transaction.messages.empty()) {
                const WalletGui::Message msg(QString::fromStdString(transaction.messages[0]));
                QString messageString = msg.getMessage();
                QTextStream messageStream(&messageString);
                out = messageStream.readLine();
            }
            break;
        case PaymentId:
            out = NodeAdapter::instance().extractPaymentId(transaction.extra);
            break;
        default:
            ;
        }
        break;
    default:
        ;
    }

    return out;
}

QHash<int, QByteArray> TransactionsTableModel::roleNames() const
{
    static const auto roles = QHash<int, QByteArray>{
        { Qt::DisplayRole, "display" }
    };
    return roles;
}

QString TransactionsTableModel::columnName(int index)
{
    QString name;
    switch (index) {
    case ColumnName::State:
        name.clear();
        break;
    case ColumnName::Date:
        name = getColumnName(Date);
        break;
    case ColumnName::Amount:
        name = getColumnName(Amount);
        break;
    case ColumnName::Address:
        name = getColumnName(Address);
        break;
    case ColumnName::Message:
        name = getColumnName(Message);
        break;
    case ColumnName::PaymentId:
        name = getColumnName(PaymentId);
        break;
    }
    return name;
}

QString TransactionsTableModel::transactionIcon(int row) const
{
    QString icon;
    if ((0 > row) || (row >= m_transfers.size())) {
        return icon;
    }

    const cn::TransactionId transactionId = m_transfers.value(row).first;
    const cn::TransferId transferId = m_transfers.value(row).second;

    cn::WalletLegacyTransaction transaction;
    cn::WalletLegacyTransfer transfer;
    if(!WalletAdapter::instance().getTransaction(transactionId, transaction) ||
            (transferId != cn::WALLET_LEGACY_INVALID_TRANSFER_ID &&
             !WalletAdapter::instance().getTransfer(transferId, transfer))) {
        return icon;
    }
    const TransactionType transactionType = static_cast<TransactionType>(roleType(transaction,
                                                                            transfer));
    switch (transactionType) {
    case TransactionType::MINED:
        icon = "qrc:/icons/tx-mined";
        break;
    case TransactionType::INPUT:
        icon = "qrc:/icons/tx-input";
        break;
    case TransactionType::OUTPUT:
        icon = "qrc:/icons/tx-output";
        break;
    case TransactionType::INOUT:
        icon = "qrc:/icons/tx-inout";
        break;
    case TransactionType::DEPOSIT:
        icon = "qrc:/icons/tx-deposit";
        break;
    default:
        break;
    }
    return icon;
}

void TransactionsTableModel::setupTransactionDetails(int row)
{
    if ((0 > row) || (row >= m_transfers.size())) {
        qCritical() << "Invalid row" << row;
        return;
    }

    const cn::TransactionId transactionId = m_transfers.value(row).first;
    const cn::TransferId transferId = m_transfers.value(row).second;

    cn::WalletLegacyTransaction transaction;
    cn::WalletLegacyTransfer transfer;
    if(!WalletAdapter::instance().getTransaction(transactionId, transaction) ||
            (transferId != cn::WALLET_LEGACY_INVALID_TRANSFER_ID &&
             !WalletAdapter::instance().getTransfer(transferId, transfer))) {
        qCritical() << "Cannot get transaction";
        return;
    }
    cn::DepositId depositId = transaction.firstDepositId;
    cn::Deposit deposit;
    if (depositId != cn::WALLET_LEGACY_INVALID_DEPOSIT_ID) {
        if(!WalletAdapter::instance().getDeposit(depositId, deposit)) {
            qCritical() << "Cannot get deposit";
            return;
        }
    }

    quint64 numberOfConfirmations = 0;
    if (transaction.blockHeight != cn::WALLET_LEGACY_UNCONFIRMED_TRANSACTION_HEIGHT) {
          numberOfConfirmations = NodeAdapter::instance().getLastKnownBlockHeight() -
                  transaction.blockHeight + 1;
    }
	const qint64 amount = getAmount(transaction, transfer, transferId, deposit);
    QString amountText = CurrencyAdapter::instance().formatAmount(qAbs(amount)) + " " +
            CurrencyAdapter::instance().getCurrencyTicker().toUpper();

	if (transaction.totalAmount < 0)
		amountText.prepend("-");

    const QString feeText = CurrencyAdapter::instance().formatAmount(transaction.fee) + " " +
        CurrencyAdapter::instance().getCurrencyTicker().toUpper();

    QStringList messageList;
    messageList.reserve(static_cast<int>(transaction.messages.size()));
    for (const auto& message: transaction.messages) {
		messageList << QTextDocumentFragment::fromHtml(QString::fromStdString(message)).toPlainText();
    }
    for (quint32 i = 0; i < messageList.size(); ++i) {
        messageList[i] = messageList[i].toHtmlEscaped().replace("\n", "<br/>");
    }

    QString depositInfo;
    if (depositId != cn::WALLET_LEGACY_INVALID_DEPOSIT_ID) {
        QModelIndex depositIndex = DepositModel::instance().index(static_cast<int>(depositId), 0);
        QString depositAmount = depositIndex.sibling(depositIndex.row(), DepositModel::COLUMN_AMOUNT).data().toString() + " " +
                CurrencyAdapter::instance().getCurrencyTicker().toUpper();
        QString depositInterest = depositIndex.sibling(depositIndex.row(), DepositModel::COLUMN_INTEREST).data().toString() + " " +
                CurrencyAdapter::instance().getCurrencyTicker().toUpper();
        QString depositSum = depositIndex.sibling(depositIndex.row(), DepositModel::COLUMN_SUM).data().toString() + " " +
                CurrencyAdapter::instance().getCurrencyTicker().toUpper();
        QString depositInfoTemplate =
                "<span style=\" font-weight:600;\">Deposit info: </span></p><br>\n"
                "<span style=\" font-weight:600;\">Status: </span>%1</p><br>\n"
                "<span style=\" font-weight:600;\">Amount: </span>%2</p><br>\n"
                "<span style=\" font-weight:600;\">Interest: </span>%3</p><br>\n"
                "<span style=\" font-weight:600;\">Sum: </span>%4</p><br>\n"
                "<span style=\" font-weight:600;\">Term interest rate: </span>%5</p><br>\n"
                "<span style=\" font-weight:600;\">Term: </span>%6</p><br>\n"
                "<span style=\" font-weight:600;\">Unlock height: </span>%7</p><br>\n"
                "<span style=\" font-weight:600;\">Expected unlock time: </span>%8</p><br>\n"
                "<span style=\" font-weight:600;\">Creating transaction: </span>%9</p><br>\n"
                "<span style=\" font-weight:600;\">Creating height: </span>%10</p><br>\n"
                "<span style=\" font-weight:600;\">Creating time: </span>%11</p><br>\n"
                "<span style=\" font-weight:600;\">Spending transaction: </span>%12</p><br>\n"
                "<span style=\" font-weight:600;\">Spending height: </span>%13</p><br>\n"
                "<span style=\" font-weight:600;\">Spending time: </span>%14</p><br>\n";
        depositInfo = depositInfoTemplate.
                arg(depositIndex.sibling(depositIndex.row(), DepositModel::COLUMN_STATE).data().toString()).
                arg(depositAmount).
                arg(depositInterest).arg(depositSum).
                arg(depositIndex.sibling(depositIndex.row(), DepositModel::COLUMN_TERM_RATE).data().toString()).
                arg(depositIndex.sibling(depositIndex.row(), DepositModel::COLUMN_TERM).data().toString()).
                arg(depositIndex.sibling(depositIndex.row(), DepositModel::COLUMN_UNLOCK_HEIGHT).data().toString()).
                arg(depositIndex.sibling(depositIndex.row(), DepositModel::COLUMN_UNLOCK_TIME).data().toString()).
                arg(depositIndex.sibling(depositIndex.row(), DepositModel::COLUMN_CREATRING_TRANSACTION_HASH).data().toString()).
                arg(depositIndex.sibling(depositIndex.row(), DepositModel::COLUMN_CREATING_HEIGHT).data().toString()).
                arg(depositIndex.sibling(depositIndex.row(), DepositModel::COLUMN_CREATING_TIME).data().toString()).
                arg(depositIndex.sibling(depositIndex.row(), DepositModel::COLUMN_SPENDING_TRANSACTION_HASH).data().toString()).
                arg(depositIndex.sibling(depositIndex.row(), DepositModel::COLUMN_SPENDING_HEIGHT).data().toString()).
                arg(depositIndex.sibling(depositIndex.row(), DepositModel::COLUMN_SPENDING_TIME).data().toString());
    }

    const QDateTime date = (transaction.timestamp > 0 ? QDateTime::fromTime_t(static_cast<uint>(transaction.timestamp)) : QDateTime());
    const QString dateStr = (date.isNull() || !date.isValid() ? "-" : date.toString("yyyy-MM-dd HH:mm"));

    const TransactionType transactionType =
            static_cast<TransactionType>(roleType(transaction,transfer));
    QString transactionAddress = QString::fromStdString(transfer.address);
    if (transactionType == TransactionType::INPUT ||
            transactionType == TransactionType::MINED ||
            transactionType == TransactionType::INOUT) {
        transactionAddress = QString(tr("me (%1)").arg(WalletAdapter::instance().getAddress()));
    } else if (transactionAddress.isEmpty()) {
        transactionAddress = tr("(n/a)");
    }

    const QByteArray hash = QByteArray(reinterpret_cast<const char*>(&transaction.hash), sizeof(transaction.hash));

    setTransactionDetails(m_transactionDetailsTemplate.arg(QString("%1 confirmations").arg(numberOfConfirmations)).
                          arg(dateStr).arg(transactionAddress).arg(amountText).arg(feeText).
                          arg(hash.toHex().toUpper().data()).
                          arg(messageList.join("<br/><br/>=========<br/><br/>")).
                          arg(depositInfo));
}

void TransactionsTableModel::exportToCsv(const QUrl &fileUrl)
{
    const QString fileName = fileUrl.toLocalFile();
    QFile f(fileName);
    if (f.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        f.write(toCsv());
        f.close();
    } else {
        qCritical() << "Cannot write file" << fileName;
    }
}

void TransactionsTableModel::reloadWalletTransactions()
{
    emit layoutAboutToBeChanged();
    m_transfers.clear();
    m_transactionRow.clear();

    quint32 row_count = 0;
    for (cn::TransactionId transactionId = 0; transactionId < WalletAdapter::instance().getTransactionCount(); ++transactionId) {
        appendTransaction(transactionId, row_count);
    }
    sortTransfers();
    emit layoutChanged();
    setRowCount(static_cast<int>(row_count));
}

void TransactionsTableModel::appendTransaction(cn::TransactionId _transactionId,
                                               quint32& _insertedRowCount)
{
    cn::WalletLegacyTransaction transaction;
    if (!WalletAdapter::instance().getTransaction(_transactionId, transaction)) {
        return;
    }

    if (transaction.transferCount) {
        m_transactionRow[_transactionId] = qMakePair(m_transfers.size(), transaction.transferCount);
        for (cn::TransferId transfer_id = transaction.firstTransferId;
             transfer_id < transaction.firstTransferId + transaction.transferCount; ++transfer_id) {
            m_transfers.append(TransactionTransferId(_transactionId, transfer_id));
            ++_insertedRowCount;
        }
    } else {
        m_transfers.append(TransactionTransferId(_transactionId, cn::WALLET_LEGACY_INVALID_TRANSFER_ID));
        m_transactionRow[_transactionId] = qMakePair(m_transfers.size() - 1, 1);
        ++_insertedRowCount;
    }
}

void TransactionsTableModel::appendTransaction(cn::TransactionId _transactionId)
{
    if (m_transactionRow.contains(_transactionId)) {
        return;
    }


    quint32 insertedRowCount = static_cast<quint32>(m_transactionRow.size());
	appendTransaction(_transactionId, insertedRowCount);

	sortTransfers();
	emit layoutAboutToBeChanged();
	emit layoutChanged();
	setRowCount(static_cast<int>(insertedRowCount));
    //reloadWalletTransactions();
}

void TransactionsTableModel::updateWalletTransaction(cn::TransactionId _id)
{
    Q_UNUSED(_id)
    emit layoutAboutToBeChanged();
    emit layoutChanged();
}

void TransactionsTableModel::lastKnownHeightUpdated(quint64 _height)
{
    Q_UNUSED(_height)
    emit layoutAboutToBeChanged();
    emit layoutChanged();
}

void TransactionsTableModel::reset()
{
    emit layoutAboutToBeChanged();
    m_transfers.clear();
    m_transactionRow.clear();
    emit layoutChanged();
    setRowCount(0);
}

QVariant TransactionsTableModel::stateIcon(quint64 numberOfConfirmations)
{
    QString icon;
    switch (numberOfConfirmations) {
    case 0:
        icon = "qrc:/icons/unconfirmed";
        break;
    case 1: case 2:
        icon = "qrc:/icons/clock1";
        break;
    case 3: case 4:
        icon = "qrc:/icons/clock2";
        break;
    case 5: case 6:
        icon = "qrc:/icons/clock3";
        break;
    case 7: case 8:
        icon = "qrc:/icons/clock4";
        break;
    case 9:
        icon = "qrc:/icons/clock5";
        break;
    default:
        icon = "qrc:/icons/transaction";
    }
    return icon;
}

qint64 TransactionsTableModel::getAmount(cn::WalletLegacyTransaction transaction,
                                      const cn::WalletLegacyTransfer &transfer,
                                      const cn::TransferId transferId,
                                      const cn::Deposit &deposit)
{
    TransactionType transactionType = static_cast<TransactionType>(roleType(transaction,
                                                                            transfer));
    if (transactionType == TransactionType::INPUT || transactionType == TransactionType::MINED) {
        return static_cast<qint64>(transaction.totalAmount);
    } else if (transactionType == TransactionType::OUTPUT || transactionType == TransactionType::INOUT) {
        if (transferId == cn::WALLET_LEGACY_INVALID_TRANSFER_ID) {
            return static_cast<qint64>(transaction.totalAmount);
        }

        return static_cast<qint64>(-transfer.amount);
    } else if (transactionType == TransactionType::DEPOSIT) {
        return static_cast<qint64>(-(transaction.fee + deposit.amount));
    }

    return 0;
}

quint8 TransactionsTableModel::roleType(cn::WalletLegacyTransaction transaction,
                                        const cn::WalletLegacyTransfer &transfer)
{
    QString transactionAddress = QString::fromStdString(transfer.address);
    if(transaction.isCoinbase) {
        return static_cast<quint8>(TransactionType::MINED);
    } else if (transaction.firstDepositId != cn::WALLET_LEGACY_INVALID_DEPOSIT_ID) {
        return static_cast<quint8>(TransactionType::DEPOSIT);
    } else if (!transactionAddress.compare(WalletAdapter::instance().getAddress())) {
        return static_cast<quint8>(TransactionType::INOUT);
    } else if(transaction.totalAmount < 0) {
        return static_cast<quint8>(TransactionType::OUTPUT);
    }

    return static_cast<quint8>(TransactionType::INPUT);
}

void TransactionsTableModel::sortTransfers()
{
    std::sort(m_transfers.begin(), m_transfers.end(),
              [&](TransactionTransferId &left, TransactionTransferId &right) {
        const cn::TransactionId leftTransactionId = left.first;
        const cn::TransactionId rightTransactionId = right.first;
        cn::WalletLegacyTransaction leftTransaction;
        cn::WalletLegacyTransaction rightTransaction;
        if (WalletAdapter::instance().getTransaction(leftTransactionId, leftTransaction) &&
            WalletAdapter::instance().getTransaction(rightTransactionId, rightTransaction)) {
            const QDateTime leftDate = (leftTransaction.timestamp > 0 ? QDateTime::fromTime_t(static_cast<uint>(leftTransaction.timestamp)) : QDateTime());
            const QDateTime rightDate = (rightTransaction.timestamp > 0 ? QDateTime::fromTime_t(static_cast<uint>(rightTransaction.timestamp)) : QDateTime());
            if (leftDate.isNull() || !leftDate.isValid()) {
                return true;
            }
            if (rightDate.isNull() || !rightDate.isValid()) {
                return false;
            }
            return leftDate > rightDate;
        }
        return true;//should not happen
    });
}

QByteArray TransactionsTableModel::toCsv() const
{
    QByteArray res;
    res.append("\"State\",\"Date\",\"Amount\",\"Fee\",\"Hash\",\"Height\",\"Address\",\"Payment ID\"\n");
    for (int row = 0; row < m_rowCount; ++row) {
        if ((0 > row) || (row >= m_transfers.size())) {
            qCritical() << "Invalid row" << row;
            continue;
        }
        const cn::TransactionId transactionId = m_transfers.value(row).first;
        const cn::TransferId transferId = m_transfers.value(row).second;

        cn::WalletLegacyTransaction transaction;
        cn::WalletLegacyTransfer transfer;
        if(!WalletAdapter::instance().getTransaction(transactionId, transaction) ||
                (transferId != cn::WALLET_LEGACY_INVALID_TRANSFER_ID &&
                 !WalletAdapter::instance().getTransfer(transferId, transfer))) {
            qCritical() << "Cannot get transaction";
            continue;
        }
        cn::DepositId depositId = transaction.firstDepositId;
        cn::Deposit deposit;
        if (depositId != cn::WALLET_LEGACY_INVALID_DEPOSIT_ID) {
            if(!WalletAdapter::instance().getDeposit(depositId, deposit)) {
                qCritical() << "Cannot get deposit";
                continue;
            }
        }

        quint64 numberOfConfirmations = 0;
        if (transaction.blockHeight != cn::WALLET_LEGACY_UNCONFIRMED_TRANSACTION_HEIGHT) {
            numberOfConfirmations = NodeAdapter::instance().getLastKnownBlockHeight() -
                    transaction.blockHeight + 1;
        }
        const QString text = (numberOfConfirmations == 0 ? tr("unconfirmed") : tr("confirmations"));
        res.append("\"").append(tr("%1 / %2").arg(numberOfConfirmations).arg(text).toUtf8()).append("\",");

        const QDateTime date = (transaction.timestamp > 0 ? QDateTime::fromTime_t(static_cast<uint>(transaction.timestamp)) : QDateTime());
        const QString dateStr = (date.isNull() || !date.isValid() ? "-" : date.toString("yyyy-MM-dd HH:mm"));
        res.append("\"").append(dateStr.toUtf8()).append("\",");

        const qint64 amount = getAmount(transaction, transfer, transactionId, deposit);
        QString amountStr = CurrencyAdapter::instance().formatAmount(qAbs(amount));
        amountStr = (amount < 0 ? "-" + amountStr : amountStr);
        res.append("\"").append(amountStr.toUtf8()).append("\",");

        const QString feeText = CurrencyAdapter::instance().formatAmount(transaction.fee);
        res.append("\"").append(feeText.toUtf8()).append("\",");

        const QString hash = QByteArray(reinterpret_cast<const char*>(&transaction.hash), sizeof(transaction.hash)).toHex().toUpper();
        res.append("\"").append(hash.toUtf8()).append("\",");

        const quint64 transactionHeight = static_cast<quint64>(transaction.blockHeight);
        QString transactionHeightStr;
        if (transactionHeight != cn::WALLET_LEGACY_UNCONFIRMED_TRANSACTION_HEIGHT) {
            transactionHeightStr = QString::number(transactionHeight);
        }
        res.append("\"").append(transactionHeightStr.toUtf8()).append("\",");

        const TransactionType transactionType =
                static_cast<TransactionType>(roleType(transaction,transfer));
        QString transactionAddress = QString::fromStdString(transfer.address);
        if (transactionType == TransactionType::INPUT ||
                transactionType == TransactionType::MINED ||
                transactionType == TransactionType::INOUT) {
            transactionAddress = QString(tr("me (%1)").arg(WalletAdapter::instance().getAddress()));
        } else if (transactionAddress.isEmpty()) {
            transactionAddress = tr("(n/a)");
        }
        res.append("\"").append(transactionAddress.toUtf8()).append("\",");

        const QString paymentId = NodeAdapter::instance().extractPaymentId(transaction.extra);
        res.append("\"").append(paymentId.toUtf8()).append("\"\n");
    }

    return res;
}

QString TransactionsTableModel::getColumnName(ColumnName columnName)
{
    QString headerName;

    if (!m_columnNameList.isEmpty())
    {
        headerName = m_columnNameList.at(columnName - 1);
    }
    else
    {
        switch (columnName)
        {
        case Date:
            headerName = "Date";
            break;
        case Amount:
            headerName = "Amount";
            break;
        case Address:
            headerName = "Address";
            break;
        case Message:
            headerName = "Message";
            break;
        case PaymentId:
            headerName = "PaymentId";
            break;
        default:
            break;
        }
    }

    return headerName;
}

} // WalletGui
