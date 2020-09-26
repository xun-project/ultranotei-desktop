// Copyright (c) 2011-2017 The Cryptonote developers
// Copyright (c) 2014-2017 XDN developers
// Copyright (c) 2016-2017 BXC developers
// Copyright (c) 2017 UltraNote developers
// Distributed under the MIT/X11 software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#pragma once

#include <QMutex>
#include <QObject>
#include <QTimer>
#include <QtMultimedia/qsoundeffect.h>
#include <QProcess>

#include <atomic>
#include <fstream>

#include "CryptoNoteConfig.h"
#include "fiatconverter.h"
#include "gui/InvoiceService.h"
#include "gui/NodeModel.h"
#include "gui/SearchService.h"
#include "gui/addressbooktablemodel.h"
#include "gui/deposittablemodel.h"
#include "gui/messagestablemodel.h"
#include "gui/sendmessagemodel.h"
#include "gui/transactionstablemodel.h"
#include "gui/MiningService.h"
#include "qmlhelpers.h"
#include <IWalletLegacy.h>
#include "gui/OptimizationService.h"

namespace WalletGui {

class WalletAdapter : public QObject, public CryptoNote::IWalletLegacyObserver {
    Q_OBJECT
    Q_DISABLE_COPY(WalletAdapter)
    Q_PROPERTY(bool isWalletOpen READ isWalletOpen WRITE setIsWalletOpen NOTIFY isWalletOpenChanged)
    QML_CONSTANT_PROPERTY(int, defaultDaemonPort, CryptoNote::RPC_DEFAULT_PORT)
    Q_PROPERTY(bool isWalletEncrypted READ isWalletEncrypted NOTIFY isWalletEncryptedChanged)
    Q_PROPERTY(bool isStartOnLoginEnabled READ isStartOnLoginEnabled WRITE startOnLogin NOTIFY isStartOnLoginEnabledChanged)
    Q_PROPERTY(QString selectedLangauge READ currentLanguage WRITE newSelectedLangauge NOTIFY selectedLangaugeChanged)
    QML_WRITABLE_PROPERTY(int, localDaemonPort, setLocalDaemonPort, 0)
    QML_WRITABLE_PROPERTY(int, connectionMode, setConnectionMode, CONNECTION_MODE_UNKNOWN)
    QML_CONSTANT_PROPERTY_PTR(NodeModel, nodeModel)
    QML_READABLE_PROPERTY(QString, statusBarText, setStatusBarText, "")

    QML_READABLE_PROPERTY(bool, isTorEnabled, setTorEnabled, false)
    QML_READABLE_PROPERTY(QString, remoteModeIcon, setRemoteModeIcon, "")
    QML_READABLE_PROPERTY(QString, remoteModeToolTip, setRemoteModeToolTip, "")
    QML_READABLE_PROPERTY(QString, connectionStateIcon, setConnectionStateIcon, "")
    QML_READABLE_PROPERTY(QString, connectionStateToolTip, setConnectionStateToolTip, "")
    QML_READABLE_PROPERTY(QString, encryptionStateIcon, setEncryptionStateIcon, "")
    QML_READABLE_PROPERTY(QString, encryptionStateToolTip, setEncryptionStateToolTip, "")
    QML_READABLE_PROPERTY(QString, synchronizationStateIcon, setSynchronizationStateIcon, "")
    QML_READABLE_PROPERTY(QString, synchronizationStateToolTip, setSynchronizationStateToolTip, "")
    QML_READABLE_PROPERTY(QString, optimizationState, setOptimizationState, "(Optimization not required)")
    QML_READABLE_PROPERTY(bool, synchronizationStatePlaying, setSynchronizationStatePlaying, false)
    QML_CONSTANT_PROPERTY_PTR(FiatConverter, fiatConverter)
    QML_CONSTANT_PROPERTY_PTR(DepositTableModel, depositTableModel)
    QML_CONSTANT_PROPERTY_PTR(AddressBookTableModel, addressBookTableModel)
    QML_CONSTANT_PROPERTY_PTR(TransactionsTableModel, transactionsTableModel)
    QML_CONSTANT_PROPERTY_PTR(MessagesTableModel, messagesTableModel)
    QML_CONSTANT_PROPERTY_PTR(SendMessageModel, sendMessageModel)
    QML_CONSTANT_PROPERTY_PTR(SearchService, searchService)
    QML_CONSTANT_PROPERTY_PTR(InvoiceService, invoiceService)
    QML_CONSTANT_PROPERTY_PTR(MiningService, miningService)

    QML_READABLE_PROPERTY(QString, publicAddress, setPublicAddress, "")
    QML_READABLE_PROPERTY(QString, privateSpendKey, setprivateSpendKey, "")
    QML_READABLE_PROPERTY(QString, privateViewKey, setPrivateViewKey, "")
    QML_READABLE_PROPERTY(QString, guiKey, setguiKey, "")
    QML_READABLE_PROPERTY(QString, mnemonicSeed, setMnemonicSeed, "")
    QML_READABLE_PROPERTY(QString, trackingEnabledLablel, setTrackingEnabledLablel, "")

public:
    enum ConnectionMode {
        CONNECTION_MODE_UNKNOWN = -1,
        CONNECTION_MODE_AUTO,
        CONNECTION_MODE_EMBEDDED,
        CONNECTION_MODE_LOCAL,
        CONNECTION_MODE_REMOTE
    };
    Q_ENUM(ConnectionMode)

    static WalletAdapter& instance();

    Q_SLOT void setTorSettings();
    Q_INVOKABLE void open(const QString& _password);
    Q_INVOKABLE void removeLock(const QString& _password);
    void createWithKeys(const CryptoNote::AccountKeys& _keys);
    void close();
    bool save(bool _details, bool _cache);
    void backup(const QString& _file);
    void reset();

    Q_INVOKABLE QString secondsToNativeTime(int _seconds);
    Q_INVOKABLE void openWallet(const QUrl& fileUrl);
    Q_INVOKABLE void createWallet(const QUrl& fileUrl);
    Q_INVOKABLE void resetWallet();
    Q_INVOKABLE void importKey(const QString& key, const QString& filePath);
    Q_INVOKABLE void backupWallet(const QUrl& fileUrl);
    Q_INVOKABLE bool encryptWallet(const QString& oldPwd, const QString& newPwd);
    Q_INVOKABLE void startOnLogin(bool on);
    Q_INVOKABLE void enableTor();
    Q_INVOKABLE void loadLanguage();

    Q_INVOKABLE QString toLocalFile(const QUrl& fileUrl) const;
    Q_INVOKABLE bool optimizeClicked();
    Q_INVOKABLE void autoOptimizeClicked();
    Q_INVOKABLE bool isAutoOpimizationEnabled() const;
    Q_INVOKABLE void importSecretkeys(QString spendKey, QString viewKey, QString walletFilePath);
    Q_INVOKABLE void importTrackingkey(QString keyString, QString filePath);
    Q_INVOKABLE void importMnemonicSeed(QString seed, QString filePath);
    Q_INVOKABLE void setIsWalletOpen(bool on);
    
    bool getTorEnabled();
    void newSelectedLangauge(QString lang);
    QString currentLanguage() const;

	QString getAddress() const;
    quint64 getActualBalance() const;
    quint64 getPendingBalance() const;
    quint64 getActualDepositBalance() const;
    quint64 getPendingDepositBalance() const;
    quint64 getTransactionCount() const;
    quint64 getTransferCount() const;
    quint64 getDepositCount() const;

    bool getTransaction(CryptoNote::TransactionId _id, CryptoNote::WalletLegacyTransaction& _transaction);
    bool getTransfer(CryptoNote::TransferId _id, CryptoNote::WalletLegacyTransfer& _transfer);
    bool getDeposit(CryptoNote::DepositId _id, CryptoNote::Deposit& _deposit);
    bool getAccountKeys(CryptoNote::AccountKeys& _keys);
    Q_INVOKABLE bool isOpen() const;
    void encryptAttachment(QByteArray& attachment, QByteArray& encryptionKey);
    void decryptAttachment(QByteArray& attachment, QByteArray& encryptionKey);
    void sendTransaction(const QVector<CryptoNote::WalletLegacyTransfer>& _transfers, quint64 _fee, const QString& _payment_id, quint64 _mixin,
        const QVector<CryptoNote::TransactionMessage>& _messages);
    void sendMessage(const QVector<CryptoNote::WalletLegacyTransfer>& _transfers, quint64 _fee, quint64 _mixin,
        const QVector<CryptoNote::TransactionMessage>& _messages, quint64 _ttl);
    Q_INVOKABLE void deposit(int _term, qreal _amount, int _fee, int _mixIn);
    Q_INVOKABLE void withdraw();
    void withdrawUnlockedDeposits(QVector<CryptoNote::DepositId> _depositIds, quint64 _fee);
    bool changePassword(const QString& _old_pass, const QString& _new_pass);
    void setWalletFile(const QString& _path);

    void initCompleted(std::error_code _result) Q_DECL_OVERRIDE;
    void saveCompleted(std::error_code _result) Q_DECL_OVERRIDE;
    void synchronizationProgressUpdated(uint32_t _current, uint32_t _total) Q_DECL_OVERRIDE;
    void synchronizationCompleted(std::error_code _error) Q_DECL_OVERRIDE;
    void actualBalanceUpdated(uint64_t _actualBalance) Q_DECL_OVERRIDE;
    void pendingBalanceUpdated(uint64_t _pendingBalance) Q_DECL_OVERRIDE;
    void actualDepositBalanceUpdated(uint64_t _actualDepositBalance) Q_DECL_OVERRIDE;
    void pendingDepositBalanceUpdated(uint64_t _pendingDepositBalance) Q_DECL_OVERRIDE;
    void externalTransactionCreated(CryptoNote::TransactionId _transactionId) Q_DECL_OVERRIDE;
    void sendTransactionCompleted(CryptoNote::TransactionId _transactionId, std::error_code _result) Q_DECL_OVERRIDE;
    void transactionUpdated(CryptoNote::TransactionId _transactionId) Q_DECL_OVERRIDE;
    void depositsUpdated(const std::vector<CryptoNote::DepositId>& _depositIds) Q_DECL_OVERRIDE;
    bool isWalletEncrypted() const;
    bool isStartOnLoginEnabled() const;

    void initLocalDaemonPort();
    void setLocalDaemonPort();
    void initConnectionMode();
    void setConnectionMode();
    Q_INVOKABLE void saveConnectionSettings();

    Q_INVOKABLE void send(const QString& payTo, const QString& paymentId,
        const QString& label, const QString& comment,
		qreal amount, int fee, int anonLevel);
	Q_INVOKABLE quint16 getCommentCharPrice();

    quint64 getNumUnlockedOutputs() const;
    void optimizationDelay();
    void optimizeWallet();

    bool isWalletOpen() const;

    WalletAdapter();
        ~WalletAdapter() = default;

private:
    QProcess* torProcess = nullptr;
	QSoundEffect incomingTransactionEffect;
	QSoundEffect outgoingTransactionEffect;
    std::fstream m_file;
    CryptoNote::IWalletLegacy* m_wallet;
    QMutex m_mutex;
    std::atomic<bool> m_isBackupInProgress;
    std::atomic<bool> m_isSynchronized;
    std::atomic<quint64> m_lastWalletTransactionId;
    QTimer m_newTransactionsNotificationTimer;
    std::atomic<CryptoNote::TransactionId> m_sentTransactionId;
    std::atomic<CryptoNote::TransactionId> m_sentMessageId;
    std::atomic<CryptoNote::TransactionId> m_depositId;
    std::atomic<CryptoNote::TransactionId> m_depositWithdrawalId;
    bool m_isWalletOpen = false;

    QTranslator m_translator;   // contains the translations for this application
    QTranslator m_translatorQt; // contains the translations for qt
    QString m_currLang;         // contains the currently loaded language
    QString m_langPath;         // Path of language files. This is always fixed to /languages
    QString m_newLang;          // contains the new language to be loaded

    void onWalletInitCompleted(int _error, const QString& _error_text);
    void onWalletSendTransactionCompleted(CryptoNote::TransactionId _transaction_id, int _error, const QString& _error_text);

    bool importLegacyWallet(const QString& _password);
    bool save(const QString& _file, bool _details, bool _cache);
    void lock();
    void unlock();
    bool openFile(const QString& _file, bool _read_only);
    void closeFile();
    void notifyAboutLastTransaction();
    void stopTorProcess();

    static void renameFile(const QString& _old_name, const QString& _new_name);
    Q_SLOT void updateBlockStatusText();
	Q_SLOT void updateWalletTransactions();
	Q_SLOT void newTransactionSoundEffect(CryptoNote::TransactionId _transactionId);
    Q_SLOT void updateOptimizationLabel();
    void updateBlockStatusTextWithDelay();
    void encryptedFlagChanged(bool encrypted);
    void checkTrackingMode();
    void setPrivateKeys();
    void setWalletTrackingLabel();
Q_SIGNALS:
    void walletInitCompletedSignal(int _error, const QString& _errorText);
    void walletCloseCompletedSignal();
    void walletSaveCompletedSignal(int _error, const QString& _errorText);
    void walletSynchronizationProgressUpdatedSignal(quint64 _current, quint64 _total);
    void walletSynchronizationCompletedSignal(int _error, const QString& _error_text);

    void walletActualBalanceUpdatedSignal(qreal _actualBalance);
    void walletPendingBalanceUpdatedSignal(qreal _pendingBalance);
    void walletActualDepositBalanceUpdatedSignal(qreal _actualDepositBalance);
    void walletPendingDepositBalanceUpdatedSignal(qreal _pendingDepositBalance);

    void walletTransactionCreatedSignal(CryptoNote::TransactionId _transactionId);
    void walletSendTransactionCompletedSignal(CryptoNote::TransactionId _transactionId, int _error, const QString& _errorText);
    void walletSendMessageCompletedSignal(CryptoNote::TransactionId _transactionId, int _error, const QString& _errorText);
    void walletCreateDepositCompletedSignal(CryptoNote::TransactionId _transactionId, int _error, const QString& _errorText);
    void walletWithdrawDepositCompletedSignal(CryptoNote::TransactionId _transactionId, int _error, const QString& _errorText);
    void walletTransactionUpdatedSignal(CryptoNote::TransactionId _transactionId);
    void walletDepositsUpdatedSignal(const QVector<CryptoNote::DepositId>& _depositIds);

    void openWalletWithPasswordSignal(bool _error);
    void changeWalletPasswordSignal();
    void updateWalletAddressSignal(const QString& _address);
    void reloadWalletTransactionsSignal();
    void updateBlockStatusTextSignal();
    void updateBlockStatusTextWithDelaySignal();
    void isWalletEncryptedChanged();
    void isStartOnLoginEnabledChanged();
    void autoOptimizationChanged();
    void updateTORSetting();
    void showMessage(const QString& title, const QString& text);

    void requestTransactionScreen();
    void alertOnApplication();
    void isWalletOpenChanged();
    void selectedLangaugeChanged();
};

}
