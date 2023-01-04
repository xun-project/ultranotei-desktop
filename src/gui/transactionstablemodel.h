#pragma once

#include "qmlhelpers.h"
#include "IWalletLegacy.h"
#include <QAbstractTableModel>

namespace WalletGui {

enum class TransactionType : quint8 {MINED, INPUT, OUTPUT, INOUT, DEPOSIT};
typedef QPair<cn::TransactionId, cn::TransferId> TransactionTransferId;

class TransactionsTableModel : public QAbstractTableModel
{
    Q_OBJECT
    QML_WRITABLE_PROPERTY(QStringList, columnNameList, setColumnNameList, QStringList())

public:
    enum ColumnName {
        State,
        Date,
        Amount,
        Address,
        Message,
        PaymentId,
        Count
    };
    Q_ENUM(ColumnName)
    explicit TransactionsTableModel(QObject *parent = nullptr);
    int rowCount(const QModelIndex &index = QModelIndex()) const override;
    int columnCount(const QModelIndex &index = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;
    Q_INVOKABLE QString columnName(int index);
    Q_INVOKABLE QString transactionIcon(int row) const;
    Q_INVOKABLE void setupTransactionDetails(int row);
    Q_INVOKABLE void exportToCsv(const QUrl &fileUrl);

    void reloadWalletTransactions();
    void appendTransaction(cn::TransactionId _id);
    void updateWalletTransaction(cn::TransactionId _id);
    void lastKnownHeightUpdated(quint64 _height);
    void reset();
Q_SIGNALS:
    void alertWithNewTransaction();

private:
    QVector<TransactionTransferId> m_transfers;
    QHash<cn::TransactionId, QPair<quint32, quint32> > m_transactionRow;
    void appendTransaction(cn::TransactionId _id, quint32& _row_count);

    static QVariant stateIcon(quint64 numberOfConfirmations);
    static qint64 getAmount(cn::WalletLegacyTransaction transaction,
                         const cn::WalletLegacyTransfer &transfer,
                         const cn::TransferId transferId,
                         const cn::Deposit &deposit);
    static quint8 roleType(cn::WalletLegacyTransaction transaction,
                    const cn::WalletLegacyTransfer &transfer);
    void sortTransfers();
    QByteArray toCsv() const;
    QString getColumnName(ColumnName columnName);
    const QString m_transactionDetailsTemplate;

private:
    QML_CONSTANT_PROPERTY(int, columnCount, ColumnName::Count)
    QML_READABLE_PROPERTY(int, rowCount, setRowCount, 0)
    QML_READABLE_PROPERTY(QString, transactionDetails, setTransactionDetails, "")
};

} // WalletGui
