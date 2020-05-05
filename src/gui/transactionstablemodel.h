#pragma once

#include "qmlhelpers.h"
#include "IWalletLegacy.h"
#include <QAbstractTableModel>

namespace WalletGui {

enum class TransactionType : quint8 {MINED, INPUT, OUTPUT, INOUT, DEPOSIT};
typedef QPair<CryptoNote::TransactionId, CryptoNote::TransferId> TransactionTransferId;

class TransactionsTableModel : public QAbstractTableModel
{
    Q_OBJECT
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
    Q_INVOKABLE QString columnName(int index) const;
    Q_INVOKABLE QString transactionIcon(int row) const;
    Q_INVOKABLE void setupTransactionDetails(int row);
    Q_INVOKABLE void exportToCsv(const QUrl &fileUrl);

    void reloadWalletTransactions();
    void appendTransaction(CryptoNote::TransactionId _id);
    void updateWalletTransaction(CryptoNote::TransactionId _id);
    void lastKnownHeightUpdated(quint64 _height);
    void reset();
private:
    QVector<TransactionTransferId> m_transfers;
    QHash<CryptoNote::TransactionId, QPair<quint32, quint32> > m_transactionRow;
    void appendTransaction(CryptoNote::TransactionId _id, quint32& _row_count);

    static QVariant stateIcon(quint64 numberOfConfirmations);
    static qint64 getAmount(CryptoNote::WalletLegacyTransaction transaction,
                         const CryptoNote::WalletLegacyTransfer &transfer,
                         const CryptoNote::TransferId transferId,
                         const CryptoNote::Deposit &deposit);
    static quint8 roleType(CryptoNote::WalletLegacyTransaction transaction,
                    const CryptoNote::WalletLegacyTransfer &transfer);
    void sortTransfers();
    QByteArray toCsv() const;
    const QString m_transactionDetailsTemplate;

private:
    QML_CONSTANT_PROPERTY(int, columnCount, ColumnName::Count)
    QML_READABLE_PROPERTY(int, rowCount, setRowCount, 0)
    QML_READABLE_PROPERTY(QString, transactionDetails, setTransactionDetails, "")
};

} // WalletGui
