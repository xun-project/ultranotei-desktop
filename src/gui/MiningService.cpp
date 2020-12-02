// Copyright (c) 2011-2017 The Cryptonote developers
// Copyright (c) 2014-2017 XDN developers
// Copyright (c) 2016-2017 BXC developers
// Copyright (c) 2017 UltraNote developers
// Distributed under the MIT/X11 software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#include "MiningService.h"
#include "MainWindow.h"
#include "Miner.h"
#include "NewPoolDialog.h"
#include "Settings.h"
#include "WalletAdapter.h"
#include <QThread>
#include <QUrl>

namespace WalletGui {

const quint32 HASHRATE_TIMER_INTERVAL = 1000;

MiningService::MiningService(QObject* _parent)
    : QObject(_parent)
    , m_miner(nullptr)
    , m_poolModel(new PoolModel(this))
    , _cronTimer(new QTimer(this))
{
    initCpuCoreList();

    _cronTimer->setInterval(1000);
    _cronTimer->setSingleShot(false);
    _hashRateTimer.setInterval(HASHRATE_TIMER_INTERVAL);
    _hashRateTimer.setSingleShot(false);
    connect(_cronTimer, &QTimer::timeout, this, &MiningService::checkStatus);
    connect(&_hashRateTimer, &QTimer::timeout, this, &MiningService::processHashRate);
}

MiningService::~MiningService()
{
    _cronTimer->stop();
    _cronTimer->deleteLater();
    stopMining();
}

void MiningService::processHashRate()
{
    quint32 hashRate = m_miner->getHashRate();
    if (hashRate == 0) {
        return;
    }

    setStatus(getMiningStatus(MINING_HASHRATE).arg(hashRate));
}

void MiningService::initCpuCoreList()
{
    int cpuCoreCount = QThread::idealThreadCount();
    if (cpuCoreCount == -1) {
        cpuCoreCount = 2;
    }

    setMaxCoreCount(cpuCoreCount);
    setCoreCount((cpuCoreCount - 1) / 2);
}

void MiningService::startMining()
{
    Q_ASSERT(m_miner == nullptr);
    QUrl poolUrl = QUrl::fromUserInput(m_poolModel->index(m_poolIndex, 0).data(PoolModel::ROLE_HOST).toString());
    poolUrl.setPort(m_poolModel->index(m_poolIndex, 0).data(PoolModel::ROLE_PORT).toInt());

    qDebug() << "Starting with pool: " << poolUrl << " Core count: " << m_coreCount;

    m_miner = new Miner(this, poolUrl.host(), poolUrl.port(), WalletAdapter::instance().getAddress());
    connect(m_miner, &Miner::socketErrorSignal, this, [this](const QString& _errorString) {
        setStatus(getMiningStatus(MINING_ERROR).arg(_errorString));
    });

    m_miner->start(m_coreCount);
    _hashRateTimer.start();
    setStatus(getMiningStatus(MINING_STARTED));
    setIsMiningActive(true);
}

void MiningService::stopMining()
{
    if (m_miner == nullptr) {
        return;
    }

    _hashRateTimer.stop();
    m_miner->stop();
    m_miner->deleteLater();
    m_miner = nullptr;
    setStatus(getMiningStatus(MINING_STOPPED));
    setIsMiningActive(false);
}

void MiningService::walletClosed()
{
    stopMining();
}

QString MiningService::getMiningStatus(MiningStatus statusIndex)
{
    QString status;
    if (!m_statusList.isEmpty())
    {
        status = m_statusList.at(statusIndex);
    }
    else
    {
        switch (statusIndex)
        {
        case MINING_STARTED:
            status = "Started";
            break;
        case MINING_STOPPED:
            status = "Stopped";
            break;
        case MINING_HASHRATE:
            status = "Hashrate: %1 H/s";
            break;
        case MINING_WAITING_SCHEDULE:
            status = "Waiting for the schedule...";
            break;
        case MINING_ERROR:
            status = "Error: %1";
            break;
        default:
            status = "Mining status error";
            break;
        }
    }
    return status;
}

void MiningService::addPoolClicked()
{
    if (Settings::instance().isTrackingMode())
    {
        emit WalletAdapter::instance().showMessage(tr("Tracking Wallet"), tr("This is a tracking wallet. This action is not available."));
        return;
    }
    else {
    NewPoolDialog dlg(&MainWindow::instance());
    if (dlg.exec() == QDialog::Accepted) {
        QString host = dlg.getHost();
        quint16 port = dlg.getPort();
        if (host.isEmpty()) {
            return;
        }

        m_poolModel->addPool(host, port);
    }
    }
}

void MiningService::clearPoolsClicked()
{
    m_poolModel->clearPools();
}

void MiningService::startClicked()
{
    if (Settings::instance().isTrackingMode())
    {
        emit WalletAdapter::instance().showMessage(tr("Tracking Wallet"), tr("This is a tracking wallet. This action is not available."));
        return;
    }
    else {
    setIsActive(true);
    if(m_cronEnabled) {
        _cronTimer->start();
        checkStatus();
    } else {
        startMining();
    }
    }
}

void MiningService::stopClicked()
{
    setIsActive(false);
    if(m_cronEnabled) {
        _cronTimer->stop();
    }
    stopMining();
}

void MiningService::checkStatus()
{
    bool scheduleContainsTriggeredTime = false;

    const auto currentTime = QDateTime::currentDateTime();

    for (int i = 0; i < m_cronDataModel->rowCount(QModelIndex()); i++) {
        const auto cronDataItem = m_cronDataModel->index(i, 0).data(Qt::DisplayRole).value<CronData*>();

        auto startTime = QDateTime::currentDateTime();
        startTime.setTime(QTime::fromString(cronDataItem->startTime(), "hh:mm"));

        auto endTime = QDateTime::currentDateTime();
        endTime.setTime(QTime::fromString(cronDataItem->endTime(), "hh:mm"));

        if ((currentTime >= startTime && currentTime <= endTime) && (currentTime.date().dayOfWeek() == (cronDataItem->day() + 1))) {
            scheduleContainsTriggeredTime = true;
            break;
        }
    }

    if (scheduleContainsTriggeredTime) {
        if (!m_isMiningActive) {
            startMining();
        }
    } else {
        setStatus(m_isActive ? getMiningStatus(MINING_WAITING_SCHEDULE) : getMiningStatus(MINING_STOPPED));
        if (m_isMiningActive) {
            stopMining();
        }
    }
}

}
