#pragma once

#include <QAbstractListModel>
#include <QList>

namespace WalletGui {

class RecipientsModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int rows READ rowCount NOTIFY rowsChanged)
public:
    enum AttachmentsRoles {
        Address = Qt::UserRole + 1
    };
    explicit RecipientsModel(QObject *parent = nullptr);
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int,QByteArray> roleNames() const override;

    Q_INVOKABLE void addUser();
    Q_INVOKABLE void removeUser(int index);
    Q_INVOKABLE void setAddress(int index, const QString &addr);
    const QString& getAddress(int index) const;
    void reset();
signals:
    void rowsChanged();
private:
    bool isValidIndex(int index) const {
        return ((index >= 0) && (index < m_recipients.count()));
    }
    QList<QString> m_recipients;
};

} //WalletGui
