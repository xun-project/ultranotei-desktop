// Copyright (c) 2011-2015 The Cryptonote developers
// Copyright (c) 2015 XDN developers
// Copyright (c) 2018 UltraNote developers
// Distributed under the MIT/X11 software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#include "NodeModel.h"
#include "Settings.h"
#include <QUrl>
#include <QQmlEngine>

namespace WalletGui {

NodeModel::NodeModel(QObject* _parent) : QStringListModel(_parent) {
  qmlRegisterInterface<NodeModel>("NodeModel");
  const auto nodesList = Settings::instance().getRPCNodesList();
  setStringList(nodesList);

  const QString currentRemoteNode = Settings::instance().getCurrentRemoteNode();
  const int curIndex = nodesList.indexOf(currentRemoteNode);
  setCurrentIndex(curIndex);
}

NodeModel::~NodeModel() {
}

void NodeModel::addNode(const QString& _host, quint16 _port) {
  insertRow(rowCount());
  setData(index(rowCount() - 1, 0), QString("%1:%2").arg(_host).arg(_port));
}

QVariant NodeModel::data(const QModelIndex& _index, int _role) const {
  if (!_index.isValid()) {
    return QVariant();
  }

  const auto strList = stringList();
  if ((0 > _index.row()) && (_index.row() >= strList.size())) {
    return QVariant();
  }
  switch (_role) {
  case ROLE_HOST:
    return QUrl::fromUserInput(strList.at(_index.row())).host();
  case ROLE_PORT:
    return QUrl::fromUserInput(strList.at(_index.row())).port();
  default:
    break;
  }

  return QStringListModel::data(_index, _role);
}

Qt::ItemFlags NodeModel::flags(const QModelIndex& _index) const {
  Q_UNUSED(_index)
  return (Qt::ItemIsEnabled | Qt::ItemNeverHasChildren | Qt::ItemIsSelectable);
}

QVariant NodeModel::headerData(int _section, Qt::Orientation _orientation, int _role) const {
  Q_UNUSED(_section)
  if (_orientation != Qt::Horizontal || _role != Qt::DisplayRole) {
    return QVariant();
  }

  return tr("Node URL");
}

bool NodeModel::setData(const QModelIndex& _index, const QVariant& _value, int _role) {
  bool res = QStringListModel::setData(_index, _value, _role);
  Settings::instance().setRPCNodesList(stringList());
  return res;
}

void NodeModel::setRemoteNode() {
    const auto strList = stringList();
    if ((0 <= m_currentIndex) && (m_currentIndex < strList.size())) {
        Settings::instance().setCurrentRemoteNode(strList.at(m_currentIndex));
    }
}

}
