#include "fiatconverter.h"
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QUrlQuery>
#include "Settings.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QDebug>

#define SERVER_URL "https://localcryptos.club/api/coin/xuni"
#define COIN_NAME "XUNI"
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
    if (RequestType::CoinPrice == type && m_availableFiatList.isEmpty()) {
        qCritical() << "Fiat list is empty";
        return nullptr;
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
    switch (type) {
    case RequestType::CoinList:
    case RequestType::SupportedCurrencies:
        if (doc.isObject()) {

            foreach(const QJsonValue & v, doc.object()["data"].toArray())
            {
                qDebug() << "Processing coin list";

                m_coinPriceDict = v.toObject().value(COIN_NAME).toObject()["price"].toObject();

                m_availableFiatList.clear();
                QList<QString> keyList = m_coinPriceDict.keys();

                for (int i = 0; i < keyList.size(); ++i) {
                    m_availableFiatList << keyList.at(i);
                    if (0 == m_fiatId.compare(keyList.at(i), Qt::CaseInsensitive)) {
                        setCurrentIndex(i);
                    }
                }
                emit availableFiatListChanged();
            }

            sendRequest(RequestType::CoinPrice);
        } else {
            qCritical() << "Reply is not a JSON array" << error.errorString();
            qDebug() << data;
        }
        break;
    case RequestType::CoinPrice:
        qDebug() << "Process coin price ";

        if (doc.isObject()) {
            
            foreach(const QJsonValue & v, doc.object()["data"].toArray())
                m_coinPriceDict = v.toObject().value("XUNI").toObject()["price"].toObject();

            if (!m_coinPriceDict.isEmpty()) {
                setCoinPrice();
                m_priceCheckTimer.start();
            } else {
                qCritical() << "Cannot find" << m_fiatId;
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
