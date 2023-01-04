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

class MessagesTableModel : public QAbstractTableModel
{
    Q_OBJECT
    QML_WRITABLE_PROPERTY(QStringList, columnNameList, setColumnNameList, QStringList())

public:
    enum ColumnName {
        Date,
        Type,
        Height,
        Message,
        Count
    };
    Q_ENUM(ColumnName)
    explicit MessagesTableModel(QObject *parent = nullptr);
    int rowCount(const QModelIndex &index = QModelIndex()) const override;
    int columnCount(const QModelIndex &index = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;
    Q_INVOKABLE QString columnName(int index);
    Q_INVOKABLE void setupMessageDetails(int row);
    Q_INVOKABLE void save(const QUrl &fileName);
    Q_INVOKABLE void download(const QUrl &folderName);
    Q_INVOKABLE void cancelDownload();
	Q_INVOKABLE bool getReadState(int row)const;


    int getRowCount() const { return m_messages.size(); }

    void reloadWalletTransactions();
    void appendTransaction(cn::TransactionId _id, quint32& _row_count);
    void appendTransaction(cn::TransactionId _id);
    void updateWalletTransaction(cn::TransactionId _id);
    void reset();
    void lastKnownHeightUpdated(quint64 _height);

	int  getMsgLastCount() const;
	int  indexAtUnseen(cn::TransactionId transactionId) const;
	void saveChangesToCache();
	void setMsgLastCount(int newCount);
	void appendToUnseen(cn::TransactionId transactionId);
	void removeFromUnseen(cn::TransactionId transactionId);
signals:
    void rowCountChanged();
    void showErrorDialog(const QString &title, const QString &msg);
    void downloadProgressChanged(qreal value);
    void abortDownload();
    void showDownloadProgress();
private:
    void sortMessages();
    void showUploadProgress(QNetworkReply *reply);
    void attachmentDownloaded(QNetworkReply *reply);
    void extractAttachment(const QByteArray &data);

	int msgLastCount;
	void initUnseenCacheFile();
    QString getColumnName(ColumnName columnName);
	QString applicationCurrentPath;
	QVector<cn::TransactionId> unseenList;

    QVector<TransactionMessageId> m_messages;
    QHash<cn::TransactionId, QPair<quint32, quint32> > m_transactionRow;
    QString m_fileNameToSave;
    QNetworkAccessManager m_networAccesskManager;
    QByteArray m_encryptionKey;
    QString m_attachmentDirectory;
    QNetworkReply* m_downloadReply = nullptr;
	QVector<size_t> messagesListTransactionId;

private:
    QML_CONSTANT_PROPERTY(int, columnCount, ColumnName::Count)
    Q_PROPERTY(int rowCount READ getRowCount NOTIFY rowCountChanged)

    QML_READABLE_PROPERTY(QString, msgHeight, setMsgHeight, "")
    QML_READABLE_PROPERTY(QString, msgHash, setMsgHash, "")
    QML_READABLE_PROPERTY(QString, msgAmount, setMsgAmount, "")
    QML_READABLE_PROPERTY(int, msgSize, setMsgSize, 0)
    QML_READABLE_PROPERTY(QString, msgFullText, setMsgFullText, "")
    QML_READABLE_PROPERTY(QString, msgReplyTo, setMsgReplyTo, "")
    QML_READABLE_PROPERTY(QString, msgAttachment, setMsgAttachment, "")
	QML_READABLE_PROPERTY(QString, msgInvoiceId, setmsgInvoiceId, "")
    QML_READABLE_PROPERTY(QString, msgPaymentId, setmsgPaymentId, "")
    QML_READABLE_PROPERTY(QString, msgInvoiceAmount, setmsgInvoiceAmount, "")
	QML_READABLE_PROPERTY(bool, hasInvoiceId, setMsgInvoice, false)
};

} //WalletGui
