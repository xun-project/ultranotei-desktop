#include "fiatconverter.h"
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QUrlQuery>
#include "Settings.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QDebug>

#define SERVER_URL "https://api.exbitron.com/api/v1/cg/tickers"
#define COIN_NAME "xuni"
#define PRICE_CHECK_PERIOD_SEC 300
#define DEFAULT_FIAT_SYMBOL "USD"

namespace WalletGui {

FiatConverter::FiatConverter(QObject *parent) : QObject(parent),
    m_http(new QNetworkAccessManager())
{
    QString fiatSymbol = Settings::instance().getFiatSymbol();
    if (fiatSymbol == "")
    {
        fiatSymbol = DEFAULT_FIAT_SYMBOL;
        Settings::instance().setFiatSymbol(fiatSymbol);
        qInfo() << QString("FiatConverter: set the fiat symbol to default (%1)").arg(fiatSymbol);
    }
    setFiatId(fiatSymbol);

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

    sendRequest(RequestType::CoinList);
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
    QString out(SERVER_URL);
    switch (type) {
    case RequestType::CoinList:
    case RequestType::SupportedCurrencies:
    case RequestType::CoinPrice:
        break;
    default:
        out.clear();
    }
    return out;
}

QNetworkReply* FiatConverter::networkReply(RequestType type, QUrl url)
{
    // For Exbitron, we just need to hit the tickers endpoint for everything
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
        if (!m_availableFiatList.isEmpty()) {
            qDebug() << "Restart price check timer";
            m_priceCheckTimer.start();
        }
    }
}

void FiatConverter::processReply(RequestType type, const QByteArray &data)
{
    QJsonParseError error{};
    QJsonDocument doc = QJsonDocument::fromJson(data, &error);

    if (!doc.isArray()) {
        qCritical() << "Reply is not a JSON array" << error.errorString();
        qDebug() << data;
        return;
    }

    QJsonArray tickers = doc.array();
    double xuniUsdtPrice = 0.0;
    double btcUsdtPrice = 0.0;
    double ethUsdtPrice = 0.0;
    double ltcUsdtPrice = 0.0;
    double dogeUsdtPrice = 0.0;

    // First pass: find base prices
    for (const QJsonValue &val : tickers) {
        QJsonObject ticker = val.toObject();
        QString tickerId = ticker["ticker_id"].toString();
        double lastPrice = ticker["last_price"].toString().toDouble();

        if (tickerId == "XUNI-USDT") {
            xuniUsdtPrice = lastPrice;
        } else if (tickerId == "BTC-USDT") {
            btcUsdtPrice = lastPrice;
        } else if (tickerId == "ETH-USDT") {
            ethUsdtPrice = lastPrice;
        } else if (tickerId == "LTC-USDT") {
            ltcUsdtPrice = lastPrice;
        } else if (tickerId == "DOGE-USDT") {
            dogeUsdtPrice = lastPrice;
        }
    }

    if (xuniUsdtPrice <= 0) {
        qCritical() << "Could not find XUNI-USDT price";
        return;
    }

    QJsonObject newPrices;
    newPrices["USD"] = xuniUsdtPrice;
    
    if (btcUsdtPrice > 0) newPrices["BTC"] = xuniUsdtPrice / btcUsdtPrice;
    if (ethUsdtPrice > 0) newPrices["ETH"] = xuniUsdtPrice / ethUsdtPrice;
    if (ltcUsdtPrice > 0) newPrices["LTC"] = xuniUsdtPrice / ltcUsdtPrice;
    if (dogeUsdtPrice > 0) newPrices["DOGE"] = xuniUsdtPrice / dogeUsdtPrice;

    m_coinPriceDict = newPrices;

    // Update available list if needed (only once or if changed)
    if (m_availableFiatList.isEmpty()) {
        m_availableFiatList.clear();
        m_availableFiatList << "USD" << "BTC" << "ETH" << "LTC" << "DOGE";
        
        // Ensure current index is set correctly
        for (int i = 0; i < m_availableFiatList.size(); ++i) {
            if (0 == m_fiatId.compare(m_availableFiatList.at(i), Qt::CaseInsensitive)) {
                setCurrentIndex(i);
            }
        }
        emit availableFiatListChanged();
    }

    // Update current price
    setCoinPrice();
    m_priceCheckTimer.start();
}

void FiatConverter::setFiatId(int index)
{
    if ((0 <= index) && (index < m_availableFiatList.size())) {
        setFiatId(m_availableFiatList.at(index));
        Settings::instance().setFiatSymbol(m_fiatId);
        setCoinPrice();
    }
}

void FiatConverter::setCoinPrice()
{
    // Case insensitive lookup
    QString key = m_fiatId.toUpper();
    if (m_coinPriceDict.contains(key)) {
        const qreal curPrice = m_coinPriceDict[key].toDouble();
        qDebug() << "Current price" << curPrice << m_fiatId;
        setCoinPrice(curPrice);
    } else {
         qDebug() << "Price not found for" << m_fiatId;
    }
}

} //WalletGui
