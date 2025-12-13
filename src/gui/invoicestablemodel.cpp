#include "invoicestablemodel.h"
#include "WalletAdapter.h"
#include "CurrencyAdapter.h"
#include "../qzipreader_p.h"
#include <QTextStream>
#include <QNetworkReply>
#include <QTemporaryFile>
#include <QDir>
#include <QDebug>

namespace WalletGui {

Q_DECL_CONSTEXPR quint64 DOWNLOAD_BUFFER_SIZE = 100 * 1024 * 1024;

static
const QString HEADER_REPLY_TO_KEY = "Reply-To";
static
const QString HEADER_ATTACHMENT = "Attachment";
static
const QString HEADER_ATTACHMENT_ENCRYPTION_KEY = "Attachment-Encryption-Key";
static
const QString IPFS_API_URL = "http://backup.ultranote.org:8080/ipfs/";
const QString HEADER_INVOICE_ID = "Invoice-ID";
const QString HEADER_INVOICE_AMOUNT = "Invoice-Amount";
const QString HEADER_PAYMENT_ID = "Payment-ID";

InvoiceTableModel::InvoiceTableModel(QObject *parent) : QAbstractTableModel(parent)
{
    initUnseenCacheFile();
    connect(&m_networAccesskManager, &QNetworkAccessManager::finished, this,
            &InvoiceTableModel::attachmentDownloaded);
}

int InvoiceTableModel::rowCount(const QModelIndex &index) const
{
    Q_UNUSED(index)
    return m_invoices.size();
}

int InvoiceTableModel::columnCount(const QModelIndex &index) const
{
    Q_UNUSED(index)
    return ColumnName::Count;
}

QVariant InvoiceTableModel::data(const QModelIndex &index, int role) const
{
    const int col = index.column();
    const int row = index.row();

    if ((0 > row) || (m_invoices.size() <= row)) {
        qCritical() << "Invalid row index" << row;
        return QVariant();
    }

    cn::WalletLegacyTransaction transaction;
    cn::TransactionId transactionId = m_invoices.value(row).first;
    WalletGui::Message message = m_invoices.value(row).second;
    if(!WalletAdapter::instance().getTransaction(transactionId, transaction)) {
      return QVariant();
    }

    QVariant out;
    switch (role) {
    case Qt::DisplayRole:
        switch (col) {
        case Unread:
            // Unread column is handled by the QML delegate using getReadState()
            out = "";
            break;
        case Date: {
            const auto date = (transaction.timestamp > 0 ? QDateTime::fromTime_t(static_cast<uint>(transaction.timestamp)) : QDateTime());
            out = (date.isNull() || !date.isValid() ? "-" : date.toString("yyyy-MM-dd HH:mm"));
        }
            break;
        case Type:
            out = (transaction.totalAmount < 0) ? tr("Out") : tr("In");
            break;
        case Height: {
            const auto height = transaction.blockHeight;
            out = (height == cn::WALLET_LEGACY_UNCONFIRMED_TRANSACTION_HEIGHT ? "-" : QString::number(height));
        }
            break;
        case Message: {
            auto msg = message.getMessage();
            QTextStream messageStream(&msg);
            out = messageStream.readLine();
        }
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

QHash<int, QByteArray> InvoiceTableModel::roleNames() const
{
    static const auto roles = QHash<int, QByteArray>{
        { Qt::DisplayRole, "display" }
    };
    return roles;
}

QString InvoiceTableModel::columnName(int index)
{
    QString name;
    switch (index) {
    case ColumnName::Unread:
        name = getColumnName(Unread);
        break;
    case ColumnName::Date:
        name = getColumnName(Date);
        break;
    case ColumnName::Type:
        name = getColumnName(Type);
        break;
    case ColumnName::Height:
        name = getColumnName(Height);
        break;
    case ColumnName::Message:
        name = getColumnName(Message);
        break;
    }
    return name;
}

void InvoiceTableModel::setupInvoiceDetails(int row)
{
    if ((0 > row) || (m_invoices.size() <= row)) {
        qCritical() << "Invalid row index" << row;
        return;
    }
    cn::WalletLegacyTransaction transaction;
    cn::TransactionId transactionId = m_invoices.value(row).first;
    WalletGui::Message message = m_invoices.value(row).second;

    int transactionIndex = indexAtUnseen(transactionId);
    if (transactionIndex >= 0) {
        removeFromUnseen(transactionId);
        saveChangesToCache();
        Q_EMIT layoutAboutToBeChanged();
        Q_EMIT layoutChanged();
    }

    if(!WalletAdapter::instance().getTransaction(transactionId, transaction)) {
      return;
    }

    const auto height = transaction.blockHeight;
    const QString invoiceHeight = (height == cn::WALLET_LEGACY_UNCONFIRMED_TRANSACTION_HEIGHT ? "-" : QString::number(height));
    setInvoiceHeight(invoiceHeight);

    const auto hash = QByteArray(reinterpret_cast<char*>(&transaction.hash),
                                 sizeof(transaction.hash));
    setInvoiceHash(hash.toHex().toUpper());

    const auto amount = static_cast<qint64>(transaction.totalAmount);
    setInvoiceAmount(CurrencyAdapter::instance().formatAmount(qAbs(amount)));

    setInvoiceSize(message.getMessage().size());

    setInvoiceFullText(message.getFullMessage());

    setInvoiceReplyTo(message.getHeaderValue(HEADER_REPLY_TO_KEY));

    QString INVOICE_AMOUNT = message.getHeaderValue(HEADER_INVOICE_AMOUNT);
    if ("" != INVOICE_AMOUNT) {
        setHasInvoiceId(true);
        setInvoiceId(message.getHeaderValue(HEADER_INVOICE_ID));
        setPaymentId(message.getHeaderValue(HEADER_PAYMENT_ID));
        setInvoiceAmountValue(INVOICE_AMOUNT);
    } else {
        setHasInvoiceId(false);
    }

    setInvoiceAttachment(message.getHeaderValue(HEADER_ATTACHMENT));

    m_encryptionKey = QByteArray::fromHex(message.getHeaderValue(HEADER_ATTACHMENT_ENCRYPTION_KEY).toUtf8());

    // Get sender address for payment
    if (transaction.totalAmount > 0) { // Incoming invoice
        // For incoming invoices, we need to find the transfer to get sender address
        for (cn::TransferId transferId = 0; transferId < transaction.transferCount; ++transferId) {
            cn::WalletLegacyTransfer transfer;
            if (WalletAdapter::instance().getTransfer(transaction.firstTransferId + transferId, transfer)) {
                if (transfer.amount > 0) {
                    setSenderAddress(QString::fromStdString(transfer.address));
                    break;
                }
            }
        }
    } else { // Outgoing invoice
        // For outgoing invoices, sender is our own address
        setSenderAddress(WalletAdapter::instance().getAddress());
    }
}

bool InvoiceTableModel::getReadState(int row) const
{
    cn::TransactionId transactionId = m_invoices.value(row).first;
    cn::WalletLegacyTransaction transaction;

    if (!WalletAdapter::instance().getTransaction(transactionId, transaction)) {
        return true;
    }

    int transactionIndex = indexAtUnseen(transactionId);
    if (transactionIndex >= 0 && transaction.totalAmount > 0) return false;
    else return true;
}

bool InvoiceTableModel::isIncomingInvoice(int row) const
{
    if ((0 > row) || (m_invoices.size() <= row)) {
        return false;
    }
    
    cn::WalletLegacyTransaction transaction;
    cn::TransactionId transactionId = m_invoices.value(row).first;
    if (!WalletAdapter::instance().getTransaction(transactionId, transaction)) {
        return false;
    }
    
    return transaction.totalAmount > 0;
}

QString InvoiceTableModel::getInvoiceSenderAddress(int row) const
{
    if ((0 > row) || (m_invoices.size() <= row)) {
        return "";
    }
    
    cn::WalletLegacyTransaction transaction;
    cn::TransactionId transactionId = m_invoices.value(row).first;
    if (!WalletAdapter::instance().getTransaction(transactionId, transaction)) {
        return "";
    }
    
    if (transaction.totalAmount > 0) { // Incoming invoice
        // Find the transfer to get sender address
        for (cn::TransferId transferId = 0; transferId < transaction.transferCount; ++transferId) {
            cn::WalletLegacyTransfer transfer;
            if (WalletAdapter::instance().getTransfer(transaction.firstTransferId + transferId, transfer)) {
                if (transfer.amount > 0) {
                    return QString::fromStdString(transfer.address);
                }
            }
        }
    }
    
    return "";
}

void InvoiceTableModel::showUploadProgress(QNetworkReply* reply)
{
    connect(reply, &QNetworkReply::downloadProgress, this,
            [&](qint64 bytesReceived, qint64 bytesTotal) {
        if (0 != bytesTotal) {
            emit downloadProgressChanged(static_cast<double>(bytesReceived) / bytesTotal);
        } else {
            emit abortDownload();
        }

    });
    connect(reply, &QNetworkReply::finished, this, &InvoiceTableModel::abortDownload);
    emit showDownloadProgress();
}

void InvoiceTableModel::attachmentDownloaded(QNetworkReply* reply)
{
    reply->deleteLater();
    m_downloadReply = nullptr;

    if(reply->error() == QNetworkReply::OperationCanceledError) {
      emit abortDownload();
      return;
    }

    if(reply->error()) {
      emit showErrorDialog(tr("Error"), tr("Can't download attachment: ") +
                           reply->errorString());
      return;
    }

    QByteArray payload = reply->readAll();
    WalletAdapter::instance().decryptAttachment(payload, m_encryptionKey);

    extractAttachment(payload);
}

void InvoiceTableModel::extractAttachment(const QByteArray &data)
{
    QTemporaryFile tempFile;
    if(!tempFile.open()) {
        emit showErrorDialog(tr("Error"), tr("Can't create temporary file for attachment"));
        return;
    }

    tempFile.write(data);
    tempFile.close();
    tempFile.open();

    QZipReader zipReader(&tempFile);
    if(zipReader.status() != QZipReader::NoError) {
        emit showErrorDialog(tr("Error"), tr("Can't open attachment zip archive"));
        return;
    }

    const QString dir = m_attachmentDirectory + "/" + m_invoiceHash;
    if(!QDir(dir).exists()) {
        if(!QDir().mkdir(dir)) {
            emit showErrorDialog(tr("Error"), tr("Can't create attachment directory"));
            return;
        }
    }

    if(!zipReader.extractAll(dir)) {
        emit showErrorDialog(tr("Error"), tr("Can't unpack attachment"));
    }
    zipReader.close();
}

void InvoiceTableModel::reloadWalletTransactions()
{
    emit layoutAboutToBeChanged();
    m_transactionRow.clear();
    m_invoices.clear();
    emit layoutChanged();

    quint32 rowCount = 0;
    invoicesListTransactionId.clear();
    for (cn::TransactionId transactionId = 0; transactionId < WalletAdapter::instance().getTransactionCount(); ++transactionId) {
      appendTransaction(transactionId, rowCount);
    }
    
    int invoicesCount = invoicesListTransactionId.size();
    int savedInvoiceLastCount = getInvoiceLastCount();
    if (savedInvoiceLastCount  != invoicesCount) {
        setInvoiceLastCount(invoicesCount);
        int invoiceDifference = invoicesCount - savedInvoiceLastCount;
        for (int i = 0; i < invoiceDifference; i++) {
            cn::TransactionId transactionId = invoicesListTransactionId.at(invoicesCount - i - 1);
            cn::WalletLegacyTransaction transaction;

            if (WalletAdapter::instance().getTransaction(transactionId, transaction)) {
                if (transaction.totalAmount > 0) {
                    appendToUnseen(transactionId);
                }
            }
        }
         saveChangesToCache();
    }
    sortInvoices();
    emit rowCountChanged();
}

void InvoiceTableModel::appendTransaction(cn::TransactionId _id,
                                           quint32& _row_count)
{
    cn::WalletLegacyTransaction transaction;
    if (!WalletAdapter::instance().getTransaction(_id, transaction)) {
      return;
    }

    m_transactionRow.insert(_id, qMakePair(std::numeric_limits<quint32>::max(), std::numeric_limits<quint32>::max()));
    if (transaction.messages.empty()) {
      return;
    }

    m_transactionRow[_id] = qMakePair(m_invoices.size(), transaction.messages.size());
    for (quint32 i = 0; i < transaction.messages.size(); ++i) {
      QString rawMessage = QString::fromStdString(transaction.messages[i]);
      WalletGui::Message message(rawMessage);
      
      // Check if this message has invoice headers
      QString invoiceId = message.getHeaderValue(HEADER_INVOICE_ID);
      QString invoiceAmount = message.getHeaderValue(HEADER_INVOICE_AMOUNT);
      
      qDebug() << "[invoicestablemodel] Checking invoice headers for transaction" << _id 
               << "invoiceId:" << invoiceId << "invoiceAmount:" << invoiceAmount
               << "transaction.totalAmount:" << transaction.totalAmount;
      
      // Only add to invoices if it has invoice headers
      if (!invoiceId.isEmpty() || !invoiceAmount.isEmpty()) {
        qDebug() << "[invoicestablemodel] Adding transaction" << _id << "to invoices list, amount:" 
                 << transaction.totalAmount << (transaction.totalAmount > 0 ? "(INCOMING)" : "(OUTGOING)")
                 << "message preview:" << message.getMessage().left(100);
        m_invoices.append(TransactionMessageId(_id, std::move(message)));
        invoicesListTransactionId.append(_id);
        ++_row_count;
      } else {
        qDebug() << "[invoicestablemodel] Transaction" << _id << "has no invoice headers, skipping";
      }
    }
}

void InvoiceTableModel::appendTransaction(cn::TransactionId _id)
{
    if (m_transactionRow.contains(_id)) {
        return;
    }

    quint32 insertedRowCount = 0;
    emit layoutAboutToBeChanged();
    for (cn::TransactionId transactionId =
         static_cast<cn::TransactionId>(m_transactionRow.size());
         transactionId <= _id; ++transactionId) {
        appendTransaction(transactionId, insertedRowCount);
        cn::WalletLegacyTransaction transaction;
        if (WalletAdapter::instance().getTransaction(transactionId, transaction)) {
            if (transaction.totalAmount > 0)
                appendToUnseen(transactionId);
        }
    }
    setInvoiceLastCount(invoicesListTransactionId.size());
    saveChangesToCache();

    sortInvoices();
    emit layoutChanged();
    emit rowCountChanged();
}

void InvoiceTableModel::updateWalletTransaction(cn::TransactionId _id)
{
    Q_UNUSED(_id)
    emit layoutAboutToBeChanged();
    emit layoutChanged();
}

void InvoiceTableModel::reset()
{
    emit layoutAboutToBeChanged();
    m_invoices.clear();
    m_transactionRow.clear();
    emit layoutChanged();
    emit rowCountChanged();
}

void InvoiceTableModel::lastKnownHeightUpdated(quint64 _height)
{
    Q_UNUSED(_height)
    emit layoutAboutToBeChanged();
    emit layoutChanged();
}

void InvoiceTableModel::sortInvoices()
{
    std::sort(m_invoices.begin(), m_invoices.end(),
              [&](TransactionMessageId &left, TransactionMessageId &right) {
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

int InvoiceTableModel::getInvoiceLastCount() const
{
    return invoiceLastCount;
}

void InvoiceTableModel::setInvoiceLastCount(int newCount)
{
    invoiceLastCount = newCount;
}

void InvoiceTableModel::saveChangesToCache()
{
    QFile UnreadFile(Settings::instance().getUnreadMessagesFile());
    if (!UnreadFile.open(QIODevice::WriteOnly | QIODevice::Text | QFile::Truncate))
        return;
    QTextStream out(&UnreadFile);
    out << "InvoiceNo:" << invoiceLastCount << "\n" << "UnseenInvoices:";
    for (int i = 0; i < unseenList.size(); i++) {
        out << QString::number(unseenList.at(i)) << ",";

    }
    UnreadFile.flush();
    UnreadFile.close();
}

void InvoiceTableModel::appendToUnseen(cn::TransactionId transactionId)
{
    unseenList.append(transactionId);
}

void InvoiceTableModel::removeFromUnseen(cn::TransactionId transactionId)
{
    unseenList.remove(indexAtUnseen(transactionId));
}

int InvoiceTableModel::indexAtUnseen(cn::TransactionId transactionId) const
{
    return unseenList.indexOf(transactionId);
}

void InvoiceTableModel::initUnseenCacheFile()
{
    QFile UnreadFile(Settings::instance().getUnreadMessagesFile());
    if (!UnreadFile.open(QIODevice::ReadWrite | QIODevice::Text))
        return;
    invoiceLastCount = 0;
    while (!UnreadFile.atEnd()) {
        QByteArray line = UnreadFile.readLine();
        if (line.contains("InvoiceNo:")) {
            line.remove(0, 10);
            invoiceLastCount = QString(line).toInt();

        }
        if (line.contains("UnseenInvoices:")) {
            line.remove(0, 15);
            QStringList list = QString(line).split(',', QString::SkipEmptyParts);
            foreach(QString num, list)
                unseenList.append(num.toInt());

        }

    }
    UnreadFile.flush();
    UnreadFile.close();
}

QString InvoiceTableModel::getColumnName(ColumnName columnName)
{
    QString headerName;

    if (!m_columnNameList.isEmpty())
    {
        headerName = m_columnNameList.at(columnName);
    }
    else
    {
        switch (columnName)
        {
        case Unread:
            headerName = "";
            break;
        case Date:
            headerName = "Date";
            break;
        case Type:
            headerName = "Type";
            break;
        case Height:
            headerName = "Height";
            break;
        case Message:
            headerName = "Message";
            break;
        default:
            break;
        }
    }

    return headerName;
}

} // namespace WalletGui
