#include "qmlclipboard.h"
#include <QApplication>

QmlClipboard::QmlClipboard(QObject *parent) : QObject(parent),
    m_clipboard(QApplication::clipboard())
{
}

QString QmlClipboard::text() const
{
    return (nullptr != m_clipboard) ? m_clipboard->text() : "";
}

void QmlClipboard::setText(const QString &txt)
{
    if (nullptr != m_clipboard) {
        m_clipboard->setText(txt);
    }
}
