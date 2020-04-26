#pragma once

#include <QAbstractListModel>
#include <QList>

namespace WalletGui {

class AttachmentsModel : public QAbstractListModel
{
    Q_OBJECT
public:
    enum AttachmentsRoles {
        FileName = Qt::UserRole + 1
    };
    explicit AttachmentsModel(QObject *parent = nullptr);
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int,QByteArray> roleNames() const override;

    Q_INVOKABLE void appendFile(const QUrl &fileName);
    Q_INVOKABLE void removeFile(int index);

    const QString& getFileName(int index) const { return m_attachments.at(index); }
    void reset();
private:
    bool isValidIndex(int index) const {
        return ((index >= 0) && (index < m_attachments.count()));
    }
    QList<QString> m_attachments;
};

} // WalletGui
