// Copyright (c) 2011-2017 The Cryptonote developers
// Copyright (c) 2014-2017 XDN developers
// Copyright (c) 2016-2017 BXC developers
// Copyright (c) 2017 UltraNote developers
// Distributed under the MIT/X11 software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#pragma once

#include <QNetworkAccessManager>
#include <QObject>

namespace WalletGui {

class AliasProvider : public QObject {
    Q_OBJECT

public:
    AliasProvider(QObject* parent);

    void getAddresses(const QString& _urlString);
    bool isActive();

private:
    QNetworkAccessManager m_networkManager;
    void readyRead();
    bool m_isActive = false;

Q_SIGNALS:
    void aliasFoundSignal(const QString& _name, const QString& _address);
};

}
