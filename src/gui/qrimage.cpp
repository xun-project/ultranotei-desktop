#include "qrimage.h"
#include "libqrencode/qrencode.h"
#include <QPainter>

QrImage::QrImage(QQuickItem *parent) : QQuickPaintedItem(parent)
{
    connect(this, &QrImage::sourceTextChanged, [&]() {
        generate(m_sourceText);
    });
}

void QrImage::paint(QPainter *painter)
{
    if ((nullptr != painter) && !m_img.isNull()) {
        painter->drawImage(QPoint(0, 0), m_img);
    }
}

void QrImage::setdimension(int value)
{
	dimension = value;
}

int QrImage::getDimension()
{
    return dimension;
}

void QrImage::generate(const QString &msg)
{
    if (msg.isEmpty()) {
        return;
    }

    QRcode *qrcode = QRcode_encodeString(msg.toStdString().c_str(), 1,
                                         QR_ECLEVEL_L, QR_MODE_8, 0);
    if (nullptr == qrcode) {
        qCritical() << "Cannot encode message" << msg;
        return;
    }

    QImage qrCodeImage = QImage(qrcode->width + 8, qrcode->width + 8, QImage::Format_RGB32);
    qrCodeImage.fill(0xffffff);
    unsigned char *p = qrcode->data;
    for (int y = 0; y < qrcode->width; y++) {
        for (int x = 0; x < qrcode->width; x++) {
            qrCodeImage.setPixel(x + 4, y + 4, ((*p & 1) ? 0x0 : 0xffffff));
            p++;
        }
    }
    QRcode_free(qrcode);
    m_img = qrCodeImage.scaled(dimension, dimension);
    update();
}
