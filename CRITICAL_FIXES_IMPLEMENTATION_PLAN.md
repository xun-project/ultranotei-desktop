# Critical Fixes Implementation Plan

## Issue 1: Process Cleanup Bug (Wallet stays running after closing)

### Root Cause Analysis
The wallet process remains running because:
1. `WalletAdapter::close()` is asynchronous but the application exits immediately
2. `NodeAdapter::deinit()` doesn't properly wait for thread completion
3. Tor process (`QProcess`) is not guaranteed to terminate
4. No synchronization between cleanup components

### Proposed Solution

#### 1. Create Shutdown Controller
```cpp
// File: src/ShutdownController.h
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
    
private slots:
    void onWalletClosed();
    void onNodeDeinitialized();
    void onTorProcessStopped();
    void onShutdownTimeout();
    
private:
    ShutdownController(QObject* parent = nullptr);
    ~ShutdownController() = default;
    
    std::atomic<bool> m_walletClosed{false};
    std::atomic<bool> m_nodeDeinitialized{false};
    std::atomic<bool> m_torStopped{false};
    QTimer m_shutdownTimer;
};
```

#### 2. Modify main.cpp
```cpp
// File: src/main.cpp (partial modifications)

// Add include
#include "ShutdownController.h"

// Modify the aboutToQuit connection
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
});

// Remove the existing aboutToQuit connection that calls WalletAdapter::close() directly
```

#### 3. Modify WalletAdapter.cpp
```cpp
// File: src/WalletAdapter.cpp (partial modifications)

// Add include
#include "ShutdownController.h"

void WalletAdapter::close() {
    Q_CHECK_PTR(m_wallet);
    
    // Store the original close logic but emit signal when done
    save(true, true);
    lock();
    m_wallet->removeObserver(this);
    m_isSynchronized = false;
    m_newTransactionsNotificationTimer.stop();
    m_lastWalletTransactionId = std::numeric_limits<quint64>::max();
    Q_EMIT walletCloseCompletedSignal();
    QCoreApplication::processEvents();
    m_wallet.reset();
    m_wallet = nullptr;
    stopTorProcess();
    unlock();
    setIsWalletOpen(false);
    setSynchronizationStateIcon("");
    setEncryptionStateIcon("");

    if (optimizationService != nullptr) {
        delete optimizationService;
        optimizationService = nullptr;
    }

    m_depositTableModel->reinitHeaderNames();
    
    // Notify shutdown controller
    ShutdownController::instance().onWalletClosed();
}

// Add synchronous close method for shutdown
void WalletAdapter::closeSynchronously() {
    QEventLoop waitLoop;
    QObject::connect(this, &WalletAdapter::walletCloseCompletedSignal, 
                     &waitLoop, &QEventLoop::quit);
    
    close();
    
    // Wait with timeout
    QTimer::singleShot(5000, &waitLoop, &QEventLoop::quit);
    waitLoop.exec();
}
```

#### 4. Modify NodeAdapter.cpp
```cpp
// File: src/NodeAdapter.cpp (partial modifications)

// Add include
#include "ShutdownController.h"

void NodeAdapter::deinit() {
    QMutexLocker lock(&m_mutex);
    if (m_node != nullptr) {
        if (m_nodeInitializerThread.isRunning()) {
            // Connect deinit completion signal
            QEventLoop waitLoop;
            QObject::connect(m_nodeInitializer, &InProcessNodeInitializer::nodeDeinitCompletedSignal,
                           &waitLoop, &QEventLoop::quit);
            
            m_nodeInitializer->stop(m_node.get());
            
            // Wait with timeout
            QTimer::singleShot(3000, &waitLoop, &QEventLoop::quit);
            waitLoop.exec();
            
            m_nodeInitializerThread.quit();
            m_nodeInitializerThread.wait(2000); // Wait up to 2 seconds
        } else {
            m_node.reset();
        }
    }
    
    // Notify shutdown controller
    ShutdownController::instance().onNodeDeinitialized();
}
```

#### 5. Implement ShutdownController.cpp
```cpp
// File: src/ShutdownController.cpp
#include "ShutdownController.h"
#include <QCoreApplication>

ShutdownController& ShutdownController::instance() {
    static ShutdownController inst;
    return inst;
}

ShutdownController::ShutdownController(QObject* parent) 
    : QObject(parent) {
    m_shutdownTimer.setSingleShot(true);
    m_shutdownTimer.setInterval(10000); // 10 second timeout
    connect(&m_shutdownTimer, &QTimer::timeout, 
            this, &ShutdownController::onShutdownTimeout);
}

void ShutdownController::initiateShutdown() {
    // Reset states
    m_walletClosed = false;
    m_nodeDeinitialized = false;
    m_torStopped = false;
    
    // Start shutdown timer
    m_shutdownTimer.start();
    
    // Initiate shutdown sequence
    // Note: These should be called in appropriate order
    // WalletAdapter::instance().closeSynchronously();
    // NodeAdapter::instance().deinit();
    // Tor process stop...
    
    // For now, components will call the slot methods when done
}

bool ShutdownController::isShutdownComplete() const {
    return m_walletClosed && m_nodeDeinitialized && m_torStopped;
}

void ShutdownController::onWalletClosed() {
    m_walletClosed = true;
    checkShutdownComplete();
}

void ShutdownController::onNodeDeinitialized() {
    m_nodeDeinitialized = true;
    checkShutdownComplete();
}

void ShutdownController::onTorProcessStopped() {
    m_torStopped = true;
    checkShutdownComplete();
}

void ShutdownController::onShutdownTimeout() {
    // Force quit even if not all components reported completion
    qWarning() << "Shutdown timeout - forcing application exit";
    emit shutdownTimeout();
}

void ShutdownController::checkShutdownComplete() {
    if (isShutdownComplete()) {
        m_shutdownTimer.stop();
        emit shutdownComplete();
    }
}
```

### 6. Update CMakeLists.txt
Add the new files to the build system:
```cmake
# Add to SOURCES list in CMakeLists.txt
set(SOURCES
    ...
    src/ShutdownController.cpp
    ...
)

# Add to HEADERS list
set(HEADERS
    ...
    src/ShutdownController.h
    ...
)
```

## Issue 2: Startup Performance Optimization

### Immediate Improvements

#### 1. Background Initialization
```cpp
// File: src/main.cpp (partial modifications)

// Create a background initialization controller
class BackgroundInitializer : public QObject {
    Q_OBJECT
public:
    explicit BackgroundInitializer(QObject* parent = nullptr) : QObject(parent) {}
    
    void initialize() {
        // Move heavy operations here
        QtWebEngine::initialize();
        
        // Load fonts in background
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
        
        emit initializationComplete();
    }
    
signals:
    void initializationComplete();
};

// In main function:
QSplashScreen splash(splashImg.scaled(800, 600), Qt::WindowStaysOnTopHint | Qt::X11BypassWindowManagerHint);
splash.show();
splash.setEnabled(false);
splash.showMessage(QObject::tr("Initializing..."), Qt::AlignCenter | Qt::AlignBottom, Qt::white);

// Start background initialization
BackgroundInitializer* bgInit = new BackgroundInitializer();
QThread* bgThread = new QThread();
bgInit->moveToThread(bgThread);

connect(bgThread, &QThread::started, bgInit, &BackgroundInitializer::initialize);
connect(bgInit, &BackgroundInitializer::initializationComplete, bgThread, &QThread::quit);
connect(bgInit, &BackgroundInitializer::initializationComplete, bgInit, &BackgroundInitializer::deleteLater);
connect(bgThread, &QThread::finished, bgThread, &QThread::deleteLater);

bgThread->start();

// Continue with lighter initialization in main thread
// ...
```

#### 2. Lazy QML Loading
```qml
// File: src/qml/UltraNote/UI/AppWindow.qml (partial modifications)

// Replace StackView with lazy loading
StackView {
    id: _appPagesStackView
    
    // ... existing properties ...
    
    // Use Loader for heavy components
    Component {
        id: _browserPageLoader
        BrowserPage {
            id: _browserPageComponentItem
        }
    }
    
    // Load components on demand
    function loadPage(pageName) {
        switch(pageName) {
            case "browser":
                if (!_browserPageLoader.status === Component.Ready) {
                    push(_browserPageLoader);
                }
                break;
            // ... other pages ...
        }
    }
}
```

## Testing Plan

### 1. Unit Tests
- Create tests for ShutdownController
- Test WalletAdapter close sequence
- Test NodeAdapter deinit sequence

### 2. Integration Tests
- Test complete application shutdown
- Test startup with different configurations
- Test error recovery during shutdown

### 3. Manual Testing Checklist
- [ ] Close application via X button
- [ ] Close application via menu → Exit
- [ ] Close application via system tray
- [ ] Verify no leftover processes in Task Manager
- [ ] Test with wallet open/closed
- [ ] Test with Tor enabled/disabled
- [ ] Test with embedded/local/remote node

## Rollback Plan

If issues occur:
1. Revert ShutdownController changes
2. Keep improved WalletAdapter::close() logic
3. Maintain background initialization improvements
4. Preserve QML lazy loading optimizations

## Timeline

### Week 1
- Implement ShutdownController
- Modify WalletAdapter close sequence
- Add unit tests

### Week 2
- Modify NodeAdapter deinit
- Implement background initialization
- Test on Windows

### Week 3
- Test on Linux and macOS
- Fix platform-specific issues
- Performance profiling

### Week 4
- Final testing
- Documentation updates
- Release preparation

## Success Metrics
- No leftover processes after close
- Shutdown completes within 5 seconds
- Startup time reduced by 30%
- Memory usage stable or reduced

## Risk Mitigation
- Keep changes incremental
- Maintain backward compatibility
- Extensive testing on all platforms
- Monitor error logs in production
