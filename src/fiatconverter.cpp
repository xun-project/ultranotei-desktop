#include "fiatconverter.h"
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QUrlQuery>
#include "Settings.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QDebug>

#define XUNI_USDT_URL "https://api.xeggex.com/api/v2/ticker/XUNI_USDT"
#define BTC_USDT_URL "https://api.xeggex.com/api/v2/ticker/BTC_USDT"
#define COIN_NAME "xuni"
#define PRICE_CHECK_PERIOD_SEC 300
#define DEFAULT_FIAT_SYMBOL "usd"

namespace WalletGui {

FiatConverter::FiatConverter(QObject *parent) : QObject(parent),
    m_http(new QNetworkAccessManager())
{
    setFiatId(DEFAULT_FIAT_SYMBOL);

    connect(m_http, &QNetworkAccessManager::sslErrors,
            this, [&](QNetworkReply *reply, const QList<QSslError> &errors) {
        qDebug() << "SSL errors, ignoring";
        reply->ignoreSslErrors(errors);
    });
    connect(m_http, &QNetworkAccessManager::finished, this,
            &FiatConverter::requestFinished);
    m_priceCheckTimer.setInterval(PRICE_CHECK_PERIOD_SEC* 1000);
    m_priceCheckTimer.setSingleShot(true);
    m_priceCheckTimer.stop();
    connect(&m_priceCheckTimer, &QTimer::timeout, [&]() {
        sendRequest(RequestType::CoinPrice);
    });

    sendRequest(RequestType::CoinPrice);
}

FiatConverter::~FiatConverter()
{
    m_priceCheckTimer.stop();
}

bool FiatConverter::sendRequest(RequestType type)
{
    const QString url = fullUrl(type);
    if (url.isEmpty()) {
        qCritical() << "URL cannot be empty";
        return false;
    }
    QNetworkReply *reply = networkReply(type, url);
    bool rc = false;
    if (nullptr != reply) {
        QMutexLocker lock(&m_loadingMapMutex);
        m_loadingMap[reply] = type;
        rc = true;
    } else {
        qCritical() << "Cannot send request";
    }
    return rc;
}

QString FiatConverter::fullUrl(RequestType type) const
{
    QString out;
    switch (type) {
    case RequestType::CoinPrice:
        out = XUNI_USDT_URL;
        break;
    case RequestType::BtcPrice:
        out = BTC_USDT_URL;
        break;
    default:
        out.clear();
    }
    return out;
}

QNetworkReply* FiatConverter::networkReply(RequestType type, QUrl url)
{
    QNetworkRequest request(url);
    QSslConfiguration config = request.sslConfiguration();
    config.setProtocol(QSsl::SecureProtocols);
    request.setSslConfiguration(config);
    return m_http->get(request);
}

void FiatConverter::requestFinished(QNetworkReply* reply)
{
    RequestType requestType = RequestType::Unknown;
    QMutexLocker lock(&m_loadingMapMutex);
    if(m_loadingMap.contains(reply)) {
        requestType = m_loadingMap[reply];
        m_loadingMap.remove(reply);
    } else {
        qCritical() << "Unknown request type";
        return;
    }
    lock.unlock();

    const int rc = reply->error();
    if (QNetworkReply::NoError == rc) {
        processReply(requestType, reply->readAll());
    } else {
        const QString msg = "Error code " + QString::number(rc) + ": " + reply->errorString();
        qCritical() << msg;
        //in case of error, restart price polling if possible
    qDebug() << "Restart price check timer";
    m_priceCheckTimer.start();
    }
}

void FiatConverter::processReply(RequestType type, const QByteArray &data)
{
    QJsonParseError error{};

    QJsonDocument doc = QJsonDocument::fromJson(data, &error);
    switch (type) {
    case RequestType::CoinPrice:
        if (doc.isObject()) {
            QJsonObject obj = doc.object();
            if (!obj.contains("last_price")) {
                qCritical() << "Missing last_price in API response";
                return;
            }
            bool ok = false;
            double lastPrice = obj["last_price"].toString().toDouble(&ok);
            if (!ok) {
                qCritical() << "Invalid last_price format:" << obj["last_price"];
                return;
            }
            m_coinPriceDict = QJsonObject();
            m_coinPriceDict[m_fiatId] = lastPrice;
            qDebug() << "XUNI price updated:" << lastPrice;

            // Get BTC price
            sendRequest(RequestType::BtcPrice);
        } else {
            qCritical() << "Invalid XUNI price response" << error.errorString();
        }
        break;
        
    case RequestType::BtcPrice:
        if (doc.isObject()) {
            QJsonObject obj = doc.object();
            if (!obj.contains("last_price")) {
                qCritical() << "Missing last_price in API response";
                return;
            }
            bool ok = false;
            double btcPrice = obj["last_price"].toString().toDouble(&ok);
            if (!ok) {
                qCritical() << "Invalid last_price format:" << obj["last_price"];
                return;
            }
            m_btcPrice = btcPrice;
            qDebug() << "BTC price updated:" << btcPrice;
            
            // Update price display
            setCoinPrice();
            m_priceCheckTimer.start();
        } else {
            qCritical() << "Invalid BTC price response" << error.errorString();
        }
        break;
        
    default:
        break;
    }
}


void FiatConverter::setCoinPrice()
{
    const qreal curPrice = m_coinPriceDict[m_fiatId].toDouble();
    qDebug() << "Current price" << curPrice << m_fiatId;
    setCoinPrice(curPrice);
}

} //WalletGui
