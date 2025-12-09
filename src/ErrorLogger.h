#pragma once

#include <QString>
#include <QDateTime>
#include <system_error>

namespace WalletGui {

class ErrorLogger {
public:
    enum class Severity {
        Info,
        Warning,
        Error,
        Critical
    };

    // Log a system error with context
    static void logError(const char* function, const std::system_error& error, const QString& context = QString());
    
    // Log a general error message
    static void logError(const char* function, const QString& message, Severity severity = Severity::Error);
    
    // Log an error with error code
    static void logError(const char* function, int errorCode, const QString& message, Severity severity = Severity::Error);

private:
    static QString formatMessage(const char* function, const QString& message, Severity severity);
    static QString severityToString(Severity severity);
};

} // namespace WalletGui
