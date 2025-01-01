// Copyright (c) 2011-2017 The Cryptonote developers
// Copyright (c) 2014-2017 XDN developers
// Copyright (c) 2016-2017 BXC developers
// Copyright (c) 2017 UltraNote developers
// Distributed under the MIT/X11 software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#pragma once

#include <QDir>
#include <QJsonObject>
#include <QObject>

namespace WalletGui {

class CommandLineParser;

class Settings : public QObject {
  Q_OBJECT
  Q_DISABLE_COPY(Settings)

public:
  static Settings& instance();

  void setCommandLineParser(CommandLineParser* _cmd_line_parser);
  void load();
  QStringList resetPools();
  bool hasAllowLocalIpOption() const;
  bool hasHideMyPortOption() const;
  bool isTestnet() const;
  QDir getDataDir() const;
  QString getP2pBindIp() const;
  quint16 getLocalRpcPort() const;
  quint16 getP2pBindPort() const;
  quint16 getP2pExternalPort() const;
  QStringList getExclusiveNodes() const;
  QStringList getPeers() const;
  QStringList getPriorityNodes() const;
  QStringList getSeedNodes() const;

  QString getWalletFile() const;
  QString getAddressBookFile() const;
  QString getUnreadMessagesFile() const;
  QStringList getMiningPoolList() const;
  QString getAutoOptimizationStatus() const;
  void setAutoOptimizationStatus(const QString& _status);
  quint64 getOptimizationInterval() const;
  bool isTrackingMode() const;
  bool isEncrypted() const;
  bool isSoundEnabled() const;
  Q_INVOKABLE QString getVersion() const;
  QString getConnection() const;
  QStringList getRPCNodesList() const;
  quint16 getCurrentLocalDaemonPort() const;
  QString getCurrentRemoteNode() const;
  bool isStartOnLoginEnabled() const;
  QString getLanguage() const;
#ifdef Q_OS_WIN
  bool isMinimizeToTrayEnabled() const;
  bool isCloseToTrayEnabled() const;
#endif
  QString getFiatSymbol() const;

  void setTrackingMode(bool _tracking);
  void setWalletFile(const QString& _file);
  void setEncrypted(bool _encrypted);
  void setSoundEnabled(bool _enabled);
  void setCurrentTheme(const QString& _theme);
  void setStartOnLoginEnabled(bool _enable);
  void setMiningPoolList(const QStringList& _miningPoolList);
  void setConnection(const QString& _connection);
  void setCurrentLocalDaemonPort(const quint16& _daemonPort);
  void setCurrentRemoteNode(const QString& _remoteNode);
  void setRPCNodesList(const QStringList& _RPCNodesList);
  void setFiatSymbol(const QString &val);
  void setLanguage(const QString& _language);
#ifdef Q_OS_WIN
  void setMinimizeToTrayEnabled(bool _enable);
  void setCloseToTrayEnabled(bool _enable);
#endif

private:
  QJsonObject m_settings;
  QString m_addressBookFile;
  QString m_UnreadMessagesFile;
  QString m_connectionMode;
  QString m_daemonPort; 
 CommandLineParser* m_cmdLineParser;

  Settings();
  ~Settings() = default;

  void saveSettings() const;
};

}
