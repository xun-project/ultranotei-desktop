// Copyright (c) 2011-2017 The Cryptonote developers
// Copyright (c) 2014-2017 XDN developers
// Copyright (c) 2016-2017 BXC developers
// Copyright (c) 2017 UltraNote developers
// Distributed under the MIT/X11 software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#pragma once

#include "Logging/LoggerManager.h"

namespace WalletGui {

class LoggerAdapter {

public:
  static LoggerAdapter& instance();
  void init();
  logging::LoggerManager& getLoggerManager();

private:
  logging::LoggerManager m_logManager;

  LoggerAdapter() = default;
  ~LoggerAdapter() = default;
};

}
