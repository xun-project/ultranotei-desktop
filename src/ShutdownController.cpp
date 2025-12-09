#include "ShutdownController.h"
#include <QCoreApplication>
#include <QDebug>

ShutdownController& ShutdownController::instance() {
    static ShutdownController inst;
    return inst;
}

ShutdownController::ShutdownController(QObject* parent) 
    : QObject(parent),
      m_walletClosed(false),
      m_nodeDeinitialized(false),
      m_torStopped(false) {
    m_shutdownTimer.setSingleShot(true);
    m_shutdownTimer.setInterval(10000); // 10 second timeout
    connect(&m_shutdownTimer, &QTimer::timeout, 
            this, &ShutdownController::onShutdownTimeout);
}

void ShutdownController::initiateShutdown() {
    qDebug() << "Initiating application shutdown...";
    
    // Reset states
    m_walletClosed = false;
    m_nodeDeinitialized = false;
    m_torStopped = false;
    
    // Start shutdown timer
    m_shutdownTimer.start();
    
    qDebug() << "Shutdown timer started (10 second timeout)";
}

bool ShutdownController::isShutdownComplete() const {
    return m_walletClosed && m_nodeDeinitialized && m_torStopped;
}

void ShutdownController::onWalletClosed() {
    qDebug() << "Wallet closed successfully";
    m_walletClosed = true;
    checkShutdownComplete();
}

void ShutdownController::onNodeDeinitialized() {
    qDebug() << "Node deinitialized successfully";
    m_nodeDeinitialized = true;
    checkShutdownComplete();
}

void ShutdownController::onTorProcessStopped() {
    qDebug() << "Tor process stopped successfully";
    m_torStopped = true;
    checkShutdownComplete();
}

void ShutdownController::onShutdownTimeout() {
    // Force quit even if not all components reported completion
    qWarning() << "Shutdown timeout - forcing application exit";
    qWarning() << "Shutdown state - Wallet:" << m_walletClosed 
               << "Node:" << m_nodeDeinitialized 
               << "Tor:" << m_torStopped;
    emit shutdownTimeout();
}

void ShutdownController::checkShutdownComplete() {
    if (isShutdownComplete()) {
        qDebug() << "All shutdown components completed successfully";
        m_shutdownTimer.stop();
        emit shutdownComplete();
    } else {
        qDebug() << "Shutdown progress - Wallet:" << m_walletClosed 
                 << "Node:" << m_nodeDeinitialized 
                 << "Tor:" << m_torStopped;
    }
}
