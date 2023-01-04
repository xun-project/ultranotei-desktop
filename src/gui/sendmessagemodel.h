#pragma once

#include "qmlhelpers.h"
#include "attachmentsmodel.h"
#include "recipientsmodel.h"
#include "IWalletLegacy.h"
#include <QNetworkAccessManager>

namespace WalletGui {

class SendMessageModel : public QObject
{
    Q_OBJECT
    QML_WRITABLE_PROPERTY(QString, message, setMessage, "")
    QML_WRITABLE_PROPERTY(bool, isSelfDestruct, setIsSelfDestruct, false)
    QML_WRITABLE_PROPERTY(int, selfDestructTimeMin, setSelfDestructTimeMin, 0)
    QML_WRITABLE_PROPERTY(int, selfDestructTimeMinFrom, setSelfDestructTimeMinFrom, 0)
    QML_WRITABLE_PROPERTY(int, selfDestructTimeMinTo, setSelfDestructTimeMinTo, 1)
    QML_WRITABLE_PROPERTY(bool, addReplyTo, setAddReplyTo, false)
    QML_READABLE_PROPERTY(int, minMessageFee, setMinMessageFee, 0)
    QML_WRITABLE_PROPERTY(int, messageFee, setMessageFee, 0)
    QML_WRITABLE_PROPERTY(int, anonimityLevel, setAnonimityLevel, 0)
    QML_CONSTANT_PROPERTY_PTR(AttachmentsModel, attachmentsModel)
    QML_CONSTANT_PROPERTY_PTR(RecipientsModel, recipientsModel)
public:
    explicit SendMessageModel(QObject *parent = nullptr);
    Q_INVOKABLE void recalculateFeeValue();
    Q_INVOKABLE void send();
    void sendMessageCompleted(cn::TransactionId _transactionId, bool _error,
                              const QString& _errorText);
signals:
    void downloadProgressChanged(double value);
    void abortDownload();
    void showDownloadProgress();
private:
    void sendMessage(const QString& ipfsHash, const QString& encrpyptionKey);
    static QString extractAddress(const QString& _addressString);
    quint64 totalAttachmentsSize() const;
    void packAttachments(QTemporaryFile* archive);
    void uploadAttachments(QTemporaryFile* archive);
    void attachmentUploaded(QNetworkReply* reply, const QString& encryptionKey);
    void showUploadProgress(QNetworkReply* reply);
    void reset();
    QNetworkAccessManager m_networkAccessManager;
};

} // WalletGui
