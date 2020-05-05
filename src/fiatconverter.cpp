#include "fiatconverter.h"
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QUrlQuery>
#include "Settings.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QDebug>

#define SERVER_URL "https://api.coingecko.com/api/v3/"
#define COIN_NAME "xuni"
#define PRICE_CHECK_PERIOD_SEC 300

namespace WalletGui {

FiatConverter::FiatConverter(QObject *parent) : QObject(parent),
    m_http(new QNetworkAccessManager())
{
    setFiatId(Settings::instance().getFiatSymbol());

    connect(m_http, &QNetworkAccessManager::sslErrors,
            this, [&](QNetworkReply *reply, const QList<QSslError> &errors) {
        qDebug() << "SSL errors, ignoring";
        reply->ignoreSslErrors(errors);
    });
    connect(m_http, &QNetworkAccessManager::finished, this,
            &FiatConverter::requestFinished);
    m_priceCheckTimer.setInterval(PRICE_CHECK_PERIOD_SEC * 1000);
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
        out += "coins/list";
        break;
    case RequestType::SupportedCurrencies:
        out += "simple/supported_vs_currencies";
        break;
    case RequestType::CoinPrice:
        out += "simple/price";
        break;
    default:
        out.clear();
    }
    return out;
}

QNetworkReply* FiatConverter::networkReply(RequestType type, QUrl url)
{
    if (RequestType::CoinPrice == type) {
        if (m_coinId.isEmpty() || m_fiatList.isEmpty()) {
            qCritical() << "Coin ID or fiat list is empty";
            return nullptr;
        }
        QUrlQuery query;
        query.addQueryItem("ids", m_coinId);
        query.addQueryItem("vs_currencies", m_fiatList);
        url.setQuery(query.query());
    }
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
        if (!m_coinId.isEmpty() && !m_fiatList.isEmpty()) {
            qDebug() << "Restart price check timer";
            m_priceCheckTimer.start();
        }
    }
}

void FiatConverter::processReply(RequestType type, const QByteArray &data)
{
    QJsonParseError error{};
    QJsonDocument doc = QJsonDocument::fromJson(data, &error);
    switch (type) {
    case RequestType::CoinList:
        qDebug() << "Processing coin list";
        if (doc.isArray()) {
            const QJsonArray arr = doc.array();
            for (const auto &val: arr) {
                const auto obj = val.toObject();
                const auto symbol = obj["symbol"].toString();
                if (0 == symbol.compare(COIN_NAME, Qt::CaseInsensitive)) {
                    m_coinId = obj["id"].toString();
                    sendRequest(RequestType::SupportedCurrencies);
                    break;
                }
            }
        } else {
            qCritical() << "Reply is not a JSON array" << error.errorString();
            qDebug() << data;
        }
        break;
    case RequestType::SupportedCurrencies:
        qDebug() << "Processing supported currencies";
        {
            m_fiatList = QString(data);
            m_fiatList.remove("[");
            m_fiatList.remove("]");
            m_fiatList.remove("\"");
            const auto tok = m_fiatList.split(",");
            m_availableFiatList.clear();
            for (int i = 0; i < tok.size(); ++i) {
                m_availableFiatList << tok.at(i);
                if (0 == m_fiatId.compare(tok.at(i), Qt::CaseInsensitive)) {
                    setCurrentIndex(i);
                }
            }
            emit availableFiatListChanged();
            sendRequest(RequestType::CoinPrice);
        }
        break;
    case RequestType::CoinPrice:
        if (doc.isObject()) {
            m_coinPriceDict = doc.object()[m_coinId].toObject();
            if (!m_coinPriceDict.isEmpty()) {
                setCoinPrice();
                m_priceCheckTimer.start();
            } else {
                qCritical() << "Cannot find" << m_coinId;
            }
        } else {
            qCritical() << "Reply is not a JSON object" << error.errorString();
            qDebug() << data;
        }
        break;
     case RequestType::Unknown:
        break;//remove compiler warning
    }
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
    const qreal curPrice = m_coinPriceDict[m_fiatId].toDouble();
    qDebug() << "Current price" << curPrice << m_fiatId;
    setCoinPrice(curPrice);
}

} //WalletGui
