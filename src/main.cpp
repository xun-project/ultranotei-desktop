// Copyright (c) 2011-2017 The Cryptonote developers
// Copyright (c) 2014-2017 XDN developers
// Copyright (c) 2016-2017 BXC developers
// Copyright (c) 2017-2023 UltraNote Infinity Developers
// Distributed under the MIT/X11 software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#include <QApplication>
#include <QTimer>
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
#include <QtWebEngine>
#include <QSystemTrayIcon>

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
#include "systemtray.h"
#include "ShutdownController.h"

#define DEBUG 1

using namespace WalletGui;

void customMessageHandler(QtMsgType type, const QMessageLogContext &context, const QString &msg)
{
    QByteArray localMsg = msg.toLocal8Bit();
    const char *file = context.file ? context.file : "";
    const char *function = context.function ? context.function : "";
    
    QString logFileName = Settings::instance().getDataDir().absoluteFilePath("debug.log");
    QFile outFile(logFileName);
    outFile.open(QIODevice::WriteOnly | QIODevice::Append);
    QTextStream ts(&outFile);
    
    QString typeStr;
    switch (type) {
    case QtDebugMsg:
        typeStr = "Debug";
        break;
    case QtInfoMsg:
        typeStr = "Info";
        break;
    case QtWarningMsg:
        typeStr = "Warning";
        break;
    case QtCriticalMsg:
        typeStr = "Critical";
        break;
    case QtFatalMsg:
        typeStr = "Fatal";
        break;
    }
    
    ts << typeStr << ": " << localMsg.constData() << " (" << file << ":" << context.line << ", " << function << ")" << endl;
    
    // Also print to stderr for console visibility if attached
    fprintf(stderr, "%s: %s (%s:%u, %s)\n", typeStr.toStdString().c_str(), localMsg.constData(), file, context.line, function);
}

int main(int argc, char* argv[]) {

    int currentExitCode = 0;

    do {
        QApplication::setAttribute(Qt::AA_ShareOpenGLContexts);
        QApplication app(argc, argv);
        QtWebEngine::initialize();

        
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

        qInstallMessageHandler(customMessageHandler);

#ifdef Q_OS_WIN
        if (!cmdLineParseResult) {
            QMessageBox::critical(nullptr, QObject::tr("Error"), cmdLineParser.getErrorText());
            return app.exec();
        }
        else if (cmdLineParser.hasHelpOption()) {
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
        QSplashScreen splash(splashImg.scaled(800, 600), Qt::WindowStaysOnTopHint | Qt::X11BypassWindowManagerHint);
        splash.show();
        splash.setEnabled(false);
        QString connection = Settings::instance().getConnection();
        QString nodeMessage;
        if (connection == "embedded") {
            nodeMessage = QObject::tr("Starting local node...");
        } else if (connection == "remote") {
            nodeMessage = QObject::tr("Connecting to remote node...");
        } else if (connection == "local") {
            nodeMessage = QObject::tr("Connecting to local daemon...");
        } else {
            nodeMessage = QObject::tr("Auto-detecting connection...");
        }
        // Animated progress dots
        QString currentStageMessage = nodeMessage;
        int dotCount = 0;
        QTimer animationTimer;
        animationTimer.setInterval(500);
        QObject::connect(&animationTimer, &QTimer::timeout, [&]() {
            dotCount = (dotCount + 1) % 4;
            QString dots = QString(".").repeated(dotCount);
            splash.showMessage(currentStageMessage + dots, Qt::AlignCenter | Qt::AlignBottom, Qt::white);
        });
        animationTimer.start();
        splash.showMessage(currentStageMessage, Qt::AlignCenter | Qt::AlignBottom, Qt::white);
        QApplication::processEvents();
        qRegisterMetaType<cn::TransactionId>("cn::TransactionId");
        qRegisterMetaType<quintptr>("quintptr");

        if (!NodeAdapter::instance().init()) {
            qCritical() << "Failed to init node";
            animationTimer.stop();
            return 0;
        }
        currentStageMessage = QObject::tr("Opening wallet...");
        splash.showMessage(currentStageMessage, Qt::AlignCenter | Qt::AlignBottom, Qt::white);
        QApplication::processEvents();
        // Stop animation when wallet opens (splash will hide soon)
        // Actually we stop when splash hides
        // We'll stop after splash.hide() but we can keep it running until then.

        if (currentExitCode == WalletAdapter::EXIT_CODE_REBOOT)
            WalletAdapter::instance().initializeAdapter();

        WalletAdapter::instance().open("");
        QQuickStyle::setStyle("Material");

        QDirIterator fontIterator("qrc:/fonts/resources/fonts/Roboto/",
                                  QStringList() << "*.ttf" << "*.otf",
                                  QDir::Files | QDir::NoSymLinks | QDir::NoDotAndDotDot,
                                  QDirIterator::Subdirectories);

        while (fontIterator.hasNext()) {
            QFile font(QDir::fromNativeSeparators(fontIterator.next()));
            if (font.open(QIODevice::ReadOnly)) {
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
        QQmlContext* context = engine.rootContext();
        if (nullptr != context) {
            auto& walletAdapter = WalletAdapter::instance();
            context->setContextProperty(walletAdapter.objectName(), &walletAdapter);
            auto& currencyAdapter = CurrencyAdapter::instance();
            context->setContextProperty(currencyAdapter.objectName(), &currencyAdapter);
            auto& settings = Settings::instance();
            context->setContextProperty(settings.objectName(), &settings);
            auto* clipboard = new QmlClipboard();
            context->setContextProperty("clipboard", clipboard);
        }

        QFontDatabase fontDatabase;
        if (fontDatabase.addApplicationFont(":/icons/resources/fonts/fontello.ttf") == -1)
            qWarning() << "Failed to load fontello.ttf";

        qmlRegisterType<QrImage>("QrImage", 1, 0, "QrImage");
        qmlRegisterType<DocumentHandler>("DocumentHandler", 1, 0, "DocumentHandler");
        engine.load(QUrl(QStringLiteral("qrc:/qml/qml/UltraNote/UI/AppWindow.qml")));
        animationTimer.stop();
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
        // Use ShutdownController for proper shutdown sequence
        QObject::connect(QApplication::instance(), &QApplication::aboutToQuit, []() {
            auto& shutdownController = ShutdownController::instance();
            
            // Connect shutdown completion to actual quit
            QObject::connect(&shutdownController, &ShutdownController::shutdownComplete,
                             QApplication::instance(), &QApplication::quit, Qt::QueuedConnection);
            
            // Connect timeout to force quit
            QObject::connect(&shutdownController, &ShutdownController::shutdownTimeout,
                             QApplication::instance(), &QApplication::quit, Qt::QueuedConnection);
            
            // Start shutdown sequence
            shutdownController.initiateShutdown();
            
            // Don't exit immediately - let shutdown controller manage it
            // The old shutdown code will now be called by the components themselves
            // when they notify the ShutdownController
        });
        QApplication::setQuitOnLastWindowClosed(true);

        currentExitCode = QApplication::exec();

    } while (currentExitCode == WalletAdapter::EXIT_CODE_REBOOT);

    return currentExitCode;
}
