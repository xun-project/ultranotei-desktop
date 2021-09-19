#include "sendmessagemodel.h"
#include "CurrencyAdapter.h"
#include "WalletAdapter.h"
#include "MessagesModel.h"
#include "../qzipwriter_p.h"
#include <QQmlEngine>
#include <QDebug>
#include <QTemporaryFile>
#include <QFileInfo>
#include <QHttpPart>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QJsonDocument>

namespace WalletGui {

Q_DECL_CONSTEXPR quint64 MESSAGE_AMOUNT = 1000;
Q_DECL_CONSTEXPR quint64 MESSAGE_CHAR_PRICE = 100;
Q_DECL_CONSTEXPR quint64 ATTACHMENT_HEADER_LENGTH = 59;
Q_DECL_CONSTEXPR quint64 ATTACHMENT_ENCRYPTION_KEY_HEADER_LENGTH = 92;
Q_DECL_CONSTEXPR quint64 MAX_ATTACHMENT_SIZE = 100 * 1024 * 1024;
Q_DECL_CONSTEXPR quint64 MINIMAL_MESSAGE_FEE = MESSAGE_CHAR_PRICE;
Q_DECL_CONSTEXPR int DEFAULT_MESSAGE_MIXIN = 2;

Q_DECL_CONSTEXPR quint32 MINUTE_SECONDS = 60;
Q_DECL_CONSTEXPR quint32 HOUR_SECONDS = 60 * MINUTE_SECONDS;
Q_DECL_CONSTEXPR int MIN_TTL = 5 * MINUTE_SECONDS;
Q_DECL_CONSTEXPR int MAX_TTL = 14 * HOUR_SECONDS;
Q_DECL_CONSTEXPR int TTL_STEP = 5 * MINUTE_SECONDS;

static const QString IPFS_API_URL = "http://backup.ultranote.org:5001/";
static const QString IPFS_RESPONSE_HASH_FIELD = "Hash";

SendMessageModel::SendMessageModel(QObject *parent) : QObject(parent)
{
    qmlRegisterInterface<SendMessageModel>("SendMessageModel");
    setAnonimityLevel(DEFAULT_MESSAGE_MIXIN);
    setSelfDestructTimeMin(1);
    setSelfDestructTimeMinFrom(1);
    setSelfDestructTimeMinTo(MAX_TTL / MIN_TTL);
    reset();
}

void SendMessageModel::recalculateFeeValue()
{
    int messageSize = m_message.length() ;
    if (messageSize > 0) {
        --messageSize;
    }

    quint64 fee = 0;
    // fee for permanent message
    if(!m_isSelfDestruct) {
        fee += MINIMAL_MESSAGE_FEE;
    }
    // fee for attachment
    if(m_attachmentsModel->rowCount() > 0) {
        quint64 atachmentFee = 0;
        atachmentFee += MESSAGE_CHAR_PRICE * ATTACHMENT_HEADER_LENGTH;
        atachmentFee += MESSAGE_CHAR_PRICE * ATTACHMENT_ENCRYPTION_KEY_HEADER_LENGTH;
        atachmentFee *= m_attachmentsModel->rowCount();
        fee += atachmentFee;
    }

    // fee for recepeints
    fee += MESSAGE_AMOUNT * static_cast<quint64>(m_recipientsModel->rowCount());
    // fee for message length
    fee += MESSAGE_CHAR_PRICE * static_cast<quint64>(messageSize);

    setMinMessageFee(static_cast<int>(fee));
    setMessageFee(m_minMessageFee);
}

void SendMessageModel::send()
{
    if (Settings::instance().isTrackingMode())
    {
        emit WalletAdapter::instance().showMessage(tr("Tracking Wallet"), tr("This is a tracking wallet. This action is not available."));
        return;
    }
    else {
    if (!WalletAdapter::instance().isOpen()) {
        return;
    }

    if(m_attachmentsModel->rowCount() == 0) {
        sendMessage(QString(), QString());
        return;
    }

    QTemporaryFile* tempFile = new QTemporaryFile(this);
    if(!tempFile->open()) {
        emit WalletAdapter::instance().showMessage(tr("Error"),
                            tr("Can't create temporary file for attachment"));
        return;
    }

    if(totalAttachmentsSize() > MAX_ATTACHMENT_SIZE) {
        emit WalletAdapter::instance().showMessage(tr("Error"),
                            tr("Attachments size exceed 100 megabyte maximum"));
        return;
    }

    packAttachments(tempFile);
    uploadAttachments(tempFile);
    }
}

void SendMessageModel::sendMessage(const QString& ipfsHash, const QString& encrpyptionKey) {
    QVector<CryptoNote::WalletLegacyTransfer> transfers;
    QVector<CryptoNote::TransactionMessage> messages;

    MessageHeader header;
    if(m_addReplyTo) {
        header.append(qMakePair(QString(MessagesModel::HEADER_REPLY_TO_KEY), WalletAdapter::instance().getAddress()));
    }
    if(!ipfsHash.isEmpty() && !encrpyptionKey.isEmpty()) {
        header.append(qMakePair(QString(MessagesModel::HEADER_ATTACHMENT), ipfsHash));
        header.append(qMakePair(QString(MessagesModel::HEADER_ATTACHMENT_ENCRYPTION_KEY), encrpyptionKey));
    }
    QString messageString = Message::makeTextMessage(m_message, header,true);

    transfers.reserve(m_recipientsModel->rowCount());
    for (int i = 0; i < m_recipientsModel->rowCount(); ++i) {
        QString address = extractAddress(m_recipientsModel->getAddress(i));
        if (!CurrencyAdapter::instance().validateAddress(address)) {
            emit WalletAdapter::instance().showMessage(tr("Error"),
                                                       tr("Invalid recipient address"));
            return;
        }

        transfers.append({address.toStdString(), MESSAGE_AMOUNT});
        messages.append({messageString.toStdString(), address.toStdString()});
    }

    quint64 fee = static_cast<quint64>(m_messageFee);
    fee -= MESSAGE_AMOUNT * static_cast<quint64>(transfers.size());
    if (fee < MINIMAL_MESSAGE_FEE) {
        emit WalletAdapter::instance().showMessage(tr("Error"),
                                                   tr("Incorrect fee value"));
        return;
    }

    if(WalletAdapter::instance().getActualBalance() < fee) {
        emit WalletAdapter::instance().showMessage(tr("Error"),
                                                   tr("Insufficient funds"));
        return;
    }

    quint64 ttl = 0;
    if (m_isSelfDestruct) {
        ttl = (static_cast<quint64>(m_selfDestructTimeMin) * MIN_TTL) + QDateTime::currentDateTimeUtc().toTime_t();
        fee = 0;
    }

    if (WalletAdapter::instance().isOpen()) {
        WalletAdapter::instance().sendMessage(transfers, fee,
                                              static_cast<quint64>(m_anonimityLevel),
                                              messages, ttl);
    }
}

QString SendMessageModel::extractAddress(const QString& _addressString)
{
    QString address = _addressString;
    if (_addressString.contains('<')) {
      int startPos = _addressString.indexOf('<');
      int endPos = _addressString.indexOf('>');
      address = _addressString.mid(startPos + 1, endPos - startPos - 1);
    }
    return address;
}

quint64 SendMessageModel::totalAttachmentsSize() const
{
    quint64 totalSize = 0;
    for(int idx = 0; idx < m_attachmentsModel->rowCount(); ++idx) {
        QFileInfo fileInfo(m_attachmentsModel->getFileName(idx));
        totalSize += static_cast<quint64>(fileInfo.size());
    }

    return totalSize;
}

void SendMessageModel::packAttachments(QTemporaryFile* archive)
{
    QZipWriter zip(archive);
    if(zip.status() != QZipWriter::NoError) {
        emit WalletAdapter::instance().showMessage(tr("Error"),
                                                   tr("Can't open attachment zip archive"));
        return;
    }

    zip.setCompressionPolicy(QZipWriter::NeverCompress);

    for(int idx = 0; idx < m_attachmentsModel->rowCount(); ++idx) {
        QFile file(m_attachmentsModel->getFileName(idx));
        if(!file.open(QIODevice::ReadOnly)) {
            emit WalletAdapter::instance().showMessage(tr("Error"),
                                                       tr("Can't open file %1").arg(file.fileName()));
            return;
        }

        zip.addFile(QFileInfo(file).fileName(), file.readAll());
    }
}

void SendMessageModel::uploadAttachments(QTemporaryFile* archive)
{
    QHttpMultiPart* multiPart = new QHttpMultiPart(QHttpMultiPart::FormDataType, this);
    QHttpPart attachmentPart;
    attachmentPart.setHeader(QNetworkRequest::ContentDispositionHeader, QVariant("form-data; name=\"file\"; filename=\"file\""));
    attachmentPart.setHeader(QNetworkRequest::ContentTypeHeader, QVariant("application/octet-stream"));
    archive->open();

    QByteArray payload = archive->readAll();
    QByteArray encryptionKey;
    WalletAdapter::instance().encryptAttachment(payload, encryptionKey);
    attachmentPart.setBody(payload);
    QString encryptionKeyStr = encryptionKey.toHex();

    multiPart->append(attachmentPart);
    archive->setParent(multiPart);

    QNetworkRequest request = QNetworkRequest(QUrl(IPFS_API_URL + "api/v0/add"));
    QNetworkReply* reply = m_networkAccessManager.post(request, multiPart);
    reply->setReadBufferSize(MAX_ATTACHMENT_SIZE);
    multiPart->setParent(reply);

    connect(reply, &QNetworkReply::finished, [encryptionKeyStr, this, reply]() {
        attachmentUploaded(reply, encryptionKeyStr);
    });

    showUploadProgress(reply);
}

void SendMessageModel::attachmentUploaded(QNetworkReply* reply, const QString& encryptionKey)
{
    reply->deleteLater();

    if(reply->error() == QNetworkReply::OperationCanceledError) {
        return;
    }

    if(reply->error()) {
        emit WalletAdapter::instance().showMessage(tr("Error"),
             tr("Can't upload attachment: ") + reply->errorString());
        return;
    }

    QJsonDocument jsonDocument = QJsonDocument::fromJson(reply->readAll());
    if(jsonDocument.isNull()) {
        emit WalletAdapter::instance().showMessage(tr("Error"),
             tr("Can't parse ipfs gateway response"));
        return;
    }

    QJsonValue hashJsonValue = jsonDocument.object().value(IPFS_RESPONSE_HASH_FIELD);
    if(hashJsonValue.isNull()) {
        emit WalletAdapter::instance().showMessage(tr("Error"),
             tr("Can't find \"Hash\" field in ipfs gateway response"));
        return;
    }

    sendMessage(hashJsonValue.toString(), encryptionKey);
}

void SendMessageModel::showUploadProgress(QNetworkReply* reply)
{
    connect(reply, &QNetworkReply::uploadProgress, [&](qint64 bytesSent, qint64 bytesTotal) {
        emit downloadProgressChanged(static_cast<double>(bytesSent) / bytesTotal);
    });
    connect(this, &SendMessageModel::abortDownload, reply, &QNetworkReply::abort);
    connect(reply, &QNetworkReply::finished, this, &SendMessageModel::abortDownload);
    emit showDownloadProgress();
}

void SendMessageModel::sendMessageCompleted(CryptoNote::TransactionId _transactionId,
                                            bool _error, const QString& _errorText)
{
    Q_UNUSED(_transactionId)
    if (_error) {
        emit WalletAdapter::instance().showMessage(tr("Error"), _errorText);
    } else {
        reset();
        emit WalletAdapter::instance().requestTransactionScreen();
    }
}

void SendMessageModel::reset()
{
  setAnonimityLevel(DEFAULT_MESSAGE_MIXIN);
  setMessageFee(MESSAGE_AMOUNT + MINIMAL_MESSAGE_FEE);
  setMessage("");
  m_recipientsModel->reset();
  m_attachmentsModel->reset();
}

} // WalletGui
