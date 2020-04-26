#ifndef DEPOSITTABLEMODEL_H
#define DEPOSITTABLEMODEL_H

#include "qmlhelpers.h"
#include "TransactionsModel.h"
#include <QAbstractTableModel>

namespace WalletGui {

class DepositTableModel : public QAbstractTableModel
{
    Q_OBJECT
    QML_READABLE_PROPERTY(int, depositCount, setDepositCount, 0)
    Q_PROPERTY(int unlockedDepositCount READ unlockedDepositCount NOTIFY unlockedDepositCountChanged)
	QML_READABLE_PROPERTY(QString, depositDetails, setDepositDetails, "")

public:
    enum ColumnName { Status = 0,
                      Amount,
                      Interest,
                      Sum,
                      Rate,
                      UnlockHeight,
                      UnlockTime,
                      SpendingTime,
                      Count
                    };
    Q_ENUM(ColumnName)
    explicit DepositTableModel(QObject *parent = nullptr);
    int rowCount(const QModelIndex &index = QModelIndex()) const override;
    int columnCount(const QModelIndex &index = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;
    Q_INVOKABLE QString columnName(int index) const;
    Q_INVOKABLE void sortAfterColumn(int col, bool ascending);
	Q_INVOKABLE void setupDepositDetails(int row);

    void reloadWalletDeposits();
    void transactionCreated(CryptoNote::TransactionId transactionId);
    void transactionUpdated(CryptoNote::TransactionId _transactionId);
    void reset();
    void depositsUpdated(const QVector<CryptoNote::DepositId>& _depositIds);
    const QVector<CryptoNote::DepositId>& unlockedDepositIds() const {return m_unlockedDepositIds;}
    int unlockedDepositCount() const { return m_unlockedDepositIds.size();}
signals:
    void unlockedDepositCountChanged();
private:
    enum Roles {
        ROLE_DEPOSIT_TERM = Qt::UserRole, ROLE_DEPOSIT_AMOUNT, ROLE_DEPOSIT_INTEREST, ROLE_STATE,
        ROLE_CREATING_TRANSACTION_ID, ROLE_SPENDING_TRANSACTION_ID, ROLE_UNLOCK_HEIGHT, ROLE_ROW, ROLE_COLUMN
    };
    enum DepositState {
        STATE_LOCKED, STATE_UNLOCKED, STATE_SPENT
    };
    static qreal calculateRate(quint64 _amount, //amount invested (in coin minimum increments)
                               quint64 _interest); //interest earned (in coin minimum increments)
    void appendDeposit(CryptoNote::DepositId _depositId);
    QVariant getUserRole(int row, int role) const;
    QVector<CryptoNote::DepositId> m_unlockedDepositIds;
    QVector<int> m_orderedRows;
};

} // WalletGui

#endif // DEPOSITTABLEMODEL_H
