// Copyright (c) 2011-2017 The Cryptonote developers
// Copyright (c) 2014-2017 XDN developers
// Copyright (c) 2016-2017 BXC developers
// Copyright (c) 2017 UltraNote developers
// Distributed under the MIT/X11 software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#include <QApplication>
#include <QCommandLineParser>
#include <QLocale>
#include <QLockFile>
#include <QMessageBox>
#include <QSplashScreen>
#include <QStyleFactory>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QClipboard>
#include <QQuickStyle>
#include <QFontDatabase>
#include <QDirIterator>
#include <QFontDatabase>

#include "CommandLineParser.h"
#include "CurrencyAdapter.h"
#include "LoggerAdapter.h"
#include "NodeAdapter.h"
#include "Settings.h"
#include "SignalHandler.h"
#include "WalletAdapter.h"
#include "qmlclipboard.h"
#include "gui/qrimage.h"
#include "gui/documenthandler.h"
#include "gui/BrowserUtils.h"
#include "update.h"

#include "gui/MainWindow.h"
#include <QtWebEngine>

#include <QSystemTrayIcon>
#include "systemtray.h"

#define DEBUG 1

using namespace WalletGui;

int main(int argc, char* argv[]) {
  QApplication::setAttribute(Qt::AA_ShareOpenGLContexts);
  QtWebEngine::initialize();

  QApplication app(argc, argv);
  QApplication::setApplicationName("UltraNoteInfinity");
  QApplication::setOrganizationName("XUNI");
  QApplication::setOrganizationDomain("Cryptocurrency");
  QApplication::setApplicationVersion(Settings::instance().getVersion());
  QApplication::setQuitOnLastWindowClosed(false);


#ifndef Q_OS_MAC
  QApplication::setStyle(QStyleFactory::create("Fusion"));
#endif

  CommandLineParser cmdLineParser(nullptr);
  Settings::instance().setCommandLineParser(&cmdLineParser);
  bool cmdLineParseResult = cmdLineParser.process(QApplication::arguments());
  if (!cmdLineParseResult) {
      qWarning() << "Error in CommandLineParser:process";
  }
  Settings::instance().load();

#ifdef Q_OS_WIN
  if(!cmdLineParseResult) {
    QMessageBox::critical(nullptr, QObject::tr("Error"), cmdLineParser.getErrorText());
    return app.exec();
  } else if (cmdLineParser.hasHelpOption()) {
    QMessageBox::information(nullptr, QObject::tr("Help"), cmdLineParser.getHelpText());
    return app.exec();
  }
#endif

  LoggerAdapter::instance().init();

  QString dataDirPath = Settings::instance().getDataDir().absolutePath();
  if (!QDir().exists(dataDirPath)) {
    QDir().mkpath(dataDirPath);
  }

  QLockFile lockFile(Settings::instance().getDataDir().absoluteFilePath(QApplication::applicationName() + ".lock"));
  if (!lockFile.tryLock()) {
    QMessageBox::warning(nullptr, QObject::tr("Fail"), QString("%1 wallet already running").arg(CurrencyAdapter::instance().getCurrencyDisplayName()));
    return 0;
  }

  QLocale::setDefault(QLocale::c());

  SignalHandler::instance().init();
  QObject::connect(&SignalHandler::instance(), &SignalHandler::quitSignal, &app, &QApplication::quit);

  QPixmap splashImg(":/images/images/UltraNoteSplash.png");
  QSplashScreen splash(splashImg.scaled(800,600), Qt::WindowStaysOnTopHint | Qt::X11BypassWindowManagerHint);
  splash.show();
  splash.setEnabled(false);
  splash.showMessage(QObject::tr("Loading blockchain..."), Qt::AlignCenter | Qt::AlignBottom, Qt::white);
  QApplication::processEvents();
  qRegisterMetaType<CryptoNote::TransactionId>("CryptoNote::TransactionId");
  qRegisterMetaType<quintptr>("quintptr");

  if (!NodeAdapter::instance().init()) {
      qCritical() << "Failed to init node";
    return 0;
  }
  WalletAdapter::instance().open("");
  QQuickStyle::setStyle("Material");

  QDirIterator fontIterator("qrc:/fonts/resources/fonts/Roboto/",
                            QStringList() << "*.ttf" << "*.otf",
                            QDir::Files | QDir::NoSymLinks | QDir::NoDotAndDotDot,
                            QDirIterator::Subdirectories);

  while (fontIterator.hasNext()) {
      QFile font(QDir::fromNativeSeparators(fontIterator.next()));
      if(font.open(QIODevice::ReadOnly)) {
          QFontDatabase::addApplicationFontFromData(font.readAll());
          font.close();
      }
  }

  QQmlApplicationEngine engine;
  BrowserUtils browserUtils;
  engine.rootContext()->setContextProperty("browserUtils", &browserUtils);

  SystemTray systemTray;
  engine.rootContext()->setContextProperty("systemTray", &systemTray);

  engine.addImportPath("qrc:/qml/qml/");
  QQmlContext *context = engine.rootContext();
  if (nullptr != context) {
      auto &walletAdapter = WalletAdapter::instance();
      context->setContextProperty(walletAdapter.objectName(), &walletAdapter);
      auto &currencyAdapter = CurrencyAdapter::instance();
      context->setContextProperty(currencyAdapter.objectName(), &currencyAdapter);
      auto &settings = Settings::instance();
      context->setContextProperty(settings.objectName(), &settings);
      auto *clipboard = new QmlClipboard();
      context->setContextProperty("clipboard", clipboard);
  }

  QFontDatabase fontDatabase;
  if (fontDatabase.addApplicationFont(":/icons/resources/fonts/fontello.ttf") == -1)
	  qWarning() << "Failed to load fontello.ttf";

  qmlRegisterType<QrImage>("QrImage", 1, 0, "QrImage");
  qmlRegisterType<DocumentHandler>("DocumentHandler", 1, 0, "DocumentHandler");
  engine.load(QUrl(QStringLiteral("qrc:/qml/qml/UltraNote/UI/AppWindow.qml")));
  splash.hide();

  /*QObject::connect(&engine, &QQmlApplicationEngine::objectCreated, [=]() {
	splash->finish(&MainWindow::instance());
	Updater d;
	d.checkForUpdate();
	MainWindow::instance().show();
   });*/

  if (engine.rootObjects().isEmpty()) {
      return EXIT_FAILURE;
  }
  QObject::connect(QApplication::instance(), &QApplication::aboutToQuit, []() {
    if (WalletAdapter::instance().isOpen()) {
      WalletAdapter::instance().close();
    }

    NodeAdapter::instance().deinit();
  });
  QApplication::setQuitOnLastWindowClosed(true);
  return QApplication::exec();
}
