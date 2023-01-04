// Copyright (c) 2011-2017 The Cryptonote developers
// Copyright (c) 2014-2017 XDN developers
// Copyright (c) 2016-2017 BXC developers
// Copyright (c) 2017 UltraNote developers
// Distributed under the MIT/X11 software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#include <QClipboard>
#include <QFileDialog>
#include <QMimeData>
#include <QTemporaryFile>
#include <QHttpMultiPart>
#include <QJsonDocument>
#include <QJsonObject>

#include "../qzipwriter_p.h"

#include "SendMessageFrame.h"
#include "CurrencyAdapter.h"
#include "MainWindow.h"
#include "Message.h"
#include "MessageAddressFrame.h"
#include "MessageAttachmentFrame.h"
#include "MessagesModel.h"
#include "WalletAdapter.h"
#include "WalletEvents.h"
#include "NetworkProgressDialog.h"

#include "ui_sendmessageframe.h"

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

const QString SendMessageFrame::IPFS_API_URL = "http://backup.ultranote.org:5001/";
const QString SendMessageFrame::IPFS_RESPONSE_HASH_FIELD = "Hash";


SendMessageFrame::SendMessageFrame(QWidget* _parent) : QFrame(_parent), m_ui(new Ui::SendMessageFrame) {
  m_ui->setupUi(this);
  setAcceptDrops(true);
  m_ui->m_mixinSlider->setValue(DEFAULT_MESSAGE_MIXIN);
  m_ui->m_feeSpin->setMinimum(CurrencyAdapter::instance().formatAmount(MESSAGE_AMOUNT + MINIMAL_MESSAGE_FEE).toDouble());
  m_ui->m_feeSpin->setValue(m_ui->m_feeSpin->minimum());
  m_ui->m_ttlSlider->setVisible(false);
  m_ui->m_ttlLabel->setVisible(false);

  m_ui->m_ttlSlider->setMinimum(1);
  m_ui->m_ttlSlider->setMaximum(MAX_TTL / MIN_TTL);
  ttlValueChanged(m_ui->m_ttlSlider->value());
  connect(&WalletAdapter::instance(), &WalletAdapter::walletSendMessageCompletedSignal, this, &SendMessageFrame::sendMessageCompleted,
    Qt::QueuedConnection);

  reset();
}

SendMessageFrame::~SendMessageFrame() {
}

void SendMessageFrame::setAddress(const QString& _address) {
  m_ui->m_addReplyToCheck->setChecked(true);
}

void SendMessageFrame::sendMessageCompleted(cn::TransactionId _transactionId, bool _error, const QString& _errorText) {
  Q_UNUSED(_transactionId);
  if (_error) {
    QCoreApplication::postEvent(
      &MainWindow::instance(),
      new ShowMessageEvent(_errorText, QtCriticalMsg));
  } else {
    reset();
  }
}

void SendMessageFrame::reset() {
  m_ui->m_mixinSlider->setValue(DEFAULT_MESSAGE_MIXIN);
  m_ui->m_feeSpin->setValue(MESSAGE_AMOUNT + MINIMAL_MESSAGE_FEE);
  m_ui->m_messageTextEdit->clear();

  for (MessageAddressFrame* addressFrame : m_addressFrames) {
    addressFrame->deleteLater();
  }

  for(int idx = 0; idx < m_ui->m_attachmentsLayout->count(); ++idx) {
      m_ui->m_attachmentsLayout->itemAt(idx)->widget()->deleteLater();
  }

  addRecipientClicked();
}

QString SendMessageFrame::extractAddress(const QString& _addressString) const {
  QString address = _addressString;
  if (_addressString.contains('<')) {
    int startPos = _addressString.indexOf('<');
    int endPos = _addressString.indexOf('>');
    address = _addressString.mid(startPos + 1, endPos - startPos - 1);
  }

  return address;
}

void SendMessageFrame::recalculateFeeValue() {
  QString messageText = m_ui->m_messageTextEdit->toPlainText();
  quint32 messageSize = messageText.length() ;
  if (messageSize > 0) {
    --messageSize;
  }

  quint64 fee = 0;
  // fee for permanent message
  if(m_ui->m_ttlCheck->checkState() != Qt::Checked) {
    fee += MINIMAL_MESSAGE_FEE;
  }
  // fee for attachment
  if(m_ui->m_attachmentsLayout->count() > 0) {
    fee += MESSAGE_CHAR_PRICE * ATTACHMENT_HEADER_LENGTH;
    fee += MESSAGE_CHAR_PRICE * ATTACHMENT_ENCRYPTION_KEY_HEADER_LENGTH;
  }

  // fee for recepeints
  fee += MESSAGE_AMOUNT * m_addressFrames.size();
  // fee for message length
  fee += MESSAGE_CHAR_PRICE * messageSize;

  m_ui->m_feeSpin->setMinimum(CurrencyAdapter::instance().formatAmount(fee).toDouble());
  m_ui->m_feeSpin->setValue(m_ui->m_feeSpin->minimum());
}

void SendMessageFrame::addRecipientClicked() {
  MessageAddressFrame* newAddress = new MessageAddressFrame(m_ui->m_messageAddressScrollArea);
  m_ui->m_addressesLayout->insertWidget(m_addressFrames.size(), newAddress);
  m_addressFrames.append(newAddress);
  if (m_addressFrames.size() == 1) {
    newAddress->disableRemoveButton(true);
  } else {
    m_addressFrames[0]->disableRemoveButton(false);
  }

  connect(newAddress, &MessageAddressFrame::destroyed, [this](QObject* _obj) {
    m_addressFrames.removeOne(static_cast<MessageAddressFrame*>(_obj));
    if (m_addressFrames.size() == 1) {
      m_addressFrames[0]->disableRemoveButton(true);
    }

    recalculateFeeValue();
  });

  recalculateFeeValue();
  m_ui->m_messageAddressScrollArea->setFixedHeight(3 * newAddress->height());
}

void SendMessageFrame::dragEnterEvent(QDragEnterEvent* event) {
  if(event->mimeData()->hasUrls()) {
    event->acceptProposedAction();
  }
}

void SendMessageFrame::dragMoveEvent(QDragMoveEvent* event) {
  event->acceptProposedAction();
}

void SendMessageFrame::dropEvent(QDropEvent* event) {
  QStringList filenames;
  Q_FOREACH (const QUrl& url, event->mimeData()->urls()) {
    filenames.append(url.toLocalFile());
  }

  addAttachments(filenames);
}

void SendMessageFrame::addAttachmentClicked() {
  addAttachments(QFileDialog::getOpenFileNames(this, tr("Add attachments"), QDir::currentPath(), tr("All Files (*)")));
}

void SendMessageFrame::addAttachments(const QStringList& filenames) {
  if(filenames.isEmpty()) {
      return;
  }

  Q_FOREACH (const QString& filename, filenames) {
    if(isAttachmentExist(filename)) {
      continue;
    }

    MessageAttachmentFrame* newAttachment = new MessageAttachmentFrame(m_ui->m_messageAttachmentScrollArea, filename);
    m_ui->m_attachmentsLayout->addWidget(newAttachment, 0, Qt::AlignTop);

    connect(newAttachment, &MessageAttachmentFrame::destroyed, [this](QObject* _obj) {
      // postpone fee recalculation, because MessageAttachmentFrame still exist right now
      QTimer::singleShot(0, this, SLOT(recalculateFeeValue()));
    });
  }

  recalculateFeeValue();
}

bool SendMessageFrame::isAttachmentExist(const QString& filename) {
  for(int idx = 0; idx < m_ui->m_attachmentsLayout->count(); ++idx) {
    QWidget* widget = m_ui->m_attachmentsLayout->itemAt(idx)->widget();
    MessageAttachmentFrame* attachmentFrame = qobject_cast<MessageAttachmentFrame*>(widget);

    if(filename == attachmentFrame->getFileName()) {
        return true;
    }
  }

  return false;
}

void SendMessageFrame::messageTextChanged() {
  recalculateFeeValue();
}

void SendMessageFrame::mixinValueChanged(int _value) {
  m_ui->m_mixinEdit->setText(QString::number(_value));
}

void SendMessageFrame::sendClicked() {
  if (!WalletAdapter::instance().isOpen()) {
    return;
  }

  if(m_ui->m_attachmentsLayout->count() == 0) {
    sendMessage(QString(), QString());
    return;
  }

  QTemporaryFile* tempFile = new QTemporaryFile(this);
  if(!tempFile->open()) {
    QCoreApplication::postEvent(&MainWindow::instance(),
                                new ShowMessageEvent(tr("Can't create temporary file for attachment"),
                                                     QtCriticalMsg));
    return;
  }

  if(totalAttachmentsSize() > MAX_ATTACHMENT_SIZE) {
    QCoreApplication::postEvent(&MainWindow::instance(),
                                new ShowMessageEvent(tr("Attachments size exceed 100 megabyte maximum"),
                                                     QtCriticalMsg));
    return;
  }

  packAttachments(tempFile);
  uploadAttachments(tempFile);
}

qint64 SendMessageFrame::totalAttachmentsSize() {
  qint64 totalSize = 0;
  for(int idx = 0; idx < m_ui->m_attachmentsLayout->count(); ++idx) {
    QWidget* widget = m_ui->m_attachmentsLayout->itemAt(idx)->widget();
    MessageAttachmentFrame* attachmentFrame = qobject_cast<MessageAttachmentFrame*>(widget);

    QFileInfo fileInfo(attachmentFrame->getFileName());
    totalSize += fileInfo.size();
  }

  return totalSize;
}


void SendMessageFrame::packAttachments(QTemporaryFile* archive) {
  QZipWriter zip(archive);
  if(zip.status() != QZipWriter::NoError) {
    QCoreApplication::postEvent(&MainWindow::instance(),
                                new ShowMessageEvent(tr("Can't open attachment zip archive"), QtCriticalMsg));
    return;
  }

  zip.setCompressionPolicy(QZipWriter::NeverCompress);

  for(int idx = 0; idx < m_ui->m_attachmentsLayout->count(); ++idx) {
    QWidget* widget = m_ui->m_attachmentsLayout->itemAt(idx)->widget();
    MessageAttachmentFrame* attachmentFrame = qobject_cast<MessageAttachmentFrame*>(widget);

    QFile file(attachmentFrame->getFileName());
    if(!file.open(QIODevice::ReadOnly)) {
      QCoreApplication::postEvent(&MainWindow::instance(),
                                  new ShowMessageEvent(QString(tr("Can't open file %1")).arg(attachmentFrame->getFileName()),
                                                       QtCriticalMsg));
      return;
    }

    zip.addFile(QFileInfo(file).fileName(), file.readAll());
  }
}

void SendMessageFrame::uploadAttachments(QTemporaryFile* archive) {
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

void SendMessageFrame::showUploadProgress(QNetworkReply* reply) {
  NetworkProgressDialog* progressDialog = new NetworkProgressDialog(this, tr("Uploading attachment"));
  connect(reply, &QNetworkReply::uploadProgress, progressDialog, &NetworkProgressDialog::networkProgress);
  connect(progressDialog, &QProgressDialog::canceled, reply, &QNetworkReply::abort);
  connect(reply, &QNetworkReply::finished, progressDialog, &NetworkProgressDialog::close);
  progressDialog->show();
}

void SendMessageFrame::attachmentUploaded(QNetworkReply* reply, const QString& encryptionKey) {
  reply->deleteLater();

  if(reply->error() == QNetworkReply::OperationCanceledError) {
    return;
  }

  if(reply->error()) {
    QCoreApplication::postEvent(&MainWindow::instance(),
                                new ShowMessageEvent(tr("Can't upload attachment: ") + reply->errorString(),
                                                     QtCriticalMsg));
    return;
  }

  QJsonDocument jsonDocument = QJsonDocument::fromJson(reply->readAll());
  if(jsonDocument.isNull()) {
    QCoreApplication::postEvent(&MainWindow::instance(),
                                new ShowMessageEvent(tr("Can't parse ipfs gateway response"), QtCriticalMsg));
    return;
  }

  QJsonValue hashJsonValue = jsonDocument.object().value(IPFS_RESPONSE_HASH_FIELD);
  if(hashJsonValue.isNull()) {
    QCoreApplication::postEvent(&MainWindow::instance(),
                                new ShowMessageEvent(tr("Can't find \"Hash\" field in ipfs gateway response"),
                                                     QtCriticalMsg));
    return;
  }

  sendMessage(hashJsonValue.toString(), encryptionKey);
}

void SendMessageFrame::sendMessage(const QString& ipfsHash, const QString& encrpyptionKey) {
  QVector<cn::WalletLegacyTransfer> transfers;
  QVector<cn::TransactionMessage> messages;

  MessageHeader header;
  if(m_ui->m_addReplyToCheck->isChecked()) {
    header.append(qMakePair(QString(MessagesModel::HEADER_REPLY_TO_KEY), WalletAdapter::instance().getAddress()));
  }
  if(!ipfsHash.isEmpty() && !encrpyptionKey.isEmpty()) {
    header.append(qMakePair(QString(MessagesModel::HEADER_ATTACHMENT), ipfsHash));
    header.append(qMakePair(QString(MessagesModel::HEADER_ATTACHMENT_ENCRYPTION_KEY), encrpyptionKey));
  }

  QString messageString = Message::makeTextMessage(m_ui->m_messageTextEdit->toPlainText(), header,true);

  transfers.reserve(m_addressFrames.size());
  for (MessageAddressFrame* addressFrame : m_addressFrames) {
    QString address = extractAddress(addressFrame->getAddress());
    if (!CurrencyAdapter::instance().validateAddress(address)) {
      QCoreApplication::postEvent(&MainWindow::instance(), new ShowMessageEvent(tr("Invalid recipient address"), QtCriticalMsg));
      return;
    }

    transfers.append({address.toStdString(), MESSAGE_AMOUNT});
    messages.append({messageString.toStdString(), address.toStdString()});
  }

  quint64 fee = CurrencyAdapter::instance().parseAmount(m_ui->m_feeSpin->cleanText());
  fee -= MESSAGE_AMOUNT * transfers.size();
  if (fee < MINIMAL_MESSAGE_FEE) {
    QCoreApplication::postEvent(&MainWindow::instance(), new ShowMessageEvent(tr("Incorrect fee value"), QtCriticalMsg));
    return;
  }

  if(WalletAdapter::instance().getActualBalance() < fee) {
    QCoreApplication::postEvent(&MainWindow::instance(), new ShowMessageEvent(tr("Insufficient funds"), QtCriticalMsg));
    return;
  }

  quint64 ttl = 0;
  if (m_ui->m_ttlCheck->checkState() == Qt::Checked) {
    ttl = QDateTime::currentDateTimeUtc().toTime_t() + m_ui->m_ttlSlider->value() * MIN_TTL;
    fee = 0;
  }

  if (WalletAdapter::instance().isOpen()) {
    WalletAdapter::instance().sendMessage(transfers, fee, m_ui->m_mixinSlider->value(), messages, ttl);
  }
}

void SendMessageFrame::ttlCheckStateChanged(int _state) {
  recalculateFeeValue();
}

void SendMessageFrame::ttlValueChanged(int _ttlValue) {
  quint32 value = _ttlValue * MIN_TTL;
  quint32 hours = value / HOUR_SECONDS;
  quint32 minutes = value % HOUR_SECONDS / MINUTE_SECONDS;
  m_ui->m_ttlLabel->setText(QString("%1h %2m").arg(hours).arg(minutes));
}

}
