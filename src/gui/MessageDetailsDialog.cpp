// Copyright (c) 2011-2017 The Cryptonote developers
// Copyright (c) 2014-2017 XDN developers
// Copyright (c) 2016-2017 BXC developers
// Copyright (c) 2017 UltraNote developers
// Distributed under the MIT/X11 software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#include <QFileDialog>
#include <QMessageBox>
#include <QTemporaryFile>

#include "NetworkProgressDialog.h"
#include "MessageDetailsDialog.h"
#include "MainWindow.h"
#include "MessagesModel.h"
#include "WalletEvents.h"
#include "WalletAdapter.h"
#include "../qzipreader_p.h"

#include "ui_messagedetailsdialog.h"

namespace WalletGui {

Q_DECL_CONSTEXPR quint64 DOWNLOAD_BUFFER_SIZE = 100 * 1024 * 1024;

const QString MessageDetailsDialog::IPFS_API_URL = "http://backup.ultranote.org:8080/ipfs/";


MessageDetailsDialog::MessageDetailsDialog(const QModelIndex& _index, QWidget* _parent) : QDialog(_parent),
  m_ui(new Ui::MessageDetailsDialog),
  attachmentDirectory(QDir::currentPath()) {
  m_ui->setupUi(this);
  QModelIndex modelIndex = MessagesModel::instance().index(_index.data(MessagesModel::ROLE_ROW).toInt(), 0);
  m_dataMapper.setModel(&MessagesModel::instance());
  m_dataMapper.addMapping(m_ui->m_heightLabel, MessagesModel::COLUMN_HEIGHT, "text");
  m_dataMapper.addMapping(m_ui->m_hashLabel, MessagesModel::COLUMN_HASH, "text");
  m_dataMapper.addMapping(m_ui->m_amountLabel, MessagesModel::COLUMN_AMOUNT, "text");
  m_dataMapper.addMapping(m_ui->m_sizeLabel, MessagesModel::COLUMN_MESSAGE_SIZE, "text");
  m_dataMapper.addMapping(m_ui->m_messageTextEdit, MessagesModel::COLUMN_FULL_MESSAGE, "plainText");
  m_dataMapper.addMapping(m_ui->m_replyButton, MessagesModel::COLUMN_HAS_REPLY_TO, "enabled");
  m_dataMapper.addMapping(m_ui->m_downloadButton, MessagesModel::COLUMN_HAS_ATTACHMENT, "enabled");
  m_dataMapper.setCurrentModelIndex(modelIndex);

  m_ui->m_prevButton->setEnabled(m_dataMapper.currentIndex() > 0);
  m_ui->m_nextButton->setEnabled(m_dataMapper.currentIndex() < MessagesModel::instance().rowCount() - 1);

  connect(&m_networAccesskManager, &QNetworkAccessManager::finished, this, &MessageDetailsDialog::attachmentDownloaded);
}

MessageDetailsDialog::~MessageDetailsDialog() {
}

QModelIndex MessageDetailsDialog::getCurrentMessageIndex() const {
  return MessagesModel::instance().index(m_dataMapper.currentIndex(), 0);
}

void MessageDetailsDialog::prevClicked() {
  m_dataMapper.toPrevious();
  m_ui->m_prevButton->setEnabled(m_dataMapper.currentIndex() > 0);
  m_ui->m_nextButton->setEnabled(m_dataMapper.currentIndex() < MessagesModel::instance().rowCount() - 1);
}

void MessageDetailsDialog::nextClicked() {
  m_dataMapper.toNext();
  m_ui->m_prevButton->setEnabled(m_dataMapper.currentIndex() > 0);
  m_ui->m_nextButton->setEnabled(m_dataMapper.currentIndex() < MessagesModel::instance().rowCount() - 1);
}

void MessageDetailsDialog::saveClicked() {
  QString filePath = QFileDialog::getSaveFileName(this, tr("Save message"), QDir::homePath());
  if (!filePath.isEmpty()) {
    QFile file(filePath);
    if (file.exists()) {
      if (QMessageBox::warning(&MainWindow::instance(), tr("File already exists"),
        tr("Warning! File already exists and will be overwritten, are you sure?"), QMessageBox::Cancel, QMessageBox::Ok) != QMessageBox::Ok) {
        return;
      }
    }

    if (!file.open(QFile::WriteOnly | QFile::Truncate)) {
      QMessageBox::critical(&MainWindow::instance(), tr("File error"), file.errorString());
      return;
    }

    QString message = m_ui->m_messageTextEdit->toPlainText();
    file.write(message.toUtf8());
    file.close();
  }
}

void MessageDetailsDialog::downloadClicked() {
  attachmentDirectory = QFileDialog::getExistingDirectory(this, tr("Download attachments"), attachmentDirectory,
                                                          QFileDialog::ShowDirsOnly | QFileDialog::DontResolveSymlinks);
  if(attachmentDirectory.isEmpty()) {
    return;
  }

  QString attachmentHeader = getCurrentMessageIndex().data(MessagesModel::ROLE_HEADER_ATTACHMENT).toString();
  QNetworkReply* reply = m_networAccesskManager.get(QNetworkRequest(QUrl(IPFS_API_URL + attachmentHeader)));
  reply->setReadBufferSize(DOWNLOAD_BUFFER_SIZE);
  showUploadProgress(reply);
}

void MessageDetailsDialog::showUploadProgress(QNetworkReply* reply) {
  NetworkProgressDialog* progressDialog = new NetworkProgressDialog(this, tr("Downloading attachment"));
  connect(reply, &QNetworkReply::downloadProgress, progressDialog, &NetworkProgressDialog::networkProgress);
  connect(progressDialog, &QProgressDialog::canceled, reply, &QNetworkReply::abort);
  connect(reply, &QNetworkReply::finished, progressDialog, &NetworkProgressDialog::close);
  progressDialog->show();
}

void MessageDetailsDialog::attachmentDownloaded(QNetworkReply* reply) {
  reply->deleteLater();

  if(reply->error() == QNetworkReply::OperationCanceledError) {
    return;
  }

  if(reply->error()) {
    QCoreApplication::postEvent(&MainWindow::instance(),
                                new ShowMessageEvent(tr("Can't download attachment: ") + reply->errorString(),
                                                     QtCriticalMsg));
    return;
  }

  QByteArray encryptionKey = QByteArray::fromHex(getCurrentMessageIndex().data(MessagesModel::ROLE_HEADER_ATTACHMENT_ENCRYPTION_KEY)
                                                                         .toString().toUtf8());
  QByteArray payload = reply->readAll();
  WalletAdapter::instance().decryptAttachment(payload, encryptionKey);

  extractAttachment(payload);
}

void MessageDetailsDialog::extractAttachment(const QByteArray& data) {
  QTemporaryFile tempFile;
  if(!tempFile.open()) {
      QCoreApplication::postEvent(&MainWindow::instance(),
                                  new ShowMessageEvent(tr("Can't create temporary file for attachment"),
                                                       QtCriticalMsg));
      return;
  }

  tempFile.write(data);
  tempFile.close();
  tempFile.open();

  QZipReader zipReader(&tempFile);
  if(zipReader.status() != QZipReader::NoError) {
      QCoreApplication::postEvent(&MainWindow::instance(),
                                  new ShowMessageEvent(tr("Can't open attachment zip archive"), QtCriticalMsg));
      return;
  }

  QString dir = attachmentDirectory + "/" + getCurrentMessageIndex().data(MessagesModel::ROLE_HASH).toByteArray().toHex().toUpper();
  if(!QDir(dir).exists()) {
      if(!QDir().mkdir(dir)) {
          QCoreApplication::postEvent(&MainWindow::instance(),
                                      new ShowMessageEvent(tr("Can't create attachment directory"),
                                                           QtCriticalMsg));
          return;
      }
  }

  if(!zipReader.extractAll(dir)) {
    QCoreApplication::postEvent(&MainWindow::instance(), new ShowMessageEvent(tr("Can't unpack attachment"),
                                QtCriticalMsg));
  }
  zipReader.close();
}

}
