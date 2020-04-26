// Copyright (c) 2011-2017 The Cryptonote developers
// Copyright (c) 2014-2017 XDN developers
// Copyright (c) 2016-2017 BXC developers
// Copyright (c) 2017 UltraNote developers
// Distributed under the MIT/X11 software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#pragma once

#include <QDataWidgetMapper>
#include <QDialog>
#include <QNetworkAccessManager>
#include <QNetworkReply>

namespace Ui {
class MessageDetailsDialog;
}

namespace WalletGui {

class MessageDetailsDialog : public QDialog {
  Q_OBJECT

public:
  MessageDetailsDialog(const QModelIndex& _index, QWidget* _parent);
  ~MessageDetailsDialog();

  static const QString IPFS_API_URL;

  QModelIndex getCurrentMessageIndex() const;

private:
  QNetworkAccessManager m_networAccesskManager;
  QScopedPointer<Ui::MessageDetailsDialog> m_ui;
  QDataWidgetMapper m_dataMapper;
  QString attachmentDirectory;
  void showUploadProgress(QNetworkReply* reply);
  void extractAttachment(const QByteArray& data);

  Q_SLOT void prevClicked();
  Q_SLOT void nextClicked();
  Q_SLOT void saveClicked();
  Q_SLOT void downloadClicked();
  Q_SLOT void attachmentDownloaded(QNetworkReply*  reply);
};

}
