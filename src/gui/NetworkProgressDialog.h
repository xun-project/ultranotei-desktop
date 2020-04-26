// Copyright (c) 2011-2016 The Cryptonote developers
// Copyright (c) 2015-2016 XDN developers
// Copyright (c) 2017 UltraNote developers
// Distributed under the MIT/X11 software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#pragma once

#include <QProgressDialog>

namespace WalletGui {

class NetworkProgressDialog : public QProgressDialog {
  Q_OBJECT
  Q_DISABLE_COPY(NetworkProgressDialog)

public:
  explicit NetworkProgressDialog(QWidget* _parent, const QString& title);
  ~NetworkProgressDialog();

  Q_SLOT void networkProgress(qint64 processedBytes, qint64 totalBytes);
};

}
