// Copyright (c) 2011-2016 The Cryptonote developers
// Copyright (c) 2015-2016 XDN developers
// Copyright (c) 2017 UltraNote developers
// Distributed under the MIT/X11 software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#include "MessageAttachmentFrame.h"
#include "ui_messageattachmentframe.h"

namespace WalletGui {

MessageAttachmentFrame::MessageAttachmentFrame(QWidget* _parent, const QString& filename) : QFrame(_parent),
      m_ui(new Ui::MessageAttachmentFrame) {
  m_ui->setupUi(this);
  m_ui->m_filename->setText(filename);
}

MessageAttachmentFrame::~MessageAttachmentFrame() {

}

QString MessageAttachmentFrame::getFileName() const {
  return m_ui->m_filename->text();
}

}
