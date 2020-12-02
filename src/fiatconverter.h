#pragma once

#include "qmlhelpers.h"
#include <QObject>
#include <QMap>
#include <QJsonObject>
#include <QTimer>
#include <QMutex>

class QNetworkAccessManager;
class QNetworkReply;

namespace WalletGui {

class FiatConverter : public QObject
{
    Q_OBJECT
    QML_READABLE_PROPERTY_FLOAT(double, coinPrice, setCoinPrice, 0)
    QML_WRITABLE_PROPERTY(QString, fiatId, setFiatId, "")
    QML_READABLE_PROPERTY(QStringList, availableFiatList, setAvailableFiatList, QStringList())
    QML_WRITABLE_PROPERTY(int, currentIndex, setCurrentIndex, -1)
public:
    enum class RequestType {
        Unknown, CoinList, SupportedCurrencies, CoinPrice
    };
    explicit FiatConverter(QObject *parent = nullptr);
    ~FiatConverter();
    Q_INVOKABLE void setFiatId(int index);
private:
    bool sendRequest(RequestType type);
    QString fullUrl(RequestType type) const;
    QNetworkReply* networkReply(RequestType type, QUrl url);
    void requestFinished(QNetworkReply* reply);
    void processReply(RequestType type, const QByteArray &data);
    void setCoinPrice();
    QNetworkAccessManager* m_http = nullptr;
    QJsonObject m_coinPriceDict;
    QString m_fiatList;
    QMap<QNetworkReply*, RequestType> m_loadingMap;
    QMutex m_loadingMapMutex;
    QTimer m_priceCheckTimer;
};

} //WalletGui
