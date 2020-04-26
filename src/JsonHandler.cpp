#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QMessageBox>

#include "JsonHandler.h"

JsonHandler::JsonHandler() { }
JsonHandler::~JsonHandler() { }

void JsonHandler::setJsonRawData(QByteArray& ba)
{
    ba_data = ba;
}

QVector<QString> JsonHandler::getHtml()
{
    QVector<QString> result_vec;
    QJsonDocument json_fba = QJsonDocument().fromJson(ba_data);
    QJsonObject JObj = json_fba.object();

    if (JObj.isEmpty()) {
        return result_vec;
    }

    QJsonArray array_res = JObj["results"].toArray();

    if (array_res.isEmpty()) {
        return result_vec;
    }

    for (auto const i : array_res) {
        QJsonObject obj = i.toObject();

        QString link = obj["url"].toString();

        if(!link.startsWith("http://") && !link.startsWith("https://")) {
            continue;
        }

        QString result = "";

        //result.append("<p></p>");

        QString title = "<a href = \"";
        title.append(link);
        title.append("\">");
        title.append(obj["title"].toString());
        title.append("</a>");

        result.append(title);

        QString sum = obj["sum"].toString();
        if (sum.length() > 0) {
            result.append("<br>");
            result.append(sum);
        }

        result.append("<br>");

        QString url = "<font color=\"#1e8449\">";
        url.append(obj["site"].toString());
        url.append("</font>");
        result.append(url);

        result_vec.push_back(result);
    }

    return result_vec;
}
