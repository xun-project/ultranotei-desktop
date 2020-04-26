#ifndef BROWSERUTILS_H
#define BROWSERUTILS_H

#include <QtCore/QFileInfo>
#include <QtCore/QUrl>
#include <QString>
#include <QFile>
#include <QDir>
#include <QTextStream>
#include <QMessageBox>

class BrowserUtils : public QObject {
    Q_OBJECT
public:
    Q_INVOKABLE static QString getBookmarks();
    Q_INVOKABLE static void addBookmark(const QUrl& currentUrl, const QString& pageTitle);
    Q_INVOKABLE static QUrl goToUrl(const QString& searchString);
};

inline QString BrowserUtils::getBookmarks()
{
#ifdef Q_OS_WIN
    QFile bkfile(QDir::homePath() + "/bookmarks.html");
#endif

#ifdef Q_OS_LINUX
    //QFile bkfile(QDir::homePath() + "/.UltraNoteWallet/bookmarks.html");
    QString path(QDir::homePath() +"/.UltraNoteWallet/");
    QDir dir;
    if (!dir.exists(path))
       dir.mkpath(path);
    QFile bkfile(path + "bookmarks.html");
#endif

#ifdef Q_OS_MACOS
    QFile bkfile(QDir::homePath() + "/.UltraNoteWallet/bookmarks.html");
#endif

    if (!bkfile.isOpen()) {
        auto open = bkfile.open(QFile::ReadWrite);
        if(!open){QMessageBox::warning(nullptr, QObject::tr("Fail"), QString("Failed to open Bookmarks file: %1").arg(bkfile.errorString()));}
    }
    QTextStream in(&bkfile);
    QString html;
    while (!in.atEnd()) {
        html += in.readLine();
    }
    return html;
}

inline void BrowserUtils::addBookmark(const QUrl& currentUrl, const QString& pageTitle)
{
#ifdef Q_OS_WIN
    QFile bookmarks(QDir::homePath() + "/bookmarks.html");
#endif

#ifdef Q_OS_LINUX
    //QFile bookmarks(QDir::homePath() + "/.UltraNoteWallet/bookmarks.html");
    QString path(QDir::homePath() +"/.UltraNoteWallet/");
    QDir dir;
    if (!dir.exists(path))
       dir.mkpath(path);
    QFile bookmarks(path + "bookmarks.html");
#endif

#ifdef Q_OS_MACOS
    QFile bookmarks(QDir::homePath() + "/.UltraNoteWallet/bookmarks.html");
#endif

    if (!bookmarks.isOpen()) {
        bookmarks.open(QFile::Append);
    }
    QString url = currentUrl.toString();
    QByteArray url_raw;
    url_raw.append("<a href=\"");
    url_raw.append(url);
    url_raw.append("\">");

    bookmarks.write(url_raw);

    QString name = pageTitle;
    QByteArray name_raw;
    name_raw.append(name);
    name_raw.append("</a>");
    bookmarks.write(name_raw);
    bookmarks.write("<br>\n");
    bookmarks.flush();
    bookmarks.close();
}

inline QUrl BrowserUtils::goToUrl(const QString& searchString)
{
    QString address = searchString;

    if (address.contains('.') && !address.contains(' ')) {
        if (!address.startsWith("http")) {
            address.prepend("http://");
        }

        return QUrl(address);
    } else {
        QString searchQuery = "https://duckduckgo.com/?q=";
        searchQuery.append(address.replace(' ', '+'));
        return QUrl(searchQuery);
    }
}
#endif // BROWSERUTILS_H