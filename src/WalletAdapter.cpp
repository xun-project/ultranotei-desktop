// Copyright (c) 2011-2017 The Cryptonote developers
// Copyright (c) 2014-2017 XDN developers
// Copyright (c) 2016-2017 BXC developers
// Copyright (c) 2017 UltraNote developers
// Distributed under the MIT/X11 software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#include <QCoreApplication>
#include <QDateTime>
#include <QDebug>
#include <QLocale>
#include <QUrl>
#include <QVector>

#include <Common/Base58.h>
#include <Common/Util.h>
#include <Common/int-util.h>
#include <QQmlEngine>
#include <Wallet/LegacyKeysImporter.h>
#include <Wallet/WalletErrors.h>
#include <crypto/chacha8.h>

#include "CurrencyAdapter.h"
#include "NodeAdapter.h"
#include "Settings.h"
#include "WalletAdapter.h"

namespace WalletGui {

const quint32 MSECS_IN_HOUR = 60 * 60 * 1000;
const quint32 MSECS_IN_MINUTE = 60 * 1000;

const quint32 LAST_BLOCK_INFO_UPDATING_INTERVAL = 1 * MSECS_IN_MINUTE;
const quint32 LAST_BLOCK_INFO_WARNING_INTERVAL = 1 * MSECS_IN_HOUR;

const quint16 COMMENT_CHAR_PRICE = 100;

WalletAdapter& WalletAdapter::instance()
{
    static WalletAdapter inst;
    return inst;
}

WalletAdapter::WalletAdapter()
    : m_wallet(nullptr)
    , m_isBackupInProgress(false)
    , m_isSynchronized(false)
    , m_lastWalletTransactionId(std::numeric_limits<quint64>::max())
    , m_sentTransactionId(CryptoNote::WALLET_LEGACY_INVALID_TRANSACTION_ID)
    , m_sentMessageId(CryptoNote::WALLET_LEGACY_INVALID_TRANSACTION_ID)
    , m_depositId(CryptoNote::WALLET_LEGACY_INVALID_TRANSACTION_ID)
    , m_depositWithdrawalId(CryptoNote::WALLET_LEGACY_INVALID_TRANSACTION_ID)
{
    setObjectName("walletAdapter");
    qmlRegisterType<WalletAdapter>("WalletAdapter", 1, 0, "WalletAdapter");

	//set source for transactions notification sounds
	incomingTransactionEffect.setSource(QUrl::fromLocalFile(":/sounds/resources/sounds/poker-chip.wav"));
	outgoingTransactionEffect.setSource(QUrl::fromLocalFile(":/sounds/resources/sounds/Swoosh-1.wav"));

    // init connection settings dialog
    initConnectionMode();
    initLocalDaemonPort();

    connect(this, &WalletAdapter::walletInitCompletedSignal, this, &WalletAdapter::onWalletInitCompleted, Qt::QueuedConnection);
    connect(this, &WalletAdapter::walletSendTransactionCompletedSignal, this, &WalletAdapter::onWalletSendTransactionCompleted, Qt::QueuedConnection);
    connect(this, &WalletAdapter::updateBlockStatusTextSignal, this, &WalletAdapter::updateBlockStatusText, Qt::QueuedConnection);
    connect(this, &WalletAdapter::updateBlockStatusTextWithDelaySignal, this, &WalletAdapter::updateBlockStatusTextWithDelay, Qt::QueuedConnection);
    connect(&m_newTransactionsNotificationTimer, &QTimer::timeout, this, &WalletAdapter::notifyAboutLastTransaction);
    connect(
        this, &WalletAdapter::walletSynchronizationProgressUpdatedSignal, this, [&]() {
            if (!m_newTransactionsNotificationTimer.isActive()) {
                m_newTransactionsNotificationTimer.start();
            }
            //setup status bar
            setSynchronizationStatePlaying(true);
            setSynchronizationStateIcon("qrc:/icons/icons/sync_sprite.gif");
            setSynchronizationStateToolTip(tr("Synchronization in progress"));
        },
        Qt::QueuedConnection);

    connect(
        this, &WalletAdapter::walletSynchronizationCompletedSignal, this,
        [&](int _error, const QString& _error_text) {
            Q_UNUSED(_error_text)
            m_newTransactionsNotificationTimer.stop();
            notifyAboutLastTransaction();
            //setup status bar
            setSynchronizationStateIcon("qrc:/icons/icons/synced.png");
            setSynchronizationStatePlaying(false);
            const QString syncLabelTooltip = _error > 0 ? tr("Not synchronized") : tr("Synchronized");
            setSynchronizationStateToolTip(syncLabelTooltip);
        },
        Qt::QueuedConnection);

    connect(&NodeAdapter::instance(), &NodeAdapter::peerCountUpdatedSignal, this,
        [&](int _peerCount) {
            const QString connectionIconPath = _peerCount > 0 ? "qrc:/icons/icons/connected.png" : "qrc:/icons/icons/disconnected.png";
            setConnectionStateIcon(connectionIconPath);
            setConnectionStateToolTip(QString(tr("%1 peers").arg(_peerCount)));
        });

	connect(this, &WalletAdapter::walletTransactionCreatedSignal, this,
		&WalletAdapter::newTransactionSoundEffect, Qt::QueuedConnection);

    //setup connections for DepositTableModel
    connect(this,
        &WalletGui::WalletAdapter::reloadWalletTransactionsSignal, m_depositTableModel,
        &DepositTableModel::reloadWalletDeposits,
        Qt::QueuedConnection);
    connect(this, &WalletGui::WalletAdapter::walletTransactionCreatedSignal, m_depositTableModel,
        static_cast<void (DepositTableModel::*)(CryptoNote::TransactionId)>(&DepositTableModel::transactionCreated),
        Qt::QueuedConnection);
    connect(this, &WalletGui::WalletAdapter::walletTransactionUpdatedSignal, m_depositTableModel,
        &DepositTableModel::transactionUpdated, Qt::QueuedConnection);
    connect(this,
        &WalletGui::WalletAdapter::walletCloseCompletedSignal, m_depositTableModel,
        &DepositTableModel::reset,
        Qt::QueuedConnection);
    connect(this,
        &WalletGui::WalletAdapter::walletDepositsUpdatedSignal, m_depositTableModel,
        &DepositTableModel::depositsUpdated,
        Qt::QueuedConnection);

    //setup connections for AddressBookTableModel
    connect(this, &WalletAdapter::walletInitCompletedSignal, m_addressBookTableModel,
        &AddressBookTableModel::walletInitCompleted, Qt::QueuedConnection);
    connect(this, &WalletAdapter::walletCloseCompletedSignal, m_addressBookTableModel,
        &AddressBookTableModel::reset, Qt::QueuedConnection);

    //setup connections for TransactionsTableModel
    connect(this, &WalletAdapter::reloadWalletTransactionsSignal, m_transactionsTableModel,
        &TransactionsTableModel::reloadWalletTransactions, Qt::QueuedConnection);
    connect(this, &WalletAdapter::walletTransactionCreatedSignal, m_transactionsTableModel,
        static_cast<void (TransactionsTableModel::*)(CryptoNote::TransactionId)>(&TransactionsTableModel::appendTransaction), Qt::QueuedConnection);
    connect(this, &WalletAdapter::walletTransactionUpdatedSignal, m_transactionsTableModel,
        &TransactionsTableModel::updateWalletTransaction, Qt::QueuedConnection);
    connect(&NodeAdapter::instance(), &NodeAdapter::lastKnownBlockHeightUpdatedSignal,
        m_transactionsTableModel, &TransactionsTableModel::lastKnownHeightUpdated,
        Qt::QueuedConnection);
    connect(this, &WalletAdapter::walletCloseCompletedSignal, m_transactionsTableModel,
        &TransactionsTableModel::reset, Qt::QueuedConnection);

    //setup connections for MessagesTableModel
    connect(this, &WalletAdapter::reloadWalletTransactionsSignal, m_messagesTableModel,
        &MessagesTableModel::reloadWalletTransactions, Qt::QueuedConnection);
    connect(this, &WalletAdapter::walletTransactionCreatedSignal, m_messagesTableModel,
        static_cast<void (MessagesTableModel::*)(CryptoNote::TransactionId)>(&MessagesTableModel::appendTransaction),
        Qt::QueuedConnection);
    connect(this, &WalletAdapter::walletTransactionUpdatedSignal, m_messagesTableModel,
        &MessagesTableModel::updateWalletTransaction,
        Qt::QueuedConnection);
    connect(&NodeAdapter::instance(), &NodeAdapter::lastKnownBlockHeightUpdatedSignal,
        m_messagesTableModel,
        &MessagesTableModel::lastKnownHeightUpdated, Qt::QueuedConnection);
    connect(this, &WalletAdapter::walletCloseCompletedSignal, m_messagesTableModel,
        &MessagesTableModel::reset, Qt::QueuedConnection);

    //set connections for SendMessageModel
    connect(this, &WalletAdapter::walletSendMessageCompletedSignal, m_sendMessageModel,
        &SendMessageModel::sendMessageCompleted, Qt::QueuedConnection);

    //set connections for receive tab
    connect(this, &WalletAdapter::walletInitCompletedSignal, [&]() {
        CryptoNote::AccountKeys keys;
        getAccountKeys(keys);
        const QString privateKeys = QString::fromStdString(Tools::Base58::encode_addr(
            CurrencyAdapter::instance().getAddressPrefix(),
            std::string(reinterpret_cast<char*>(&keys), sizeof(keys))));
        setPrivateKey(privateKeys);
    });
    connect(this, &WalletAdapter::walletCloseCompletedSignal, [&]() {
        setPublicAddress("");
        setPrivateKey("");
    });
    connect(this, &WalletAdapter::updateWalletAddressSignal, [&](const QString& address) {
        setPublicAddress(address);
    });

    //set connections for send invoice tab
    connect(this, &WalletAdapter::walletSendMessageCompletedSignal, m_invoiceService, &InvoiceService::sendMessageCompleted,
        Qt::QueuedConnection);

    encryptedFlagChanged(false);
    setSynchronizationStateIcon("qrc:/icons/icons/sync_sprite.gif");
    setConnectionStateIcon("qrc:/icons/icons/disconnected.png");
    const QString connection = Settings::instance().getConnection();
    if (connection.compare("remote") == 0) {
        setRemoteModeToolTip(tr("Connected through remote node"));
        setRemoteModeIcon("qrc:/icons/icons/remote_node.svg");
    }

    connect(this, &WalletAdapter::updateTORSetting, this, &WalletAdapter::setTorSettings);
    m_newTransactionsNotificationTimer.setInterval(500);
	//QTimer::singleShot(1500, this, SLOT(updateWalletTransactions()));
}

void WalletAdapter::stopTorProcess()
{
    if (torProcess != nullptr) {
        QNetworkProxy::setApplicationProxy(QNetworkProxy::NoProxy);
        torProcess->close();
        delete torProcess;
        torProcess = nullptr;
    }
}

QString WalletAdapter::getAddress() const
{
    try {
        return m_wallet == nullptr ? QString() : QString::fromStdString(m_wallet->getAddress());
    } catch (std::system_error&) {
        return QString();
    }
}

quint64 WalletAdapter::getActualBalance() const
{
    try {
        return (m_wallet == nullptr) ? 0 : m_wallet->actualBalance();
    } catch (std::system_error&) {
        return 0;
    }
}

quint64 WalletAdapter::getPendingBalance() const
{
    try {
        return m_wallet == nullptr ? 0 : m_wallet->pendingBalance();
    } catch (std::system_error&) {
        return 0;
    }
}

quint64 WalletAdapter::getActualDepositBalance() const
{
    try {
        return m_wallet == nullptr ? 0 : m_wallet->actualDepositBalance();
    } catch (std::system_error&) {
        return 0;
    }
}

quint64 WalletAdapter::getPendingDepositBalance() const
{
    try {
        return m_wallet == nullptr ? 0 : m_wallet->pendingDepositBalance();
    } catch (std::system_error&) {
        return 0;
    }
}

void WalletAdapter::open(const QString& _password)
{
    Q_ASSERT(m_wallet == nullptr);
    Settings::instance().setEncrypted(!_password.isEmpty());
    emit isWalletEncryptedChanged();
    setStatusBarText(tr("Opening wallet"));

    m_wallet = NodeAdapter::instance().createWallet();
    m_wallet->addObserver(this);

    if (QFile::exists(Settings::instance().getWalletFile())) {
        if (Settings::instance().getWalletFile().endsWith(".keys")) {
            if (!importLegacyWallet(_password)) {
                return;
            }
        }

        if (openFile(Settings::instance().getWalletFile(), true)) {
            try {
                m_wallet->initAndLoad(m_file, _password.toStdString());
            } catch (std::system_error&) {
                closeFile();
                delete m_wallet;
                m_wallet = nullptr;
            }
        }
    } else {
        Settings::instance().setEncrypted(false);
        try {
            m_wallet->initAndGenerate("");
        } catch (std::system_error&) {
            delete m_wallet;
            m_wallet = nullptr;
        }
    }
    setIsWalletOpen(nullptr != m_wallet);
    if (m_isWalletOpen) {
        setSynchronizationStateIcon("qrc:/icons/icons/sync_sprite.gif");
        encryptedFlagChanged(Settings::instance().isEncrypted());
    }
}

void WalletAdapter::createWithKeys(const CryptoNote::AccountKeys& _keys)
{
    m_wallet = NodeAdapter::instance().createWallet();
    m_wallet->addObserver(this);
    Settings::instance().setEncrypted(false);
    setStatusBarText(tr("Importing keys"));
    m_wallet->initWithKeys(_keys, "");
}

bool WalletAdapter::isOpen() const
{
    return m_wallet != nullptr;
}

bool WalletAdapter::importLegacyWallet(const QString& _password)
{
    QString fileName = Settings::instance().getWalletFile();
    Settings::instance().setEncrypted(!_password.isEmpty());
    try {
        fileName.replace(fileName.lastIndexOf(".keys"), 5, ".wallet");
        if (!openFile(fileName, false)) {
            delete m_wallet;
            m_wallet = nullptr;
            return false;
        }

        CryptoNote::importLegacyKeys(Settings::instance().getWalletFile().toStdString(), _password.toStdString(), m_file);
        closeFile();
        Settings::instance().setWalletFile(fileName);
        return true;
    } catch (std::system_error& _err) {
        closeFile();
        if (_err.code().value() == CryptoNote::error::WRONG_PASSWORD) {
            Settings::instance().setEncrypted(true);
            Q_EMIT openWalletWithPasswordSignal(!_password.isEmpty());
        }
    } catch (std::runtime_error& _err) {
        closeFile();
    }

    delete m_wallet;
    m_wallet = nullptr;
    return false;
}

void WalletAdapter::close()
{
    Q_CHECK_PTR(m_wallet);
    save(true, true);
    lock();
    m_wallet->removeObserver(this);
    m_isSynchronized = false;
    m_newTransactionsNotificationTimer.stop();
    m_lastWalletTransactionId = std::numeric_limits<quint64>::max();
    Q_EMIT walletCloseCompletedSignal();
    QCoreApplication::processEvents();
    delete m_wallet;
    m_wallet = nullptr;
    stopTorProcess();
    unlock();
    setIsWalletOpen(false);
    setSynchronizationStateIcon(""); //hide
    setEncryptionStateIcon("");
}

bool WalletAdapter::save(bool _details, bool _cache)
{
    return save(Settings::instance().getWalletFile() + ".temp", _details, _cache);
}

bool WalletAdapter::save(const QString& _file, bool _details, bool _cache)
{
    Q_CHECK_PTR(m_wallet);
    if (openFile(_file, false)) {
        try {
            m_wallet->save(m_file, _details, _cache);
        } catch (std::system_error&) {
            closeFile();
            return false;
        }
        setStatusBarText(tr("Saving data"));
    } else {
        return false;
    }

    return true;
}

void WalletAdapter::backup(const QString& _file)
{
    if (save(_file.endsWith(".wallet") ? _file : _file + ".wallet", true, false)) {
        m_isBackupInProgress = true;
    }
}

void WalletAdapter::reset()
{
    Q_CHECK_PTR(m_wallet);
    save(false, false);
    lock();
    m_wallet->removeObserver(this);
    m_isSynchronized = false;
    m_newTransactionsNotificationTimer.stop();
    m_lastWalletTransactionId = std::numeric_limits<quint64>::max();
    Q_EMIT walletCloseCompletedSignal();
    QCoreApplication::processEvents();
    delete m_wallet;
    m_wallet = nullptr;
    unlock();
}

Q_DECL_CONSTEXPR int SECONDS_IN_MINUTE = 60;
Q_DECL_CONSTEXPR int SECONDS_IN_HOUR = 60 * SECONDS_IN_MINUTE;
Q_DECL_CONSTEXPR int SECONDS_IN_DAY = 24 * SECONDS_IN_HOUR;
Q_DECL_CONSTEXPR int SECONDS_IN_MONTH = 30 * SECONDS_IN_DAY;
Q_DECL_CONSTEXPR int SECONDS_IN_YEAR = 12 * SECONDS_IN_MONTH;

QString WalletAdapter::secondsToNativeTime(int _seconds)
{
    QString resTempate("~ %1 %2");
    if (_seconds < SECONDS_IN_MINUTE) {
        return resTempate.arg(_seconds).arg(QObject::tr("seconds"));
    } else if (_seconds < SECONDS_IN_HOUR) {
        return resTempate.arg(_seconds / SECONDS_IN_MINUTE).arg(QObject::tr("minutes"));
    } else if (_seconds < SECONDS_IN_DAY) {
        return resTempate.arg(_seconds / SECONDS_IN_HOUR).arg(QObject::tr("hours"));
    } else if (_seconds < SECONDS_IN_MONTH) {
        return resTempate.arg(_seconds / SECONDS_IN_DAY).arg(QObject::tr("days"));
    } else if (_seconds < SECONDS_IN_YEAR) {
        return resTempate.arg(_seconds / SECONDS_IN_MONTH).arg(QObject::tr("months"));
    }
    return resTempate.arg(_seconds / SECONDS_IN_YEAR).arg(QObject::tr("years"));
}

void WalletAdapter::openWallet(const QUrl& fileUrl)
{
    const QString filePath = fileUrl.toLocalFile();
    if (!filePath.isEmpty()) {
        if (isOpen()) {
            close();
        }

        setWalletFile(filePath);
        open("");
    }
}

void WalletAdapter::createWallet(const QUrl& fileUrl)
{
    QString filePath = fileUrl.toLocalFile();
    if (!filePath.isEmpty() && !filePath.endsWith(".wallet")) {
        filePath.append(".wallet");
    }

    if (!filePath.isEmpty() && !QFile::exists(filePath)) {
        if (isOpen()) {
            close();
        }

        setWalletFile(filePath);
        open("");
    } else {
        emit showMessage(tr("Error"), tr("Cannot create wallet"));
    }
}

void WalletAdapter::resetWallet()
{
    if (isOpen()) {
        reset();
        open("");
    } else {
        emit showMessage(tr("Warning"), tr("No wallet open to reset"));
    }
}

void WalletAdapter::importKey(const QString& key, const QString& filePath)
{
    const QString keyString = key.trimmed();
    QString filePathString = filePath;
    if (!filePathString.endsWith(".wallet")) {
        filePathString.append(".wallet");
    }

    uint64_t addressPrefix;
    std::string data;
    CryptoNote::AccountKeys keys;
    if (Tools::Base58::decode_addr(keyString.toStdString(), addressPrefix, data) && addressPrefix == CurrencyAdapter::instance().getAddressPrefix() && data.size() == sizeof(keys)) {
        std::memcpy(&keys, data.data(), sizeof(keys));
        if (isOpen()) {
            close();
        }

        setWalletFile(filePathString);
        createWithKeys(keys);
        qInfo() << "importKey success";
    } else {
        emit showMessage(tr("Error"), tr("Cannot import key"));
    }
}

void WalletAdapter::backupWallet(const QUrl& fileUrl)
{
    QString filePath = fileUrl.toLocalFile();
    qDebug() << "backupWallet" << filePath;
    if (!filePath.isEmpty() && !filePath.endsWith(".wallet")) {
        filePath.append(".wallet");
    }

    if (!filePath.isEmpty() && !QFile::exists(filePath)) {
        backup(filePath);
    } else {
        emit showMessage(tr("Error"), tr("Cannot backup wallet: file exists"));
    }
}

bool WalletAdapter::encryptWallet(const QString& oldPwd, const QString& newPwd)
{
    if (newPwd.isEmpty()) {
        qCritical() << "Password cannot be empty";
        return false;
    }
    const bool rc = changePassword(oldPwd, newPwd);
    emit isWalletEncryptedChanged();
    encryptedFlagChanged(rc);
    return rc;
}

void WalletAdapter::startOnLogin(bool on)
{
    if (Settings::instance().isStartOnLoginEnabled() != on) {
        Settings::instance().setStartOnLoginEnabled(on);
        emit isStartOnLoginEnabledChanged();
    }
}

void WalletAdapter::enableTor()
{
    Q_EMIT updateTORSetting();
}

bool WalletAdapter::getTorEnabled()
{
    return m_isTorEnabled;
}

bool WalletAdapter::isStartOnLoginEnabled() const
{
    return Settings::instance().isStartOnLoginEnabled();
}

QString WalletAdapter::toLocalFile(const QUrl& fileUrl) const
{
    return fileUrl.toLocalFile();
}

quint64 WalletAdapter::getTransactionCount() const
{
    Q_CHECK_PTR(m_wallet);
    try {
        return m_wallet->getTransactionCount();
    } catch (std::system_error&) {
    }

    return 0;
}

quint64 WalletAdapter::getTransferCount() const
{
    Q_CHECK_PTR(m_wallet);
    try {
        return m_wallet->getTransferCount();
    } catch (std::system_error&) {
    }

    return 0;
}

quint64 WalletAdapter::getDepositCount() const
{
    Q_CHECK_PTR(m_wallet);
    try {
        return m_wallet->getDepositCount();
    } catch (std::system_error&) {
    }

    return 0;
}

bool WalletAdapter::getTransaction(CryptoNote::TransactionId _id, CryptoNote::WalletLegacyTransaction& _transaction)
{
    Q_CHECK_PTR(m_wallet);
    try {
        return m_wallet->getTransaction(_id, _transaction);
    } catch (std::system_error&) {
    }

    return false;
}

bool WalletAdapter::getTransfer(CryptoNote::TransferId _id, CryptoNote::WalletLegacyTransfer& _transfer)
{
    Q_CHECK_PTR(m_wallet);
    try {
        return m_wallet->getTransfer(_id, _transfer);
    } catch (std::system_error&) {
    }

    return false;
}

bool WalletAdapter::getDeposit(CryptoNote::DepositId _id, CryptoNote::Deposit& _deposit)
{
    Q_CHECK_PTR(m_wallet);
    try {
        return m_wallet->getDeposit(_id, _deposit);
    } catch (std::system_error&) {
    }

    return false;
}

bool WalletAdapter::getAccountKeys(CryptoNote::AccountKeys& _keys)
{
    Q_CHECK_PTR(m_wallet);
    try {
        m_wallet->getAccountKeys(_keys);
        return true;
    } catch (std::system_error&) {
    }

    return false;
}

void WalletAdapter::encryptAttachment(QByteArray& attachment, QByteArray& encryptionKey)
{
    for (int i = 0; i < CHACHA8_KEY_SIZE; ++i) {
        encryptionKey.append(Crypto::rand<char>());
    }

    uint64_t nonce = SWAP64LE(static_cast<int64_t>(attachment.size()));
    Crypto::chacha8(10, attachment.data(), static_cast<size_t>(attachment.size()),
        reinterpret_cast<uint8_t*>(encryptionKey.data()), reinterpret_cast<uint8_t*>(&nonce),
        attachment.data());
}

void WalletAdapter::decryptAttachment(QByteArray& attachment, QByteArray& encryptionKey)
{
    uint64_t nonce = SWAP64LE(static_cast<int64_t>(attachment.size()));
    Crypto::chacha8(10, attachment.data(), static_cast<size_t>(attachment.size()),
        reinterpret_cast<uint8_t*>(encryptionKey.data()), reinterpret_cast<uint8_t*>(&nonce),
        attachment.data());
}

void WalletAdapter::sendTransaction(const QVector<CryptoNote::WalletLegacyTransfer>& _transfers, quint64 _fee, const QString& _paymentId, quint64 _mixin,
    const QVector<CryptoNote::TransactionMessage>& _messages)
{
    Q_CHECK_PTR(m_wallet);
    try {
        lock();
        Crypto::SecretKey _transactionsk;
        m_sentTransactionId = m_wallet->sendTransaction(_transactionsk, _transfers.toStdVector(), _fee, NodeAdapter::instance().convertPaymentId(_paymentId), _mixin, 0, _messages.toStdVector());
        setStatusBarText(tr("Sending transaction"));
    } catch (std::system_error&) {
        unlock();
    }
}

void WalletAdapter::sendMessage(const QVector<CryptoNote::WalletLegacyTransfer>& _transfers, quint64 _fee, quint64 _mixin,
    const QVector<CryptoNote::TransactionMessage>& _messages, quint64 _ttl)
{
    Q_CHECK_PTR(m_wallet);
    try {
        lock();
        Crypto::SecretKey _transactionsk;
        m_sentMessageId = m_wallet->sendTransaction(_transactionsk,_transfers.toStdVector(), _fee, "", _mixin, 0, _messages.toStdVector(), _ttl);
        setStatusBarText(tr("Sending messages"));
    } catch (std::system_error&) {
        unlock();
    }
}

void WalletAdapter::deposit(int _term, qreal _amount, int _fee, int _mixIn)
{
    Q_CHECK_PTR(m_wallet);
    try {
        lock();
		m_depositId = m_wallet->deposit(_term, _amount, _fee, _mixIn);
        setStatusBarText(tr("Creating deposit"));
    } catch (std::system_error&) {
        unlock();
    }
}

void WalletAdapter::withdraw()
{
    const auto& depositIds = m_depositTableModel->unlockedDepositIds();
    qDebug() << "Unlocked deposit ids" << depositIds;
    if (!depositIds.isEmpty()) {
        withdrawUnlockedDeposits(depositIds,
            static_cast<quint64>(CurrencyAdapter::instance().getMinimumFee()));
    }
}

void WalletAdapter::withdrawUnlockedDeposits(QVector<CryptoNote::DepositId> _depositIds, quint64 _fee)
{
    Q_CHECK_PTR(m_wallet);
    try {
        lock();
        m_depositWithdrawalId = m_wallet->withdrawDeposits(_depositIds.toStdVector(), _fee);
        setStatusBarText(tr("Withdrawing deposit"));
    } catch (std::system_error&) {
        unlock();
    }
}

bool WalletAdapter::changePassword(const QString& _oldPassword, const QString& _newPassword)
{
    Q_CHECK_PTR(m_wallet);
    try {
        if (m_wallet->changePassword(_oldPassword.toStdString(), _newPassword.toStdString()).value() == CryptoNote::error::WRONG_PASSWORD) {
            return false;
        }
    } catch (std::system_error&) {
        return false;
    }

    Settings::instance().setEncrypted(!_newPassword.isEmpty());
    return save(true, true);
}

void WalletAdapter::setWalletFile(const QString& _path)
{
    Q_ASSERT(m_wallet == nullptr);
    Settings::instance().setWalletFile(_path);
}

void WalletAdapter::initCompleted(std::error_code _error)
{
    if (m_file.is_open()) {
        closeFile();
    }

    Q_EMIT walletInitCompletedSignal(_error.value(), QString::fromStdString(_error.message()));
}

void WalletAdapter::onWalletInitCompleted(int _error, const QString& _errorText)
{
    switch (_error) {
    case 0: {
        Q_EMIT walletActualBalanceUpdatedSignal(m_wallet->actualBalance());
        Q_EMIT walletPendingBalanceUpdatedSignal(m_wallet->pendingBalance());
        Q_EMIT walletActualDepositBalanceUpdatedSignal(m_wallet->actualDepositBalance());
        Q_EMIT walletPendingDepositBalanceUpdatedSignal(m_wallet->pendingDepositBalance());
        Q_EMIT updateWalletAddressSignal(QString::fromStdString(m_wallet->getAddress()));
        Q_EMIT reloadWalletTransactionsSignal();
		QTimer::singleShot(300, this, SLOT(updateWalletTransactions()));
        setStatusBarText(tr("Ready"));
        QTimer::singleShot(5000, this, &WalletAdapter::updateBlockStatusText);
        if (!QFile::exists(Settings::instance().getWalletFile())) {
            save(true, true);
        }

        break;
    }
    case CryptoNote::error::WRONG_PASSWORD:
        Q_EMIT openWalletWithPasswordSignal(Settings::instance().isEncrypted());
        Settings::instance().setEncrypted(true);
        delete m_wallet;
        m_wallet = nullptr;
        break;
    default: {
        delete m_wallet;
        m_wallet = nullptr;
        break;
    }
    }
}

void WalletAdapter::saveCompleted(std::error_code _error)
{
    if (!_error && !m_isBackupInProgress) {
        closeFile();
        renameFile(Settings::instance().getWalletFile() + ".temp", Settings::instance().getWalletFile());
        setStatusBarText(tr("Ready"));
        Q_EMIT updateBlockStatusTextWithDelaySignal();
    } else if (m_isBackupInProgress) {
        m_isBackupInProgress = false;
        closeFile();
    } else {
        closeFile();
    }

    Q_EMIT walletSaveCompletedSignal(_error.value(), QString::fromStdString(_error.message()));
}

void WalletAdapter::synchronizationProgressUpdated(uint32_t _current, uint32_t _total)
{
    m_isSynchronized = false;
    setStatusBarText(QString("%1 %2/%3").arg(tr("Synchronizing")).arg(_current).arg(_total));
    Q_EMIT walletSynchronizationProgressUpdatedSignal(_current, _total);
}

void WalletAdapter::synchronizationCompleted(std::error_code _error)
{
    if (!_error) {
        m_isSynchronized = true;
        Q_EMIT updateBlockStatusTextSignal();
        Q_EMIT walletSynchronizationCompletedSignal(_error.value(), QString::fromStdString(_error.message()));
    }
}

void WalletAdapter::actualBalanceUpdated(uint64_t _actual_balance)
{
    Q_EMIT walletActualBalanceUpdatedSignal(_actual_balance);
}

void WalletAdapter::pendingBalanceUpdated(uint64_t _pending_balance)
{
    Q_EMIT walletPendingBalanceUpdatedSignal(_pending_balance);
}

void WalletAdapter::actualDepositBalanceUpdated(uint64_t _actualDepositBalance)
{
    Q_EMIT walletActualDepositBalanceUpdatedSignal(_actualDepositBalance);
}

void WalletAdapter::pendingDepositBalanceUpdated(uint64_t _pendingDepositBalance)
{
    Q_EMIT walletPendingDepositBalanceUpdatedSignal(_pendingDepositBalance);
}

void WalletAdapter::externalTransactionCreated(CryptoNote::TransactionId _transactionId)
{
    if (!m_isSynchronized) {
        m_lastWalletTransactionId = _transactionId;
    } else {
        Q_EMIT walletTransactionCreatedSignal(_transactionId);
    }
}

void WalletAdapter::sendTransactionCompleted(CryptoNote::TransactionId _transactionId, std::error_code _error)
{
    Q_ASSERT(_transactionId == m_sentTransactionId || _transactionId == m_sentMessageId || _transactionId == m_depositId || _transactionId == m_depositWithdrawalId);
    unlock();
    Q_EMIT walletSendTransactionCompletedSignal(_transactionId, _error.value(), QString::fromStdString(_error.message()));
    if (_transactionId == m_sentTransactionId) {
        m_sentTransactionId = CryptoNote::WALLET_LEGACY_INVALID_TRANSACTION_ID;
    } else if (_transactionId == m_sentMessageId) {
        Q_EMIT walletSendMessageCompletedSignal(_transactionId, _error.value(), QString::fromStdString(_error.message()));
        m_sentMessageId = CryptoNote::WALLET_LEGACY_INVALID_TRANSACTION_ID;
    } else if (_transactionId == m_depositId) {
        Q_EMIT walletCreateDepositCompletedSignal(_transactionId, _error.value(), QString::fromStdString(_error.message()));
        m_depositId = CryptoNote::WALLET_LEGACY_INVALID_TRANSACTION_ID;
    } else if (_transactionId == m_depositWithdrawalId) {
        Q_EMIT walletWithdrawDepositCompletedSignal(_transactionId, _error.value(), QString::fromStdString(_error.message()));
        m_depositWithdrawalId = CryptoNote::WALLET_LEGACY_INVALID_TRANSACTION_ID;
    }

    Q_EMIT requestTransactionScreen();
    Q_EMIT updateBlockStatusTextWithDelaySignal();
}

void WalletAdapter::onWalletSendTransactionCompleted(CryptoNote::TransactionId _transactionId, int _error, const QString& _errorText)
{
    CryptoNote::WalletLegacyTransaction transaction;
    if (!this->getTransaction(_transactionId, transaction)) {
        return;
    }

    Q_EMIT walletTransactionCreatedSignal(_transactionId);

    save(true, true);
}

void WalletAdapter::transactionUpdated(CryptoNote::TransactionId _transactionId)
{
    Q_EMIT walletTransactionUpdatedSignal(_transactionId);
}

void WalletAdapter::depositsUpdated(const std::vector<CryptoNote::DepositId>& _depositIds)
{
    Q_EMIT walletDepositsUpdatedSignal(QVector<CryptoNote::DepositId>::fromStdVector(_depositIds));
}

void WalletAdapter::lock()
{
    m_mutex.lock();
}

void WalletAdapter::unlock()
{
    m_mutex.unlock();
}

bool WalletAdapter::openFile(const QString& _file, bool _readOnly)
{
    lock();
    m_file.open(_file.toStdString(), std::ios::binary | (_readOnly ? std::ios::in : (std::ios::out | std::ios::trunc)));
    if (!m_file.is_open()) {
        unlock();
    }

    return m_file.is_open();
}

void WalletAdapter::closeFile()
{
    m_file.close();
    unlock();
}

void WalletAdapter::notifyAboutLastTransaction()
{
    if (m_lastWalletTransactionId != std::numeric_limits<quint64>::max()) {
        Q_EMIT walletTransactionCreatedSignal(m_lastWalletTransactionId);
        m_lastWalletTransactionId = std::numeric_limits<quint64>::max();
    }
}

void WalletAdapter::renameFile(const QString& _oldName, const QString& _newName)
{
    Q_ASSERT(QFile::exists(_oldName));
    QFile::remove(_newName);
    QFile::rename(_oldName, _newName);
}

void WalletAdapter::updateBlockStatusText()
{
    if (m_wallet == nullptr) {
        return;
    }

    const QDateTime currentTime = QDateTime::currentDateTimeUtc();
    const QDateTime blockTime = NodeAdapter::instance().getLastLocalBlockTimestamp();
    quint64 blockAge = blockTime.msecsTo(currentTime);
    const QString warningString = blockTime.msecsTo(currentTime) < LAST_BLOCK_INFO_WARNING_INTERVAL ? "" : QString("  Warning: last block was received %1 hours %2 minutes ago").arg(blockAge / MSECS_IN_HOUR).arg(blockAge % MSECS_IN_HOUR / MSECS_IN_MINUTE);
    setStatusBarText(QString(tr("Wallet synchronized. Height: %1  |  Time (UTC): %2%3")).arg(NodeAdapter::instance().getLastLocalBlockHeight()).arg(QLocale(QLocale::English).toString(blockTime, "dd MMM yyyy, HH:mm:ss")).arg(warningString));

    QTimer::singleShot(LAST_BLOCK_INFO_UPDATING_INTERVAL,
        this, &WalletAdapter::updateBlockStatusText);
}

void WalletAdapter::updateWalletTransactions()
{
	Q_EMIT reloadWalletTransactionsSignal();
}

void WalletAdapter::newTransactionSoundEffect(CryptoNote::TransactionId _transactionId)
{
	CryptoNote::WalletLegacyTransaction transaction;
	if (!this->getTransaction(_transactionId, transaction)) {
		return;
	}
	transaction.totalAmount < 0 ? outgoingTransactionEffect.play() : incomingTransactionEffect.play();
}

void WalletAdapter::setTorSettings()
{
    if (WalletAdapter::instance().getTorEnabled()) {
        torProcess = new QProcess();
        QString program;
        program = "tor";
#ifdef Q_OS_LINUX
        program = "tor";
#endif
#ifdef Q_OS_MACOS
        if (QFile::exists("/Applications/tor")) {
            program = "/Applications/tor";
        } else {
            program = "tor";
        }

#endif
#ifdef Q_OS_WIN
        program = "./tor";
#endif
        torProcess->start(program);
        // here we can implement some kind of control:
        /*
                while(torProcess->waitForReadyRead()){
                    QString state;
                    state+=torProcess->readAll();
                    QMessageBox mb;
                    mb.setText(state);
                    mb.exec();
                }

                torProcess->waitForReadyRead();
                QString state;
                state+=torProcess->readAll();
                QMessageBox mb;
                mb.setText(state);
                mb.exec();

        */
        QNetworkProxy proxy;
        proxy.setType(QNetworkProxy::Socks5Proxy);
        proxy.setHostName("127.0.0.1");
        proxy.setPort(9050);
        // proxy.setUser("username");
        // proxy.setPassword("password");
        QNetworkProxy::setApplicationProxy(proxy);
    } else {
        stopTorProcess();
    }
}


void WalletAdapter::updateBlockStatusTextWithDelay()
{
    QTimer::singleShot(5000, this, SLOT(updateBlockStatusText()));
}

bool WalletAdapter::isWalletEncrypted() const
{
    return Settings::instance().isEncrypted();
}

void WalletAdapter::initLocalDaemonPort()
{
    m_localDaemonPort = Settings::instance().getCurrentLocalDaemonPort();
    if (m_localDaemonPort == 0) {
        m_localDaemonPort = CryptoNote::RPC_DEFAULT_PORT;
    }
    emit localDaemonPortChanged();
}

void WalletAdapter::setLocalDaemonPort()
{
    Settings::instance().setCurrentLocalDaemonPort(static_cast<quint16>(m_localDaemonPort));
}

void WalletAdapter::initConnectionMode()
{
    const QString connection = Settings::instance().getConnection();
    m_connectionMode = CONNECTION_MODE_UNKNOWN;
    if ("auto" == connection) {
        m_connectionMode = CONNECTION_MODE_AUTO;
    } else if ("embedded" == connection) {
        m_connectionMode = CONNECTION_MODE_EMBEDDED;
    } else if ("local" == connection) {
        m_connectionMode = CONNECTION_MODE_LOCAL;
    } else if ("remote" == connection) {
        m_connectionMode = CONNECTION_MODE_REMOTE;
    }
    emit connectionModeChanged();
}

void WalletAdapter::setConnectionMode()
{
    QString connection;
    switch (m_connectionMode) {
    case CONNECTION_MODE_AUTO:
        connection = "auto";
        break;
    case CONNECTION_MODE_EMBEDDED:
        connection = "embedded";
        break;
    case CONNECTION_MODE_LOCAL:
        connection = "local";
        break;
    case CONNECTION_MODE_REMOTE:
        connection = "remote";
        break;
    default:;
    }
    Settings::instance().setConnection(connection);
}

void WalletAdapter::saveConnectionSettings()
{
    setConnectionMode();
    setLocalDaemonPort();
    if (nullptr != m_nodeModel) {
        m_nodeModel->setRemoteNode();
    }
}

void WalletAdapter::encryptedFlagChanged(bool encrypted)
{
    const QString encryptionIconPath = encrypted ? "qrc:/icons/icons/lock_closed.png" : "qrc:/icons/icons/lock_open.png";
    setEncryptionStateIcon(encryptionIconPath);
    const QString encryptionLabelTooltip = encrypted ? tr("Encrypted") : tr("Not encrypted");
    setEncryptionStateToolTip(encryptionLabelTooltip);
}

void WalletAdapter::send(const QString& payTo, const QString& paymentId,
    const QString& label, const QString& comment,
	qreal amount, int fee, int anonLevel)
{
    QVector<CryptoNote::WalletLegacyTransfer> walletTransfers;
    CryptoNote::WalletLegacyTransfer walletTransfer;
    walletTransfer.address = payTo.toStdString();

    walletTransfer.amount = amount;

    walletTransfers.push_back(walletTransfer);
    if (!label.isEmpty()) {
        m_addressBookTableModel->addAddress(label, payTo);
    }

    QVector<CryptoNote::TransactionMessage> walletMessages;
    if (!comment.isEmpty()) {
        walletMessages.append(CryptoNote::TransactionMessage { comment.toStdString(),
            payTo.toStdString() });
    }

    sendTransaction(walletTransfers, static_cast<quint64>(fee), paymentId,
        static_cast<quint64>(anonLevel), walletMessages);
}
quint16 WalletAdapter::getCommentCharPrice()
{
	return COMMENT_CHAR_PRICE;
}
}
