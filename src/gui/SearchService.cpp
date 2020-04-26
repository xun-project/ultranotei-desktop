#include <QDesktopServices>
#include <QLabel>
#include <QLayout>
#include <QLineEdit>
#include <QMessageBox>
#include <QObject>
#include <QString>
#include <QTextBrowser>
#include <QTextCodec>
#include <QTextCursor>
#include <QVector>
#include <QWidget>
#include <iostream>

#include "HTTPManager.h"
#include "JsonHandler.h"
#include "MainWindow.h"
#include "SearchService.h"

namespace WalletGui {

SearchService::SearchService(QObject* parent)
    : QObject(parent)
{
    SearchServiceProgressStateClass::registerQmlEnum("UltraNote.SearchService", 1, 0, "SearchServiceProgressState");
    SearchServiceSearchTypeClass::registerQmlEnum("UltraNote.SearchService", 1, 0, "SearchServiceSearchType");

    http_mr = new HTTPManager();

    connect(http_mr, &HTTPManager::replyIsReady, this, &SearchService::httpReplyViewer);
}

SearchService::~SearchService()
{
    delete http_mr;
}

void SearchService::httpReplyViewer()
{
    QByteArray ba = http_mr->getReplyText();

    JsonHandler jh;
    jh.setJsonRawData(ba);

    setResultsModel(jh.getHtml().toList());

    if (m_resultsModel.size() == 0) {
        setProgress(SearchServiceProgressState::ERROR);
    } else {
        setProgress(SearchServiceProgressState::SUCCESS);
    }
}

void SearchService::startSearch()
{
    setProgress(SearchServiceProgressState::PENDING);
    qDebug() << "Start search: " << m_searchText;

    QString* query = new (QString);
    *query = "https://search.ultranote.org/search?";
    QString* opt = new (QString);
    *opt = "q=";
    QString squery = m_searchText;
    opt->append(squery);
    opt->append("&c=main&n=10&format=json");
    if (m_searchType == SearchServiceSearchType::ALL) {

    } else if (m_searchType == SearchServiceSearchType::IMAGES) {
        opt->append("&searchtype=images");
    } else if (m_searchType == SearchServiceSearchType::NEWS) {
        opt->append("&searchtype=news");
    }
    query->append(opt);

    setResultsModel(QStringList());

    setProgress(SearchServiceProgressState::IN_PROGRESS);
    http_mr->sendRequest(*query);
}

}
