#pragma once

#include <QObject>
#include <QClipboard>

class QmlClipboard : public QObject
{
    Q_OBJECT
public:
    explicit QmlClipboard(QObject *parent = nullptr);
    Q_INVOKABLE QString text() const;
    Q_INVOKABLE void setText(const QString &txt);
private:
    QClipboard *m_clipboard = nullptr;
};
