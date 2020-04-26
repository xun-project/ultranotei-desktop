// Copyright (c) 2011-2017 The Cryptonote developers
// Copyright (c) 2014-2017 XDN developers
// Copyright (c) 2016-2017 BXC developers
// Copyright (c) 2017 UltraNote developers
// Distributed under the MIT/X11 software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#pragma once

#include <QFrame>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QDrag>
#include <QDragEnterEvent>
#include <QDragMoveEvent>
#include <QDropEvent>

#include <IWalletLegacy.h>

namespace Ui {
class SendMessageFrame;
}

namespace WalletGui {

class MessageAddressFrame;

class SendMessageFrame : public QFrame {
  Q_OBJECT
  Q_DISABLE_COPY(SendMessageFrame)

public:
  SendMessageFrame(QWidget* _parent);
  ~SendMessageFrame();

  void setAddress(const QString& _address);
  void dragEnterEvent(QDragEnterEvent* event) Q_DECL_OVERRIDE;
  void dragMoveEvent(QDragMoveEvent* event) Q_DECL_OVERRIDE;
  void dropEvent(QDropEvent* event) Q_DECL_OVERRIDE;

private:
  static const QString IPFS_API_URL;
  static const QString IPFS_RESPONSE_HASH_FIELD;

  QScopedPointer<Ui::SendMessageFrame> m_ui;
  QList<MessageAddressFrame*> m_addressFrames;
  QNetworkAccessManager networkAccessManager;

  void sendMessage(const QString& ipfsHash, const QString& encrpyptionKey);
  void sendMessageCompleted(CryptoNote::TransactionId _transactionId, bool _error, const QString& _errorText);
  void reset();
  void addAttachments(const QStringList& filenames);
  qint64 totalAttachmentsSize();
  bool isAttachmentExist(const QString &filename);
  void packAttachments(QTemporaryFile* archive);
  void uploadAttachments(QTemporaryFile* archive);
  void showUploadProgress(QNetworkReply* reply);
  void attachmentUploaded(QNetworkReply *reply,const QString& encryptionKey);
  void packAttachmentsToArchive(const QIODevice *archive);

  QString extractAddress(const QString& _addressString) const;

  Q_SLOT void recalculateFeeValue();
  Q_SLOT void addRecipientClicked();
  Q_SLOT void addAttachmentClicked();
  Q_SLOT void messageTextChanged();
  Q_SLOT void mixinValueChanged(int _value);
  Q_SLOT void sendClicked();
  Q_SLOT void ttlCheckStateChanged(int _state);
  Q_SLOT void ttlValueChanged(int _ttlValue);
};

}
