#ifndef TRANSLATORMANAGER_H
#define TRANSLATORMANAGER_H

#include <QObject>
#include <QMap>
#include <QTranslator>
#include <QMutex>

typedef QMap<QString, QTranslator*> TranslatorMap;

class TranslatorManager
{
    Q_DISABLE_COPY(TranslatorManager)
public:
    static TranslatorManager& instance();
    ~TranslatorManager();

     void switchTranslator(QTranslator& translator, const QString& filename);
     void initialize();
     inline QString getCurrentLang()  { return m_keyLang; }

private:
    TranslatorManager();

    TranslatorMap   m_translators;
    QString         m_keyLang;
    QString         m_langPath;
};

#endif // TRANSLATORMANAGER_H