#include "recipientsmodel.h"
#include <QQmlEngine>
#include <QDebug>

namespace WalletGui {

RecipientsModel::RecipientsModel(QObject *parent) : QAbstractListModel(parent)
{
    qmlRegisterInterface<RecipientsModel>("RecipientsModel");
    reset();
}

int RecipientsModel::rowCount(const QModelIndex& /*parent*/) const
{
    return m_recipients.size();
}

QVariant RecipientsModel::data(const QModelIndex &index, int role) const
{
    if (!isValidIndex(index.row())) {
        qCritical() << "invalid model index";
        return QVariant();
    }
    QVariant out;
    switch (role) {
    case Address:
        out = m_recipients.at(index.row());
        break;
    }
    return out;
}

QHash<int,QByteArray> RecipientsModel::roleNames() const
{
    static const auto roles = QHash<int, QByteArray> {
        { Address, "address" }
    };
    return roles;
}

void RecipientsModel::addUser()
{
    emit layoutAboutToBeChanged();
    m_recipients.append("");
    emit layoutChanged();
    emit rowsChanged();
}

void RecipientsModel::removeUser(int index)
{
    if (isValidIndex(index)) {
        emit layoutAboutToBeChanged();
        m_recipients.removeAt(index);
        emit layoutChanged();
        emit rowsChanged();
    } else {
        qWarning() << "Invalid index" << index;
    }
}

void RecipientsModel::setAddress(int index, const QString &addr)
{
    if (isValidIndex(index)) {
        emit layoutAboutToBeChanged();
        m_recipients[index] = addr;
        emit layoutChanged();
    } else {
        qWarning() << "Invalid index" << index;
    }
}

const QString& RecipientsModel::getAddress(int index) const
{
    return m_recipients.at(index);
}

void RecipientsModel::reset()
{
    emit layoutAboutToBeChanged();
    m_recipients.clear();
    m_recipients.append("");//one default empty entry
    emit layoutChanged();
    emit rowsChanged();
}

} //WalletGui
