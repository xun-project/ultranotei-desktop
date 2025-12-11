#pragma once

#include "qmlhelpers.h"
#include "Message.h"
#include "IWalletLegacy.h"
#include "Settings.h"

#include <QAbstractTableModel>
#include <QNetworkAccessManager>
#include <QFile>

class QNetworkReply;

namespace WalletGui {

typedef QPair<cn::TransactionId, Message> TransactionMessageId;

class InvoiceTableModel : public QAbstractTableModel
{
    Q_OBJECT
    QML_WRITABLE_PROPERTY(QStringList, columnNameList, setColumnNameList, QStringList())

public:
    enum ColumnName {
        Unread,
        Date,
        Type,
        Height,
        Message,
        Count
    };
    Q_ENUM(ColumnName)
    explicit InvoiceTableModel(QObject *parent = nullptr);
    int rowCount(const QModelIndex &index = QModelIndex()) const override;
    int columnCount(const QModelIndex &index = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;
    Q_INVOKABLE QString columnName(int index);
    Q_INVOKABLE void setupInvoiceDetails(int row);
    Q_INVOKABLE bool getReadState(int row) const;
    Q_INVOKABLE bool isIncomingInvoice(int row) const;
    Q_INVOKABLE QString getInvoiceSenderAddress(int row) const;

    int getRowCount() const { return m_invoices.size(); }

    void reloadWalletTransactions();
    void appendTransaction(cn::TransactionId _id, quint32& _row_count);
    void appendTransaction(cn::TransactionId _id);
    void updateWalletTransaction(cn::TransactionId _id);
    void reset();
    void lastKnownHeightUpdated(quint64 _height);

    int getInvoiceLastCount() const;
    int indexAtUnseen(cn::TransactionId transactionId) const;
    void saveChangesToCache();
    void setInvoiceLastCount(int newCount);
    void appendToUnseen(cn::TransactionId transactionId);
    void removeFromUnseen(cn::TransactionId transactionId);
signals:
    void rowCountChanged();
    void showErrorDialog(const QString &title, const QString &msg);
    void downloadProgressChanged(qreal value);
    void abortDownload();
    void showDownloadProgress();
private:
    void sortInvoices();
    void showUploadProgress(QNetworkReply *reply);
    void attachmentDownloaded(QNetworkReply *reply);
    void extractAttachment(const QByteArray &data);

    int invoiceLastCount;
    void initUnseenCacheFile();
    QString getColumnName(ColumnName columnName);
    QString applicationCurrentPath;
    QVector<cn::TransactionId> unseenList;

    QVector<TransactionMessageId> m_invoices;
    QHash<cn::TransactionId, QPair<quint32, quint32> > m_transactionRow;
    QString m_fileNameToSave;
    QNetworkAccessManager m_networAccesskManager;
    QByteArray m_encryptionKey;
    QString m_attachmentDirectory;
    QNetworkReply* m_downloadReply = nullptr;
    QVector<size_t> invoicesListTransactionId;

private:
    QML_CONSTANT_PROPERTY(int, columnCount, ColumnName::Count)
    Q_PROPERTY(int rowCount READ getRowCount NOTIFY rowCountChanged)

    QML_READABLE_PROPERTY(QString, invoiceHeight, setInvoiceHeight, "")
    QML_READABLE_PROPERTY(QString, invoiceHash, setInvoiceHash, "")
    QML_READABLE_PROPERTY(QString, invoiceAmount, setInvoiceAmount, "")
    QML_READABLE_PROPERTY(int, invoiceSize, setInvoiceSize, 0)
    QML_READABLE_PROPERTY(QString, invoiceFullText, setInvoiceFullText, "")
    QML_READABLE_PROPERTY(QString, invoiceReplyTo, setInvoiceReplyTo, "")
    QML_READABLE_PROPERTY(QString, invoiceAttachment, setInvoiceAttachment, "")
    QML_READABLE_PROPERTY(QString, invoiceId, setInvoiceId, "")
    QML_READABLE_PROPERTY(QString, paymentId, setPaymentId, "")
    QML_READABLE_PROPERTY(QString, invoiceAmountValue, setInvoiceAmountValue, "")
    QML_READABLE_PROPERTY(bool, hasInvoiceId, setHasInvoiceId, false)
    QML_READABLE_PROPERTY(QString, senderAddress, setSenderAddress, "")
};

} //WalletGui
