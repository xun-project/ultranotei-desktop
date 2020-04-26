// Copyright (c) 2011-2015 The Cryptonote developers
// Copyright (c) 2015 XDN developers
// Copyright (c) 2018 UltraNote developers
// Distributed under the MIT/X11 software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#pragma once

#include "qmlhelpers.h"
#include <QStringListModel>

namespace WalletGui {

class NodeModel : public QStringListModel {
  Q_OBJECT
  QML_WRITABLE_PROPERTY(int, currentIndex, setCurrentIndex, -1)
public:
  enum Roles {
    ROLE_HOST = Qt::UserRole, ROLE_PORT
  };

  NodeModel(QObject* _parent);
  ~NodeModel();

  Q_INVOKABLE void addNode(const QString& _host, quint16 _port);
  void setNodesList();
  void setRemoteNode();

  QVariant data(const QModelIndex& _index, int _role) const Q_DECL_OVERRIDE;
  Qt::ItemFlags flags(const QModelIndex& _index) const Q_DECL_OVERRIDE;
  QVariant headerData(int _section, Qt::Orientation _orientation, int _role) const Q_DECL_OVERRIDE;
  bool setData(const QModelIndex& _index, const QVariant& _value, int _role = Qt::EditRole) Q_DECL_OVERRIDE;
};

}
