// Copyright (c) 2011-2017 The Cryptonote developers
// Copyright (c) 2014-2017 XDN developers
// Copyright (c) 2016-2017 BXC developers
// Copyright (c) 2017 UltraNote developers
// Distributed under the MIT/X11 software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#pragma once

#include "PoolModel.h"
#include "qmlhelpers.h"
#include <QFrame>
#include <QTimer>

namespace WalletGui {
class Miner;

class CronData : public QObject {
    Q_OBJECT
    QML_WRITABLE_PROPERTY(QString, label, setLabel, "")
    QML_WRITABLE_PROPERTY(QString, startTime, setStartTime, "00:00")
    QML_WRITABLE_PROPERTY(QString, endTime, setEndTime, "23:59")
    QML_WRITABLE_PROPERTY(int, day, setDay, 1)
};

class CronDataModel : public QAbstractListModel {
    Q_OBJECT
    // QAbstractItemModel interface
public:
    CronDataModel(QObject* parent = nullptr)
        : QAbstractListModel(parent)
    {
        m_roles[CronDataModelRoles::CronDataRole] = "cron_data";
    }

    enum CronDataModelRoles {
        CronDataRole = 0,
    };
    Q_ENUM(CronDataModelRoles)

    int rowCount(const QModelIndex& parent) const override
    {
        return m_items.count();
    }
    QVariant data(const QModelIndex& index, int role) const override
    {
        if (!index.isValid()) {
            return QVariant();
        }

        int row = index.row();

        if (row < 0 && row >= m_items.count()) {
            return QVariant();
        }

        auto item = m_items.at(row);

        switch (role) {
        case CronDataModelRoles::CronDataRole:
            return QVariant::fromValue(item);
        default:
            return QVariant();
        }
    }
    QHash<int, QByteArray> roleNames() const override
    {
        return m_roles;
    }

    Q_INVOKABLE void addPattern(const QString& label, const QString& startTime, const QString& endTime, int day)
    {
        auto dataItem = new CronData();
        dataItem->setLabel(label);
        dataItem->setStartTime(startTime);
        dataItem->setEndTime(endTime);
        dataItem->setDay(day);

        beginInsertRows(QModelIndex(), 0, 0);
        m_items.prepend(dataItem);
        endInsertRows();
    }
    Q_INVOKABLE void removePattern(int index)
    {
        beginRemoveRows(QModelIndex(), index, index);
        m_items.removeAt(index);
        endRemoveRows();
    }

private:
    QHash<int, QByteArray> m_roles;
    QList<CronData*> m_items;
};

class MiningService : public QObject {
    Q_OBJECT
    QML_WRITABLE_PROPERTY(bool, isActive, setIsActive, false)
    QML_WRITABLE_PROPERTY(bool, isMiningActive, setIsMiningActive, false)
    QML_WRITABLE_PROPERTY(QString, status, setStatus, tr("Stopped"))
    QML_WRITABLE_PROPERTY(QStringList, statusList, setStatusList, QStringList())
    QML_CONSTANT_PROPERTY_PTR(PoolModel, poolModel)
    QML_WRITABLE_PROPERTY(int, poolIndex, setPoolIndex, 0)
    QML_WRITABLE_PROPERTY(int, maxCoreCount, setMaxCoreCount, 0)
    QML_WRITABLE_PROPERTY(int, coreCount, setCoreCount, 0)
    QML_WRITABLE_PROPERTY(bool, cronEnabled, setCronEnabled, false)
    QML_CONSTANT_PROPERTY_PTR(CronDataModel, cronDataModel)
public:
    enum MiningStatus
    {
        MINING_STARTED,
        MINING_STOPPED,
        MINING_HASHRATE,
        MINING_WAITING_SCHEDULE,
        MINING_ERROR
    };

    MiningService(QObject* _parent);
    ~MiningService() override;

    Q_INVOKABLE void addPoolClicked();
    Q_INVOKABLE void clearPoolsClicked();
    Q_INVOKABLE void startClicked();
    Q_INVOKABLE void stopClicked();

private slots:
    void checkStatus();
    void processHashRate();
private:
    QTimer _hashRateTimer;
    Miner* m_miner;
    void initCpuCoreList();
    void startMining();
    void stopMining();
    void walletClosed();
    QString getMiningStatus(MiningStatus statusIndex);
    QTimer* _cronTimer;
};

}
