#pragma once

#include <QObject>
#include <QTimer>
#include <atomic>

class ShutdownController : public QObject {
    Q_OBJECT
    
public:
    static ShutdownController& instance();
    
    void initiateShutdown();
    bool isShutdownComplete() const;
    
signals:
    void shutdownComplete();
    void shutdownTimeout();
    
public slots:
    void onWalletClosed();
    void onNodeDeinitialized();
    void onTorProcessStopped();
    void onShutdownTimeout();
    
private:
    ShutdownController(QObject* parent = nullptr);
    ~ShutdownController() = default;
    
    void checkShutdownComplete();
    
    std::atomic<bool> m_walletClosed;
    std::atomic<bool> m_nodeDeinitialized;
    std::atomic<bool> m_torStopped;
    QTimer m_shutdownTimer;
};
