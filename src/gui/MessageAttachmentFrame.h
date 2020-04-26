// Copyright (c) 2011-2016 The Cryptonote developers
// Copyright (c) 2015-2016 XDN developers
// Copyright (c) 2017 UltraNote developers
// Distributed under the MIT/X11 software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#pragma once

#include <QFrame>

namespace Ui {
  class MessageAttachmentFrame;
}

namespace WalletGui {

class MessageAttachmentFrame : public QFrame {
  Q_OBJECT
  Q_DISABLE_COPY(MessageAttachmentFrame)

public:
  MessageAttachmentFrame(QWidget* _parent, const QString& filename);
  ~MessageAttachmentFrame();

  QString getFileName() const;

private:
  QScopedPointer<Ui::MessageAttachmentFrame> m_ui;
};

}
