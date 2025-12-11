// Copyright (c) 2011-2017 The Cryptonote developers
// Copyright (c) 2014-2017 XDN developers
// Copyright (c) 2016-2017 BXC developers
// Copyright (c) 2017 UltraNote developers
// Distributed under the MIT/X11 software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#include <QApplication>
#include <QClipboard>
#include <QFileDialog>
#include <QHttpMultiPart>
#include <QJsonDocument>
#include <QJsonObject>
#include <QMimeData>
#include <QTemporaryFile>

#include "../qzipwriter_p.h"

#include "AddressBookDialog.h"
#include "AliasProvider.h"
#include "InvoiceService.h"
#include "MainWindow.h"
#include "Message.h"
#include "MessageAddressFrame.h"
#include "MessageAttachmentFrame.h"
#include "MessagesModel.h"
#include "NetworkProgressDialog.h"
#include "WalletAdapter.h"
#include "WalletEvents.h"

#include "MessageAttachmentFrame.h"
#include <Common/DnsTools.h>

namespace WalletGui {

Q_DECL_CONSTEXPR int DEFAULT_MESSAGE_MIXIN = 2;
Q_DECL_CONSTEXPR quint32 MINUTE_SECONDS = 60;
Q_DECL_CONSTEXPR quint32 HOUR_SECONDS = 60 * MINUTE_SECONDS;
Q_DECL_CONSTEXPR int MIN_TTL = 5 * MINUTE_SECONDS;
Q_DECL_CONSTEXPR int MAX_TTL = 14 * HOUR_SECONDS;
Q_DECL_CONSTEXPR int TTL_STEP = 5 * MINUTE_SECONDS;
Q_DECL_CONSTEXPR quint64 MESSAGE_AMOUNT = 1000;
Q_DECL_CONSTEXPR int MESSAGE_AMOUNT_PRECISION = 8;
Q_DECL_CONSTEXPR quint64 MESSAGE_CHAR_PRICE = 100;
Q_DECL_CONSTEXPR quint64 MINIMAL_MESSAGE_FEE = MESSAGE_CHAR_PRICE;

Q_DECL_CONSTEXPR quint64 ATTACHMENT_HEADER_LENGTH = 59;
Q_DECL_CONSTEXPR quint64 ATTACHMENT_ENCRYPTION_KEY_HEADER_LENGTH = 92;
Q_DECL_CONSTEXPR quint64 MAX_ATTACHMENT_SIZE = 100 * 1024 * 1024;

const QString InvoiceService::IPFS_API_URL = "http://backup.ultranote.org:5001/";
const QString InvoiceService::IPFS_RESPONSE_HASH_FIELD = "Hash";

Q_DECL_CONSTEXPR quint32 TRANSACTION_ADDRESS_INPUT_INTERVAL = 1500;

Q_DECL_CONSTEXPR int DEFAULT_MIXIN = 2;
Q_DECL_CONSTEXPR quint64 COMMENT_CHAR_PRICE = 100;

InvoiceService::InvoiceService(QObject* _parent)
    : QObject(_parent)
    , m_ttlMaximumValue(MAX_TTL / MIN_TTL)
    , m_ttlValue(DEFAULT_MESSAGE_MIXIN)
    , m_feeMinimalValue(CurrencyAdapter::instance().formatAmount(MESSAGE_AMOUNT + MINIMAL_MESSAGE_FEE).toDouble())
    , m_feeValue(CurrencyAdapter::instance().formatAmount(MESSAGE_AMOUNT + MINIMAL_MESSAGE_FEE).toDouble())
    , m_mixinValue(DEFAULT_MESSAGE_MIXIN)
    , m_addressInputTimer(new QTimer{ this })
    , m_aliasProvider(new AliasProvider(this))
{
    m_addressInputTimer->setInterval(TRANSACTION_ADDRESS_INPUT_INTERVAL);
    m_addressInputTimer->setSingleShot(true);

    connect(m_aliasProvider, &AliasProvider::aliasFoundSignal, this, &InvoiceService::onAliasFound);
    connect(this, &InvoiceService::addressChanged, this, &InvoiceService::updateQRCode, Qt::QueuedConnection);
    connect(this, &InvoiceService::amountChanged, this, &InvoiceService::updateQRCode, Qt::QueuedConnection);
    connect(this, &InvoiceService::paymentIDChanged, this, &InvoiceService::updateQRCode, Qt::QueuedConnection);
    connect(this, &InvoiceService::invoiceIDChanged, this, &InvoiceService::updateQRCode, Qt::QueuedConnection);
    connect(this, &InvoiceService::invoiceMessageTextChanged, this, &InvoiceService::onMessageTextChanged);
    connect(m_addressInputTimer, &QTimer::timeout, this, &InvoiceService::checkAddressAlias, Qt::QueuedConnection);

    reset();
}

InvoiceService::~InvoiceService()
{
}

void InvoiceService::sendMessageCompleted(cn::TransactionId _transactionId, bool _error, const QString& _errorText)
{
    Q_UNUSED(_transactionId)
    if (_error) {
        QCoreApplication::postEvent(
                    &MainWindow::instance(),
                    new ShowMessageEvent(_errorText, QtCriticalMsg));
    }
    else {
        reset();
    }
}

void InvoiceService::reset()
{
    setMixinValue(DEFAULT_MESSAGE_MIXIN);
    setFeeValue(MESSAGE_AMOUNT + MINIMAL_MESSAGE_FEE);
    setinvoiceMessageText("");
    setAddress("");
    setLabel("");
    setPaymentID("");
    setAmount(0.0);
    setInvoiceID("");
    setQrPayload("");

    m_attachmentsModel->setStringList(QStringList());
}

QString InvoiceService::base64Encode(QString string)
{
    QByteArray ba;
    ba.append(string);
    return ba.toBase64();
}

void InvoiceService::updateQRCode()
{
    QString delimiter = " ";

    QString invoiceCode = getAddress()
            + delimiter + getPaymentId()
            + delimiter + base64Encode(getInvoiceId())
            + delimiter + getAmountString();
    setQrPayload(invoiceCode);
}

QString InvoiceService::getAddress() const
{
    QString address = m_address;
    if (address.contains('<')) {
        int startPos = address.indexOf('<');
        int endPos = address.indexOf('>');
        address = address.mid(startPos + 1, endPos - startPos - 1);
    }

    return address;
}

QString InvoiceService::getLabel() const
{
    return m_label;
}

qreal InvoiceService::getAmount() const
{
    return m_amount;
}

QString InvoiceService::getAmountString() const
{
    return QString::number(m_amount, 'f', MESSAGE_AMOUNT_PRECISION);
}

QString InvoiceService::getInvoiceId() const
{
    return m_invoiceID;
}

QString InvoiceService::getPaymentId() const
{
    return m_paymentID;
}

void InvoiceService::onAliasFound(const QString& _name, const QString& _address)
{
    qDebug() << "ALIAS FOUND";
    setAddress(QString("%1 <%2>").arg(_name).arg(_address));
}

void InvoiceService::checkAddressAlias()
{
    if (!m_aliasProvider->isActive()) {
        m_aliasProvider->getAddresses(m_address);
    }
}

void InvoiceService::pasteClicked()
{
    setAddress(QApplication::clipboard()->text());
}

void InvoiceService::removeAttachment(int index)
{
    if (index >= 0 && index < m_attachmentsModel->rowCount()) {
        m_attachmentsModel->removeRow(index);
    }

    recalculateFeeValue();
}

void InvoiceService::invoiceIdEdited(const QString& _text)
{
    setInvoiceID(_text);
    recalculateFeeValue();
}

QString InvoiceService::extractAddress(const QString& _addressString) const
{
    QString address = _addressString;
    if (_addressString.contains('<')) {
        int startPos = _addressString.indexOf('<');
        int endPos = _addressString.indexOf('>');
        address = _addressString.mid(startPos + 1, endPos - startPos - 1);
    }

    return address;
}

void InvoiceService::recalculateFeeValue()
{
    QString messageText = m_invoiceMessageText;
    quint32 messageSize = messageText.length();
    if (messageSize > 0) {
        --messageSize;
    }

    quint32 invoiceIdSize = getInvoiceId().length();
    if (invoiceIdSize > 0) {
        --invoiceIdSize;
    }

    quint32 invoiceAmountSize = getAmountString().length();
    if (invoiceAmountSize > 0) {
        --invoiceAmountSize;
    }

    quint32 paymentIdSize = getPaymentId().length();
    if (paymentIdSize > 0) {
        --paymentIdSize;
    }

    quint64 fee = 0;
    // fee for permanent message
    if (!m_ttlEnabled) {
        fee += MINIMAL_MESSAGE_FEE;
    }

    // fee for attachment
    if (m_attachmentsModel->rowCount() > 0) {
        quint64 atachmentFee = 0;
        atachmentFee += MESSAGE_CHAR_PRICE * ATTACHMENT_HEADER_LENGTH;
        atachmentFee += MESSAGE_CHAR_PRICE * ATTACHMENT_ENCRYPTION_KEY_HEADER_LENGTH;
        atachmentFee *= m_attachmentsModel->rowCount();
        fee += atachmentFee;
    }

    // fee for invoiceId
    fee += MESSAGE_CHAR_PRICE * invoiceIdSize;

    // fee for invoice amount
    fee += MESSAGE_CHAR_PRICE * invoiceAmountSize;

    // fee for paymentId
    fee += MESSAGE_CHAR_PRICE * paymentIdSize;

    // fee for recepeint
    fee += MESSAGE_AMOUNT;

    // fee for message length
    fee += MESSAGE_CHAR_PRICE * messageSize;

    setFeeMinimalValue(CurrencyAdapter::instance().formatAmount(fee).toDouble());
    setFeeValue(fee);
}

void InvoiceService::addAttachments(const QStringList& filenames)
{
    if (filenames.isEmpty()) {
        return;
    }

    QStringList attachments = m_attachmentsModel->stringList();

    for (const QString& filename : filenames) {
        if (isAttachmentExist(filename)) {
            continue;
        }

        attachments.append(filename);
    }

    m_attachmentsModel->setStringList(attachments);

    recalculateFeeValue();
}

bool InvoiceService::isAttachmentExist(const QString& filename)
{
    return m_attachmentsModel->stringList().contains(filename);
}

void InvoiceService::onMessageTextChanged()
{
    recalculateFeeValue();
}

void InvoiceService::mixinValueChanged(int _value)
{
    setMixinValue(_value);
}

void InvoiceService::sendClicked()
{
    if (!WalletAdapter::instance().isOpen()) {
        return;
    }

    if (Settings::instance().isTrackingMode())
    {
        emit WalletAdapter::instance().showMessage(tr("Tracking Wallet"), tr("This is a tracking wallet. This action is not available."));
        return;
    }
    else {
    if (m_attachmentsModel->rowCount() == 0) {
        sendMessage(QString(), QString());
        return;
    }

    QTemporaryFile* tempFile = new QTemporaryFile(this);
    if (!tempFile->open()) {
        QCoreApplication::postEvent(&MainWindow::instance(),
                                    new ShowMessageEvent(tr("Can't create temporary file for attachment"),
                                                         QtCriticalMsg));
        return;
    }

    if (totalAttachmentsSize() > MAX_ATTACHMENT_SIZE) {
        QCoreApplication::postEvent(&MainWindow::instance(),
                                    new ShowMessageEvent(tr("Attachments size exceed 100 megabyte maximum"),
                                                         QtCriticalMsg));
        return;
    }

    packAttachments(tempFile);
    uploadAttachments(tempFile);
    }
}

qint64 InvoiceService::totalAttachmentsSize()
{
    qint64 totalSize = 0;
    for (const auto& attachment : m_attachmentsModel->stringList()) {
        QFileInfo fileInfo(attachment);
        totalSize += fileInfo.size();
    }

    return totalSize;
}

void InvoiceService::packAttachments(QTemporaryFile* archive)
{
    QZipWriter zip(archive);
    if (zip.status() != QZipWriter::NoError) {
        QCoreApplication::postEvent(&MainWindow::instance(),
                                    new ShowMessageEvent(tr("Can't open attachment zip archive"), QtCriticalMsg));
        return;
    }

    zip.setCompressionPolicy(QZipWriter::NeverCompress);

    for (const auto& attachment : m_attachmentsModel->stringList()) {
        QUrl fileUrl(attachment);
        QFile file(fileUrl.toLocalFile());
        if (!file.open(QIODevice::ReadOnly)) {
            QCoreApplication::postEvent(&MainWindow::instance(),
                                        new ShowMessageEvent(QString(tr("Can't open file %1")).arg(attachment),
                                                             QtCriticalMsg));
            return;
        }

        zip.addFile(QFileInfo(file).fileName(), file.readAll());
    }
}

void InvoiceService::uploadAttachments(QTemporaryFile* archive)
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
    QNetworkReply* reply = networkAccessManager.post(request, multiPart);
    reply->setReadBufferSize(MAX_ATTACHMENT_SIZE);
    multiPart->setParent(reply);

    connect(reply, &QNetworkReply::finished, [encryptionKeyStr, this, reply]() {
        attachmentUploaded(reply, encryptionKeyStr);
    });

    showUploadProgress(reply);
}

void InvoiceService::attachmentUploaded(QNetworkReply* reply, const QString& encryptionKey)
{
    reply->deleteLater();

    if (reply->error() == QNetworkReply::OperationCanceledError) {
        return;
    }

    if (reply->error()) {
        QCoreApplication::postEvent(&MainWindow::instance(),
                                    new ShowMessageEvent(tr("Can't upload attachment: ") + reply->errorString(),
                                                         QtCriticalMsg));
        return;
    }

    QJsonDocument jsonDocument = QJsonDocument::fromJson(reply->readAll());
    if (jsonDocument.isNull()) {
        QCoreApplication::postEvent(&MainWindow::instance(),
                                    new ShowMessageEvent(tr("Can't parse ipfs gateway response"), QtCriticalMsg));
        return;
    }

    QJsonValue hashJsonValue = jsonDocument.object().value(IPFS_RESPONSE_HASH_FIELD);
    if (hashJsonValue.isNull()) {
        QCoreApplication::postEvent(&MainWindow::instance(),
                                    new ShowMessageEvent(tr("Can't find \"Hash\" field in ipfs gateway response"),
                                                         QtCriticalMsg));
        return;
    }

    sendMessage(hashJsonValue.toString(), encryptionKey);
}

void InvoiceService::sendMessage(const QString& ipfsHash, const QString& encrpyptionKey)
{
    QVector<cn::WalletLegacyTransfer> transfers;
    QVector<cn::TransactionMessage> messages;

    MessageHeader header;
    if (m_replyToChecked) {
        header.append(qMakePair(QString(MessagesModel::HEADER_REPLY_TO_KEY), WalletAdapter::instance().getAddress()));
    }
    if (!ipfsHash.isEmpty() && !encrpyptionKey.isEmpty()) {
        header.append(qMakePair(QString(MessagesModel::HEADER_ATTACHMENT), ipfsHash));
        header.append(qMakePair(QString(MessagesModel::HEADER_ATTACHMENT_ENCRYPTION_KEY), encrpyptionKey));
    }
    header.append(qMakePair(QString(MessagesModel::HEADER_PAYMENT_ID), getPaymentId()));
    header.append(qMakePair(QString(MessagesModel::HEADER_INVOICE_ID), getInvoiceId()));
    header.append(qMakePair(QString(MessagesModel::HEADER_INVOICE_AMOUNT), getAmountString()));

    QString messageString = Message::makeTextMessage(m_invoiceMessageText, header, true);

    transfers.reserve(1);
    //  for (MessageAddressFrame* addressFrame : m_addressFrames) {
    QString address = extractAddress(getAddress());
    
    // Check if address is a valid UltraNote address
    if (!CurrencyAdapter::instance().validateAddress(address)) {
        // Might be a DNS alias, try to resolve it
        qDebug() << "[InvoiceService] Address is not a valid UltraNote address, trying DNS alias resolution...";
        QString resolvedAddress = address;
        
        // Try to resolve as OpenAlias DNS record
        std::string domainStr = address.toStdString();
        std::vector<std::string> records;
        
        qDebug() << "[InvoiceService] Attempting DNS resolution for:" << address;
        if (common::fetch_dns_txt(domainStr, records)) {
            qDebug() << "[InvoiceService] DNS resolution successful, records found:" << records.size();
            // Try to parse OpenAlias record
            for (const auto& record : records) {
                QString qrecord = QString::fromStdString(record);
                qDebug() << "[InvoiceService] Checking DNS record:" << qrecord;
                if (qrecord.contains("oa1:xuni")) {
                    qDebug() << "[InvoiceService] Found OpenAlias record (oa1:xuni)";
                    // Parse OpenAlias format: oa1:xuni recipient_address=<address>; recipient_name=<name>;
                    QRegularExpression regex("recipient_address=([^;]+)");
                    QRegularExpressionMatch match = regex.match(qrecord);
                    if (match.hasMatch()) {
                        QString aliasAddress = match.captured(1).trimmed();
                        qDebug() << "[InvoiceService] Parsed address from OpenAlias:" << aliasAddress;
                        // Validate the address
                        if (CurrencyAdapter::instance().validateAddress(aliasAddress)) {
                            qDebug() << "[InvoiceService] Parsed address is valid UltraNote address";
                            resolvedAddress = aliasAddress;
                            break;
                        } else {
                            qDebug() << "[InvoiceService] Parsed address is NOT a valid UltraNote address";
                        }
                    }
                }
            }
        } else {
            qDebug() << "[InvoiceService] DNS resolution failed for:" << address;
        }
        
        // If still not a valid address, show error
        if (!CurrencyAdapter::instance().validateAddress(resolvedAddress)) {
            qDebug() << "[InvoiceService] Address resolution failed. Original:" << address << "Resolved:" << resolvedAddress;
            QCoreApplication::postEvent(&MainWindow::instance(), 
                new ShowMessageEvent(tr("The address '%1' is not a valid UltraNote address and could not be resolved as a DNS alias.").arg(address), 
                QtCriticalMsg));
            return;
        }
        
        address = resolvedAddress;
        qDebug() << "[InvoiceService] Successfully resolved alias to address:" << address;
    }

    transfers.append({ address.toStdString(), MESSAGE_AMOUNT });
    messages.append({ messageString.toStdString(), address.toStdString() });
    //  }

    quint64 fee = m_feeValue;
    fee -= MESSAGE_AMOUNT * transfers.size();
    if (fee < MINIMAL_MESSAGE_FEE) {
        QCoreApplication::postEvent(&MainWindow::instance(), new ShowMessageEvent(tr("Incorrect fee value"), QtCriticalMsg));
        return;
    }

    if (WalletAdapter::instance().getActualBalance() < fee) {
        QCoreApplication::postEvent(&MainWindow::instance(), new ShowMessageEvent(tr("Insufficient funds"), QtCriticalMsg));
        return;
    }

    if (!isValidPaymentId(getPaymentId().toUtf8())) {
        QCoreApplication::postEvent(&MainWindow::instance(), new ShowMessageEvent(tr("Invalid payment ID"), QtCriticalMsg));
        return;
    }

    quint64 ttl = 0;
    if (m_ttlEnabled) {
        ttl = QDateTime::currentDateTimeUtc().toTime_t() + m_ttlValue * MIN_TTL;
        fee = 0;
    }

    if (WalletAdapter::instance().isOpen()) {
        //TODO this related to cryptonote developers - method doesn't contain paymentID as 6-th parameter
        WalletAdapter::instance().sendMessage(transfers, fee, m_mixinValue, messages, ttl);
    }
}

void InvoiceService::ttlCheckStateChanged(int _state)
{
    recalculateFeeValue();
}

void InvoiceService::ttlValueChanged(int _ttlValue)
{
    quint32 value = _ttlValue * MIN_TTL;
    quint32 hours = value / HOUR_SECONDS;
    quint32 minutes = value % HOUR_SECONDS / MINUTE_SECONDS;
    setTtlDecoratedValue(QString("= %1h %2m").arg(hours).arg(minutes));
}

bool InvoiceService::isValidPaymentId(const QByteArray& _paymentIdString)
{
    if (_paymentIdString.isEmpty()) {
        return true;
    }

    QByteArray paymentId = QByteArray::fromHex(_paymentIdString);
    return (paymentId.size() == sizeof(crypto::Hash)) && (_paymentIdString.toUpper() == paymentId.toHex().toUpper());
}

void InvoiceService::addAttachmentClicked(const QString& fileUrl)
{
    addAttachments(QStringList() << fileUrl);
}

void InvoiceService::showUploadProgress(QNetworkReply* reply)
{
    NetworkProgressDialog* progressDialog = new NetworkProgressDialog(nullptr, tr("Uploading attachment"));
    connect(reply, &QNetworkReply::uploadProgress, progressDialog, &NetworkProgressDialog::networkProgress);
    connect(progressDialog, &QProgressDialog::canceled, reply, &QNetworkReply::abort);
    connect(reply, &QNetworkReply::finished, progressDialog, &NetworkProgressDialog::close);
    progressDialog->show();
}

void InvoiceService::addressEdited()
{
    QMutexLocker lock(&timerMutex);
    qDebug() << "ADDRESS EDITED";
    if (!m_addressInputTimer->isActive()) {
        qDebug() << "ADDRESS TIMER START";
        m_addressInputTimer->start();
    }
}
}
