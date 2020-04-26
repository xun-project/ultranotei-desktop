#pragma once

#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QString>

class HTTPManager : public QObject {
    Q_OBJECT
public:
    HTTPManager();
    ~HTTPManager();
    void sendRequest(QString q);
    QByteArray getReplyText();

signals:
    void replyIsReady();

public slots:
    //void slotRead(QNetworkReply* r);
    void slotRead();
    void ignoreSslErrors();

private:
    QNetworkAccessManager* m_manager;
    QNetworkReply* m_reply_tmp;
    QNetworkRequest* m_request;
    QUrl m_url;
    QByteArray m_options;
    QByteArray* repl;
};
