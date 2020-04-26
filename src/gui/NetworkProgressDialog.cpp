// Copyright (c) 2011-2016 The Cryptonote developers
// Copyright (c) 2015-2016 XDN developers
// Copyright (c) 2017 UltraNote developers
// Distributed under the MIT/X11 software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#include "NetworkProgressDialog.h"

namespace WalletGui {

NetworkProgressDialog::NetworkProgressDialog(QWidget* _parent, const QString& title) : QProgressDialog(_parent) {
    setWindowTitle(title);
    setMinimum(0);
    setValue(0);
    setMinimumDuration(0);
    setFixedSize(QSize(400, 100));
    setAttribute(Qt::WA_DeleteOnClose);
    // Modal progress dialog causes QNetworkAccessManager to stack
    setModal(false);
}

NetworkProgressDialog::~NetworkProgressDialog() {

}

void NetworkProgressDialog::networkProgress(qint64 processedBytes, qint64 totalBytes) {
    setMaximum(totalBytes);
    setValue(processedBytes);
}

}
