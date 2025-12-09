#include "ErrorLogger.h"
#include <QDebug>

namespace WalletGui {

void ErrorLogger::logError(const char* function, const std::system_error& error, const QString& context) {
    QString message = QString("System error: %1 (code: %2)")
        .arg(QString::fromStdString(error.what()))
        .arg(error.code().value());
    
    if (!context.isEmpty()) {
        message += QString(" - Context: %1").arg(context);
    }
    
    qCritical() << formatMessage(function, message, Severity::Error);
}

void ErrorLogger::logError(const char* function, const QString& message, Severity severity) {
    QString formattedMsg = formatMessage(function, message, severity);
    
    switch (severity) {
        case Severity::Info:
            qInfo() << formattedMsg;
            break;
        case Severity::Warning:
            qWarning() << formattedMsg;
            break;
        case Severity::Error:
            qCritical() << formattedMsg;
            break;
        case Severity::Critical:
            qCritical() << formattedMsg;
            break;
    }
}

void ErrorLogger::logError(const char* function, int errorCode, const QString& message, Severity severity) {
    QString fullMessage = QString("Error code %1: %2").arg(errorCode).arg(message);
    logError(function, fullMessage, severity);
}

QString ErrorLogger::formatMessage(const char* function, const QString& message, Severity severity) {
    return QString("[%1] [%2] %3: %4")
        .arg(QDateTime::currentDateTime().toString("yyyy-MM-dd HH:mm:ss"))
        .arg(severityToString(severity))
        .arg(function)
        .arg(message);
}

QString ErrorLogger::severityToString(Severity severity) {
    switch (severity) {
        case Severity::Info: return "INFO";
        case Severity::Warning: return "WARN";
        case Severity::Error: return "ERROR";
        case Severity::Critical: return "CRITICAL";
        default: return "UNKNOWN";
    }
}

} // namespace WalletGui
