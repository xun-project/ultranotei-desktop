#include "addressbooktablemodel.h"
#include "Settings.h"
#include "WalletAdapter.h"
#include <QFile>
#include <QJsonDocument>
#include <QQmlEngine>

namespace WalletGui {

AddressBookTableModel::AddressBookTableModel(QObject* parent)
    : QAbstractTableModel(parent)
{
    qmlRegisterType<AddressBookTableModel>("AddressBookTableModel", 1, 0,
        "AddressBookTableModel");
}

int AddressBookTableModel::rowCount(const QModelIndex& index) const
{
    Q_UNUSED(index)
    return m_addressBook.size();
}

int AddressBookTableModel::columnCount(const QModelIndex& index) const
{
    Q_UNUSED(index)
    return ColumnName::Count;
}

QVariant AddressBookTableModel::data(const QModelIndex& index, int role) const
{

    const int col = index.column();
    const int row = index.row();

    if (row > (m_addressBook.size() - 1)) {
        return "";
    }

    const QJsonObject obj = m_addressBook.at(row).toObject();
    QVariant out;
    switch (role) {
    case Qt::DisplayRole:
        switch (col) {
        case Label:
            out = obj.value("label");
            break;
        case Address:
            out = obj.value("address");
            break;
        }
        break;
    default:;
    }

    return out;
}

QHash<int, QByteArray> AddressBookTableModel::roleNames() const
{
    static const auto roles = QHash<int, QByteArray> {
        { Qt::DisplayRole, "display" }
    };
    return roles;
}

QString AddressBookTableModel::columnName(int index)
{
    QString name;
    switch (index) {
    case ColumnName::Label:
        name = getColumnName(Label);
        break;
    case ColumnName::Address:
        name = getColumnName(Address);
        break;
    }
    return name;
}

void AddressBookTableModel::addAddress(const QString& _label, const QString& _address)
{
    auto labelDuplicateFound = false;
    for(const QJsonValue& pair : m_addressBook) {
        QJsonObject obj = pair.toObject();
        if(pair["label"].toString() == _label) {
            labelDuplicateFound = true;
            break;
        }
    }

    if(labelDuplicateFound) {
        qDebug() << "The address with the requested label" << _label << "already exists";
        return;
    }

    qDebug() << "Label: " << _label << _address;
    emit layoutAboutToBeChanged();
    QJsonObject newAddress;
    newAddress.insert("label", _label);
    newAddress.insert("address", _address);
    m_addressBook.append(newAddress);
    emit layoutChanged();
    setRowCount(m_addressBook.size());
    saveAddressBook();
    qDebug() << m_addressBook;
}

void AddressBookTableModel::removeAddress(int _row)
{
    if (_row > m_addressBook.size() - 1) {
        return;
    }
    emit layoutAboutToBeChanged();
    m_addressBook.removeAt(_row);
    emit layoutChanged();
    setRowCount(m_addressBook.size());
    saveAddressBook();
}

void AddressBookTableModel::walletInitCompleted(int _error, const QString& _error_text)
{
    Q_UNUSED(_error_text)
    if (!_error) {
        QFile addressBookFile(Settings::instance().getAddressBookFile());
        if (addressBookFile.open(QIODevice::ReadOnly)) {
            QByteArray file_content = addressBookFile.readAll();
            QJsonDocument doc = QJsonDocument::fromJson(file_content);
            if (!doc.isNull()) {
                m_addressBook = doc.array();
            }
            addressBookFile.close();
            emit layoutAboutToBeChanged();
            emit layoutChanged();
            setRowCount(m_addressBook.size());
        }
    }
}

void AddressBookTableModel::reset()
{
    emit layoutAboutToBeChanged();
    while (!m_addressBook.empty()) {
        m_addressBook.removeFirst();
    }
    emit layoutChanged();
    setRowCount(m_addressBook.size());
}

void AddressBookTableModel::saveAddressBook()
{
    QFile addressBookFile(Settings::instance().getAddressBookFile());
    if (addressBookFile.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        QByteArray file_content = QJsonDocument(m_addressBook).toJson(QJsonDocument::Compact);
        addressBookFile.write(file_content);
        addressBookFile.close();
    }
}

QString AddressBookTableModel::selectedLabel()
{
    QString label;
    if ((0 <= m_selectedRow) && (m_selectedRow < m_addressBook.size())) {
        const QJsonObject obj = m_addressBook.at(m_selectedRow).toObject();
        label = obj["label"].toString();
    }
    return label;
}

QString AddressBookTableModel::selectedAddress()
{
    QString address;
    if ((0 <= m_selectedRow) && (m_selectedRow < m_addressBook.size())) {
        const QJsonObject obj = m_addressBook.at(m_selectedRow).toObject();
        address = obj["address"].toString();
    }
    return address;
}

QString AddressBookTableModel::getColumnName(ColumnName columnName)
{
    QString headerName;

    if (!m_columnNameList.isEmpty())
    {
        headerName = m_columnNameList.at(columnName);
    }
    else
    {
        switch (columnName)
        {
        case Label:
            headerName = "Label";
            break;
        case Address:
            headerName = "Address";
            break;
        default:
            break;
        }
    }

    return headerName;
}

} // WalletGui
