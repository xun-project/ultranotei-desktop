#include <QApplication>
#include <QLocale>
#include <QTranslator>
#include <qdebug.h>

#include "Settings.h"
#include "TranslatorManager.h"

using namespace WalletGui;

TranslatorManager* TranslatorManager::m_Instance = 0;

TranslatorManager::TranslatorManager()
{
    QString lang = Settings::instance().getLanguage();
    if(lang.isEmpty()) {
        lang = QLocale::system().name();
        qInfo() << "lang : "<< lang;
        lang.truncate(lang.lastIndexOf('_'));
    }

#if defined(_MSC_VER)
  m_langPath = QApplication::applicationDirPath();
  m_langPath.append("/languages");
#elif defined(Q_OS_MAC)
  m_langPath = QApplication::applicationDirPath();
  m_langPath = m_langPath + "/../Resources/languages/";
#else
  m_langPath = "languages";
#endif

    QDir dir(m_langPath);
    QStringList resources = dir.entryList(QStringList() << "*.qm", QDir::Files);
    qInfo() << "Application translation path :" << m_langPath;
    qInfo() << "Available translations  :" << resources;

    for (int j = 0; j < resources.size(); j++)
    {
        QString locale = resources[j];
        locale.remove(0, locale.indexOf('_'));

        //Example : "_ru.qm"
        if (locale == lang)
        {
            QTranslator* pTranslator = new QTranslator;
            if (pTranslator->load(resources[j], m_langPath))
            {
                qApp->installTranslator(pTranslator) ? qInfo() << "pTranslator install success" : qInfo()<<"pTranslator install failed";
                m_keyLang = locale;
                m_translators.insert(locale, pTranslator);
                break;
            }
        }
    }

    QStringList resourcesQt = QDir(QApplication::applicationDirPath().append("/translations")).entryList(QStringList() << "qt_*.qm", QDir::Files);
    qInfo() << "Qt translations dir :" << QApplication::applicationDirPath().append("/translations");
    qInfo() << "Qt translations :" << resourcesQt;

    m_langPath.truncate(m_langPath.lastIndexOf('/'));
    m_langPath.append("/translations");

    for (int j = 0; j < resourcesQt.size(); j++)
    {
        QString locale = resourcesQt[j];
        locale.remove(0, locale.indexOf('_'));

        //Example : "_ru.qm"
        if (locale == lang)
        {
            QTranslator* qTranslator = new QTranslator;
            if (qTranslator->load(resourcesQt[j], m_langPath))
            {
                qApp->installTranslator(qTranslator) ? qInfo() << "qTranslator install success" : qInfo() << "qTranslator install failed";
                m_keyLang = locale;
                m_translators.insert(locale, qTranslator);
                break;
            }
        }
    }
}

TranslatorManager::~TranslatorManager()
{
    TranslatorMap::const_iterator i = m_translators.begin();
    while (i != m_translators.end())
    {
        QTranslator* pTranslator = i.value();
        delete pTranslator;
        ++i;
    }

    m_translators.clear();
}

TranslatorManager* TranslatorManager::instance()
{
    static QMutex mutex;
    if (!m_Instance)
    {
        mutex.lock();

        if (!m_Instance)
            m_Instance = new TranslatorManager;

        mutex.unlock();
    }

    return m_Instance;
}

void TranslatorManager::switchTranslator(QTranslator& translator, const QString& filename)
{

  // remove the old translator
  qApp->removeTranslator(&translator) ? qInfo() << "remove translator success" : qInfo() << "remove translator failed";

  // load the new translator
  if(translator.load(filename))
   qApp->installTranslator(&translator) ? qInfo() << "switch translator success" : qInfo() << "switch translator failed";
}
