#pragma once

#include "qmlhelpers.h"
#include <QQuickPaintedItem>
#include <QImage>

class QrImage : public QQuickPaintedItem
{
	Q_OBJECT
	QML_READABLE_PROPERTY(QString, sourceText, setSourceText, "")
	Q_PROPERTY(int dimension WRITE setdimension READ getDimension)
public:
    QrImage(QQuickItem *parent = nullptr);
    void paint(QPainter *painter) override;
	void setdimension(int value);
    int getDimension();

private:
    void generate(const QString &msg);
    QImage m_img;
	int dimension = 300;
};
