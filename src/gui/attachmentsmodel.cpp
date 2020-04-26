#include "attachmentsmodel.h"
#include <QQmlEngine>
#include <QDebug>

namespace WalletGui {

AttachmentsModel::AttachmentsModel(QObject *parent) : QAbstractListModel(parent)
{
    qmlRegisterInterface<AttachmentsModel>("AttachmentsModel");
}

int AttachmentsModel::rowCount(const QModelIndex& /*parent*/) const
{
    return m_attachments.size();
}

QVariant AttachmentsModel::data(const QModelIndex &index, int role) const
{
    if (!isValidIndex(index.row())) {
        qCritical() << "invalid model index";
        return QVariant();
    }
    QVariant out;
    switch (role) {
    case FileName:
        out = m_attachments.at(index.row());
        break;
    }
    return out;
}

QHash<int,QByteArray> AttachmentsModel::roleNames() const
{
    static const auto roles = QHash<int, QByteArray> {
        { FileName, "fileName" }
    };
    return roles;
}

void AttachmentsModel::appendFile(const QUrl &fileName)
{
    const auto localFileName = fileName.toLocalFile();
    if (!m_attachments.contains(localFileName)) {
        emit layoutAboutToBeChanged();
        m_attachments.append(localFileName);
        emit layoutChanged();
    } else {
        qWarning() << "File already attached" << fileName;
    }
}

void AttachmentsModel::removeFile(int index)
{
    if (isValidIndex(index)) {
        emit layoutAboutToBeChanged();
        m_attachments.removeAt(index);
        emit layoutChanged();
    } else {
        qWarning() << "Invalid index" << index;
    }
}

void AttachmentsModel::reset()
{
    emit layoutAboutToBeChanged();
    m_attachments.clear();
    emit layoutChanged();
}

} // WalletGui
