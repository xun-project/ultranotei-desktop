#include "deposittablemodel.h"
#include "CurrencyAdapter.h"
#include "WalletAdapter.h"
#include "NodeAdapter.h"
#include <QQmlEngine>
#include <QDateTime>
#include "DepositModel.h"

namespace {

QDateTime getExpectedTimeForHeight(quint64 _height) {
    quint64 lastLocalBlockHeight = WalletGui::NodeAdapter::instance().getLastLocalBlockHeight();
    QDateTime localLocalBlockTimestamp = WalletGui::NodeAdapter::instance().getLastLocalBlockTimestamp();

    return localLocalBlockTimestamp.addSecs((_height - lastLocalBlockHeight) * WalletGui::CurrencyAdapter::instance().getDifficultyTarget());
}

}

namespace WalletGui {

DepositTableModel::DepositTableModel(QObject *parent) : QAbstractTableModel(parent)
{
    qInfo() << "DepositTableModel::DepositTableModel";

    qmlRegisterType<DepositTableModel>("DepositTableModel", 1, 0, "DepositTableModel");
    connect(this, &DepositTableModel::depositCountChanged, [&]() {
        m_unlockedDepositIds.clear();
        for (int i = 0; i < m_depositCount; ++i) {
            const DepositState depositState = static_cast<DepositState>(getUserRole(i,
                                              ROLE_STATE).toInt());
            if (STATE_UNLOCKED == depositState) {
                m_unlockedDepositIds.push_back(static_cast<cn::DepositId>(i));
            }
        }
		emit unlockedDepositCountChanged();
    });
}

int DepositTableModel::rowCount(const QModelIndex &index) const
{
    Q_UNUSED(index)
    return m_depositCount;
}

int DepositTableModel::columnCount(const QModelIndex &index) const
{
    Q_UNUSED(index)
    return ColumnName::Count;
}

QVariant DepositTableModel::data(const QModelIndex &index, int role) const
{
    const int col = index.column();
    int row = index.row();
    if (row < m_orderedRows.size()) {
        row = m_orderedRows.at(row);
    }
    QVariant out;

    switch (role) {
    case Qt::DisplayRole:
        switch (col) {
        case Status: {
            DepositState depositState = static_cast<DepositState>(getUserRole(row, ROLE_STATE).toInt());
            switch (depositState) {
            case STATE_LOCKED:
                out = tr("Locked");
                break;
            case STATE_UNLOCKED:
                out = tr("Unlocked");
                break;
            case STATE_SPENT:
                out = tr("Spent");
                break;
            }
        }
            break;
        case Amount:
            out = WalletGui::CurrencyAdapter::instance().formatAmount(getUserRole(row, ROLE_DEPOSIT_AMOUNT).value<quint64>());
            break;
        case Interest:
            out = WalletGui::CurrencyAdapter::instance().formatAmount(getUserRole(row, ROLE_DEPOSIT_INTEREST).value<quint64>());
            break;
        case Sum:
            out = WalletGui::CurrencyAdapter::instance().formatAmount(getUserRole(row,
                                                                                  ROLE_DEPOSIT_AMOUNT).value<quint64>() +
                                                                      getUserRole(row, ROLE_DEPOSIT_INTEREST).value<quint64>());
            break;
        case Rate: {
            quint64 amount = getUserRole(row, ROLE_DEPOSIT_AMOUNT).value<quint64>();
            quint64 interest = getUserRole(row, ROLE_DEPOSIT_INTEREST).value<quint64>();
            qreal termRate = calculateRate(amount, interest);
            out = QString("%1 %").arg(QString::number(termRate * 100, 'f', 2));
        }
            break;
        case UnlockHeight: {
            quint64 unlockHeight = getUserRole(row, ROLE_UNLOCK_HEIGHT).value<quint64>();
            if (unlockHeight == cn::WALLET_LEGACY_UNCONFIRMED_TRANSACTION_HEIGHT) {
                out = "-";
            } else {
                out = unlockHeight > 0 ? unlockHeight - 1 : 0;
            }
        }
            break;
        case UnlockTime: {
            DepositState depositState = static_cast<DepositState>(getUserRole(row, ROLE_STATE).toInt());
            if (depositState == STATE_LOCKED) {
                quint64 unlockHeight = getUserRole(row, ROLE_UNLOCK_HEIGHT).value<quint64>();
                if (unlockHeight == cn::WALLET_LEGACY_UNCONFIRMED_TRANSACTION_HEIGHT) {
                    out = "-";
                } else {
                    out = getExpectedTimeForHeight(unlockHeight).toString("yyyy-MM-dd HH:mm");
                }
            } else {
                out = QDateTime();
            }
        }
            break;
        case SpendingTime: {
            cn::TransactionId spendingTransactionId = getUserRole(row, ROLE_SPENDING_TRANSACTION_ID).value<cn::TransactionId>();
            if (spendingTransactionId == cn::WALLET_LEGACY_INVALID_TRANSACTION_ID) {
                out = "-";
            } else {
                out = WalletGui::TransactionsModel::instance().index(static_cast<int>(spendingTransactionId), WalletGui::TransactionsModel::COLUMN_DATE).data();
            }
        }
            break;
        }
        break;
    default:
        ;
    }

    return out;
}

QVariant DepositTableModel::getUserRole(int row, int role) const
{
    cn::Deposit deposit;

    if(!WalletGui::WalletAdapter::instance().getDeposit(row, deposit)) {
        return QVariant();
    }

    switch(role) {
    case ROLE_DEPOSIT_TERM:
        return deposit.term;

    case ROLE_DEPOSIT_AMOUNT:
        return static_cast<quint64>(deposit.amount);

    case ROLE_DEPOSIT_INTEREST:
        return static_cast<quint64>(deposit.interest);

    case ROLE_STATE:
        if (deposit.locked) {
            return static_cast<int>(STATE_LOCKED);
        } else if (deposit.spendingTransactionId == cn::WALLET_LEGACY_INVALID_TRANSACTION_ID) {
            return static_cast<int>(STATE_UNLOCKED);
        }
        return static_cast<int>(STATE_SPENT);

    case ROLE_CREATING_TRANSACTION_ID:
        return static_cast<quintptr>(deposit.creatingTransactionId);

    case ROLE_SPENDING_TRANSACTION_ID:
        return static_cast<quintptr>(deposit.spendingTransactionId);

    case ROLE_UNLOCK_HEIGHT: {
        cn::TransactionId creatingTransactionId = getUserRole(row, ROLE_CREATING_TRANSACTION_ID).value<cn::TransactionId>();
        quint64 creatingHeight = WalletGui::TransactionsModel::instance().index(static_cast<int>(creatingTransactionId), 0).
                data(WalletGui::TransactionsModel::ROLE_HEIGHT).value<quint64>();
        if (creatingHeight == cn::WALLET_LEGACY_UNCONFIRMED_TRANSACTION_HEIGHT) {
            return static_cast<const quint64>(cn::WALLET_LEGACY_UNCONFIRMED_TRANSACTION_HEIGHT);
        }

        return creatingHeight + getUserRole(row, ROLE_DEPOSIT_TERM).value<quint32>();
    }

    case ROLE_ROW:
        return row;
    }

    return QVariant();
}

QString DepositTableModel::getColumnName(ColumnName columnName)
{
    //get translations once from QML to C++, in case of DepositeTable it can not be done in qml
    if (!translationsInit)
    {
        QQmlEngine engine;

        QQmlComponent component(&engine, "qrc:/qml/qml/UltraNote/UI/LegacyTranslations.qml");
        QObject* object = component.create();

        m_columnNameList = QQmlProperty::read(object, "depositTableHeaders").toStringList();

        delete object;

        translationsInit = true;
    }

    QString headerName;

    if (!m_columnNameList.isEmpty())
    {
        headerName = m_columnNameList.at(columnName);
    }
    else
    {
        switch (columnName)
        {
        case Status:
            headerName = "Status";
            break;
        case Amount:
            headerName = "Amount";
            break;
        case Interest:
            headerName = "Interest";
            break;
        case Sum:
            headerName = "Sum";
            break;
        case Rate:
            headerName = "Rate";
            break;
        case UnlockHeight:
            headerName = "UnlockHeight";
            break;
        case UnlockTime:
            headerName = "UnlockTime";
            break;
        case SpendingTime:
            headerName = "SpendingTime";
            break;
        default:
            break;
        }
    }

    return headerName;
}

void DepositTableModel::reinitHeaderNames()
{
    translationsInit = false;
}

QHash<int, QByteArray> DepositTableModel::roleNames() const
{
    static const auto roles = QHash<int, QByteArray>{
        { Qt::DisplayRole, "display" }
    };
    return roles;
}

QString DepositTableModel::columnName(int index)
{
    QString name;
    switch (index) {
    case ColumnName::Status:
        name = getColumnName(Status);
        break;
    case ColumnName::Amount:
        name = getColumnName(Amount);
        break;
    case ColumnName::Interest:
        name = getColumnName(Interest);
        break;
    case ColumnName::Sum:
        name = getColumnName(Sum);
        break;
    case ColumnName::Rate:
        name = getColumnName(Rate);
        break;
    case ColumnName::UnlockHeight:
        name = getColumnName(UnlockHeight);
        break;
    case ColumnName::UnlockTime:
        name = getColumnName(UnlockTime);
        break;
    case ColumnName::SpendingTime:
        name = getColumnName(SpendingTime);
        break;
    }
    return name;
}

qreal DepositTableModel::calculateRate(quint64 _amount, quint64 _interest)
{
    return (static_cast<qreal>(_interest)) / _amount;
}

void DepositTableModel::reloadWalletDeposits()
{
    reset();

    if (WalletGui::WalletAdapter::instance().getDepositCount() == 0) {
        return;
    }
    emit layoutAboutToBeChanged();
    setDepositCount(static_cast<int>(WalletGui::WalletAdapter::instance().getDepositCount()));
    emit layoutChanged();
}

void DepositTableModel::reset()
{
    emit layoutAboutToBeChanged();
    setDepositCount(0);
    emit layoutChanged();
}

void DepositTableModel::transactionCreated(cn::TransactionId transactionId)
{
    if (m_depositCount < WalletGui::WalletAdapter::instance().getDepositCount()) {
        appendDeposit(WalletGui::WalletAdapter::instance().getDepositCount() - 1);
    }
}

void DepositTableModel::appendDeposit(cn::DepositId _depositId)
{
    if (_depositId < m_depositCount) {
        return;
    }

    emit layoutAboutToBeChanged();
    setDepositCount(static_cast<const int>(_depositId + 1));
    emit layoutChanged();
}

void DepositTableModel::transactionUpdated(cn::TransactionId _transactionId)
{
    QModelIndex transactionIndex = WalletGui::TransactionsModel::instance().index(static_cast<int>(_transactionId), 0);
    if (!transactionIndex.isValid()) {
        return;
    }

    quintptr firstDepositId = transactionIndex.data(WalletGui::TransactionsModel::ROLE_DEPOSIT_ID).value<quintptr>();
    quintptr depositCount = transactionIndex.data(WalletGui::TransactionsModel::ROLE_DEPOSIT_COUNT).value<quintptr>();
    emit dataChanged(index(firstDepositId, 0), index(firstDepositId + depositCount - 1, columnCount() - 1));
}

void DepositTableModel::depositsUpdated(const QVector<cn::DepositId>& _depositIds)
{
    for (const auto& depositId: _depositIds) {
        emit dataChanged(index(static_cast<int>(depositId), 0), index(static_cast<int>(depositId), columnCount() - 1));
    }
}

void DepositTableModel::sortAfterColumn(int col, bool ascending)
{
    emit layoutAboutToBeChanged();
    QVector<QVariant> vals;
    m_orderedRows.clear();//data is taken with no order
    for (int row = 0; row < m_depositCount; ++row) {
        vals.append(data(createIndex(row, col), Qt::DisplayRole));
    }
    m_orderedRows.resize(vals.size());
    std::iota(m_orderedRows.begin(), m_orderedRows.end(), 0);
    std::sort(m_orderedRows.begin(), m_orderedRows.end(),
              [&vals, &ascending](int left, int right) {
        return ascending ? (vals.at(left) > vals.at(right)) : (vals.at(left) < vals.at(right));
    });
    emit layoutChanged();
}

void DepositTableModel::setupDepositDetails(int row)
{
	QModelIndex depositIndex = index(row,0);
	if (!depositIndex.isValid()) {
		return;
	}

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

	QString depositAmount = depositIndex.sibling(depositIndex.row(), DepositModel::COLUMN_AMOUNT).data().toString() + " " +
		CurrencyAdapter::instance().getCurrencyTicker().toUpper();

	QString depositInterest = depositIndex.sibling(depositIndex.row(), DepositModel::COLUMN_INTEREST).data().toString() + " " +
		CurrencyAdapter::instance().getCurrencyTicker().toUpper();
	QString depositSum = depositIndex.sibling(depositIndex.row(), DepositModel::COLUMN_SUM).data().toString() + " " +
		CurrencyAdapter::instance().getCurrencyTicker().toUpper();
	QString depositInfo = depositInfoTemplate.
		arg(depositIndex.sibling(depositIndex.row(), DepositModel::COLUMN_STATE).data().toString()).
		arg(depositAmount).
		arg(depositInterest).
		arg(depositSum).
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

	setDepositDetails(depositInfo);
}


} // WalletGui
