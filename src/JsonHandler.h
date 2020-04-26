#pragma once
#include <QJsonObject>
#include <QObject>
#include <QVector>

class JsonHandler : public QObject {
    Q_OBJECT
public:
    JsonHandler();
    ~JsonHandler();

    void setJsonRawData(QByteArray&);
    QVector<QString> getHtml();

private:
    QByteArray ba_data;
};
