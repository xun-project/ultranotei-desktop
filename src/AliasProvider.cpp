// Copyright (c) 2011-2017 The Cryptonote developers
// Copyright (c) 2014-2017 XDN developers
// Copyright (c) 2016-2017 BXC developers
// Copyright (c) 2017 UltraNote developers
// Distributed under the MIT/X11 software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkReply>
#include <QStringList>
#include <QUrl>
#include <QRegularExpression>
#include <QDebug>

#include "AliasProvider.h"
#include "CurrencyAdapter.h"
#include "Common/DnsTools.h"

namespace WalletGui {

Q_DECL_CONSTEXPR char ALIAS_OBJECT_NAME[] = "cediname1";
Q_DECL_CONSTEXPR char ALIAS_NAME_TAG[] = "name";
Q_DECL_CONSTEXPR char ALIAS_ADDRESS_TAG[] = "BXC";

DnsWorker::DnsWorker(QObject* parent) : QObject(parent) {
}

DnsWorker::~DnsWorker() {
}

void DnsWorker::resolveDns(const QString& domain) {
    std::string domainStr = domain.toStdString();
    std::vector<std::string> records;
    
    bool success = common::fetch_dns_txt(domainStr, records);
    
    if (success && !records.empty()) {
        // Try to parse OpenAlias record
        for (const auto& record : records) {
            QString qrecord = QString::fromStdString(record);
            QString address, name;
            
            // Check if it's an OpenAlias record
            if (parseOpenAliasRecord(qrecord, address, name)) {
                // Validate the address using CurrencyAdapter
                if (CurrencyAdapter::instance().validateAddress(address)) {
                    if (name.isEmpty()) {
                        name = domain;
                    }
                    emit dnsResolved(name, address);
                    return;
                }
            }
        }
    }
    
    emit dnsError(tr("No valid OpenAlias record found"));
}

AliasProvider::AliasProvider(QObject* parent)
    : QObject(parent), m_dnsWorker(new DnsWorker()) {
    m_dnsThread.start();
    m_dnsWorker->moveToThread(&m_dnsThread);
    
    connect(this, &AliasProvider::resolveDnsSignal, m_dnsWorker, &DnsWorker::resolveDns);
    connect(m_dnsWorker, &DnsWorker::dnsResolved, this, &AliasProvider::onDnsResolved);
    connect(m_dnsWorker, &DnsWorker::dnsError, this, &AliasProvider::onDnsError);
}

AliasProvider::~AliasProvider() {
    m_dnsThread.quit();
    m_dnsThread.wait();
    delete m_dnsWorker;
}

void AliasProvider::getAddresses(const QString& _urlString) {
    
    // First check if it's a valid UltraNote address
    if (isValidUltraNoteAddress(_urlString)) {
        // It's already an address, not an alias
        return;
    }
    
    // Check if it looks like a domain (not an IP address and contains dots)
    if (isLikelyDomain(_urlString)) {
        // Try DNS resolution first (OpenAlias)
        m_isActive = true;
        emit resolveDnsSignal(_urlString);
        return;
    }
    
    // Otherwise, try HTTP (CEDINAME)
    QUrl url = QUrl::fromUserInput(_urlString);
    if (!url.isValid()) {
        return;
    }

    QNetworkRequest request(url);
    QNetworkReply* reply = m_networkManager.get(request);
    m_isActive = true;
    connect(reply, &QNetworkReply::readyRead, this, &AliasProvider::readyRead);
    connect(reply, &QNetworkReply::finished, reply, &QNetworkReply::deleteLater);
}

bool AliasProvider::isActive() { return m_isActive; }

bool AliasProvider::isLikelyDomain(const QString& input) {
    // Simple check: contains a dot and doesn't look like an IP address
    // and doesn't start with http:// or https://
    if (input.startsWith("http://") || input.startsWith("https://")) {
        return false;
    }
    
    // Check if it contains a dot and doesn't look like an IP address
    if (input.contains('.') && !input.contains(':')) {
        // Check if it's a valid UltraNote address (would have been caught earlier)
        // Additional check: doesn't look like a typical URL with path
        if (!input.contains('/') && !input.contains('?')) {
            return true;
        }
    }
    
    return false;
}

bool AliasProvider::isValidUltraNoteAddress(const QString& address) {
    // Use CurrencyAdapter to validate the address
    return CurrencyAdapter::instance().validateAddress(address);
}

bool AliasProvider::parseOpenAliasRecord(const QString& record, QString& address, QString& name) {
    // Parse OpenAlias format: oa1:xuni recipient_address=<address>; recipient_name=<name>;
    if (!record.contains("oa1:xuni")) {
        return false;
    }
    
    QRegularExpression addrRegex("recipient_address=([^;]+)");
    QRegularExpressionMatch addrMatch = addrRegex.match(record);
    if (!addrMatch.hasMatch()) {
        return false;
    }
    
    address = addrMatch.captured(1).trimmed();
    // Don't validate address length here - let CurrencyAdapter validate it
    // UltraNote addresses can be 99 chars (regular) or 187 chars (integrated)
    
    QRegularExpression nameRegex("recipient_name=([^;]+)");
    QRegularExpressionMatch nameMatch = nameRegex.match(record);
    if (nameMatch.hasMatch()) {
        name = nameMatch.captured(1).trimmed();
    }
    
    return true;
}

bool DnsWorker::parseOpenAliasRecord(const QString& record, QString& address, QString& name) {
    // Parse OpenAlias format: oa1:xuni recipient_address=<address>; recipient_name=<name>;
    if (!record.contains("oa1:xuni")) {
        return false;
    }
    
    QRegularExpression addrRegex("recipient_address=([^;]+)");
    QRegularExpressionMatch addrMatch = addrRegex.match(record);
    if (!addrMatch.hasMatch()) {
        return false;
    }
    
    address = addrMatch.captured(1).trimmed();
    // Don't validate address length here - let CurrencyAdapter validate it
    // UltraNote addresses can be 99 chars (regular) or 187 chars (integrated)
    
    QRegularExpression nameRegex("recipient_name=([^;]+)");
    QRegularExpressionMatch nameMatch = nameRegex.match(record);
    if (nameMatch.hasMatch()) {
        name = nameMatch.captured(1).trimmed();
    }
    
    return true;
}

void AliasProvider::onDnsResolved(const QString& name, const QString& address) {
    m_isActive = false;
    if (!address.isEmpty()) {
        Q_EMIT aliasFoundSignal(name, address);
    }
}

void AliasProvider::onDnsError(const QString& error) {
    m_isActive = false;
    // DNS failed, could try HTTP here if we want to fallback
    // But for now, just fail silently
}

void AliasProvider::readyRead()
{
    auto reply = qobject_cast<QNetworkReply*>(sender());
    QByteArray data = reply->readAll();
    QJsonDocument doc = QJsonDocument::fromJson(data);
    m_isActive = false;
    if (doc.isNull()) {
        return;
    }

    QJsonArray array = doc.object().value(ALIAS_OBJECT_NAME).toArray();
    if (array.isEmpty()) {
        return;
    }

    QJsonObject obj = array.first().toObject();
    QString name = obj.value(ALIAS_NAME_TAG).toString();
    QString address = obj.value(ALIAS_ADDRESS_TAG).toString();

    if (!address.isEmpty()) {
        Q_EMIT aliasFoundSignal(name, address);
    }
}

}
