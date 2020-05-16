#pragma once

#include <QObject>
#include "CryptoNoteWrapper.h"
#include "CurrencyAdapter.h"

namespace WalletGui {

class OptimizationService : public QObject {
    Q_OBJECT
    Q_DISABLE_COPY(OptimizationService)
public:
    OptimizationService(QObject* _parent = nullptr);
    ~OptimizationService();

    void checkOptimization();

    Q_SLOT void walletOpened();
    Q_SLOT void walletClosed();
    Q_SLOT void synchronizationProgressUpdated();
    Q_SLOT void synchronizationCompleted();

public Q_SLOTS:
    void stop();

Q_SIGNALS:
    void finished();

protected:
    virtual void timerEvent(QTimerEvent *_event);

private:
    int m_checkTimerId;
    int m_optimizationTimerId;
    quint64 m_currentOptimizationInterval;
    bool m_isSynchronized;

    void delay();
    void optimize();
    void ensureStarted();
    void ensureStopped();

};
}