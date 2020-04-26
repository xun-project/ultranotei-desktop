#pragma once
#include "HTTPManager.h"
#include "qmlhelpers.h"
#include <IWalletLegacy.h>
#include <QFrame>

namespace WalletGui {

QML_REGISTER_ENUM(SearchServiceProgressState, PENDING = 0, IN_PROGRESS, SUCCESS, ERROR)
QML_REGISTER_ENUM(SearchServiceSearchType, ALL = 0, IMAGES, NEWS)

class SearchService : public QObject {
    Q_OBJECT
    QML_WRITABLE_PROPERTY(QString, searchText, setSearchText, "")
    QML_WRITABLE_PROPERTY(QStringList, resultsModel, setResultsModel, QStringList {})
    QML_WRITABLE_PROPERTY(SearchServiceSearchType, searchType, setSearchType, SearchServiceSearchType::ALL)
    QML_WRITABLE_PROPERTY(SearchServiceProgressState, progress, setProgress, SearchServiceProgressState::PENDING)
public:
    SearchService(QObject* _parent);
    ~SearchService();

    //QML API
    Q_INVOKABLE void startSearch();

private slots:
    void httpReplyViewer();

private:
    HTTPManager* http_mr;
};

}
