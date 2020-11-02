#pragma once

#include "qmlhelpers.h"
#include <QAbstractTableModel>
#include <QJsonArray>

namespace WalletGui {

class AddressBookTableModel : public QAbstractTableModel {
    Q_OBJECT
    QML_WRITABLE_PROPERTY(QStringList, columnNameList, setColumnNameList, QStringList())

public:
    enum ColumnName {
        Label = 0,
        Address,
        Count
    };
    explicit AddressBookTableModel(QObject* parent = nullptr);
    int rowCount(const QModelIndex& index = QModelIndex()) const override;
    int columnCount(const QModelIndex& index = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;
    Q_INVOKABLE QString columnName(int index);
    Q_INVOKABLE void addAddress(const QString& _label, const QString& _address);
    Q_INVOKABLE void removeAddress(int _row);
    void walletInitCompleted(int _error, const QString& _error_text);
    void reset();
    QString selectedLabel();
    QString selectedAddress();

private:
    QML_READABLE_PROPERTY(int, rowCount, setRowCount, 0)
    QML_CONSTANT_PROPERTY(int, colCount, ColumnName::Count)
    QML_WRITABLE_PROPERTY(int, selectedRow, setSelectedRow, -1)
    Q_PROPERTY(QString selectedLabel READ selectedLabel NOTIFY selectedRowChanged)
    Q_PROPERTY(QString selectedAddress READ selectedAddress NOTIFY selectedRowChanged)

private:
    void saveAddressBook();
    QString getColumnName(ColumnName columnName);
    QJsonArray m_addressBook;
};

} // WalletGui
