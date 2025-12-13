// Copyright (c) 2011-2017 The Cryptonote developers
// Copyright (c) 2014-2017 XDN developers
// Copyright (c) 2016-2017 BXC developers
// Copyright (c) 2017 UltraNote developers
// Distributed under the MIT/X11 software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#pragma once

#include <QNetworkAccessManager>
#include <QObject>
#include <QThread>
#include <string>
#include <vector>

namespace WalletGui {

class DnsWorker : public QObject {
    Q_OBJECT

public:
    DnsWorker(QObject* parent = nullptr);
    ~DnsWorker();

    bool parseOpenAliasRecord(const QString& record, QString& address, QString& name);

public slots:
    void resolveDns(const QString& domain);

signals:
    void dnsResolved(const QString& name, const QString& address);
    void dnsError(const QString& error);
};

class AliasProvider : public QObject {
    Q_OBJECT

public:
    AliasProvider(QObject* parent);
    ~AliasProvider();

    void getAddresses(const QString& _urlString);
    bool isActive();

private:
    QNetworkAccessManager m_networkManager;
    QThread m_dnsThread;
    DnsWorker* m_dnsWorker;
    void readyRead();
    bool m_isActive = false;

    bool isLikelyDomain(const QString& input);
    bool isValidUltraNoteAddress(const QString& address);
    bool parseOpenAliasRecord(const QString& record, QString& address, QString& name);

Q_SIGNALS:
    void aliasFoundSignal(const QString& _name, const QString& _address);
    void resolveDnsSignal(const QString& domain);

private slots:
    void onDnsResolved(const QString& name, const QString& address);
    void onDnsError(const QString& error);
};

}
