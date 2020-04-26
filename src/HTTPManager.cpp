#include <QByteArray>
#include <QMessageBox>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QObject>

#include <iostream>

#include "HTTPManager.h"

HTTPManager::HTTPManager()
{
    m_manager = new QNetworkAccessManager(this);
    repl = new (QByteArray);
}

HTTPManager::~HTTPManager()
{
    delete m_manager;
    delete repl;
}

void HTTPManager::sendRequest(QString q)
{
    QString url = q;
    m_url = q;
    m_reply_tmp = m_manager->get(QNetworkRequest(QUrl(q)));
    connect(m_reply_tmp, &QNetworkReply::finished, this, &HTTPManager::slotRead);
    connect(m_reply_tmp, &QNetworkReply::sslErrors, this, &HTTPManager::ignoreSslErrors);
}

void HTTPManager::slotRead()
{
    *repl = m_reply_tmp->readAll();
    emit HTTPManager::replyIsReady();
    m_reply_tmp->deleteLater();
}

QByteArray HTTPManager::getReplyText()
{
    return *repl;
}

void HTTPManager::ignoreSslErrors()
{
    QMessageBox mb;
    mb.setText("SSL Error occured");
    mb.exec();
}
