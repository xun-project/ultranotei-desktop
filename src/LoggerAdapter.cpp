// Copyright (c) 2011-2017 The Cryptonote developers
// Copyright (c) 2014-2017 XDN developers
// Copyright (c) 2016-2017 BXC developers
// Copyright (c) 2017 UltraNote developers
// Distributed under the MIT/X11 software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#include "LoggerAdapter.h"
#include "Settings.h"

namespace WalletGui {

LoggerAdapter& LoggerAdapter::instance() {
  static LoggerAdapter inst;
  return inst;
}

void LoggerAdapter::init() {
  common::JsonValue loggerConfiguration(common::JsonValue::OBJECT);
  int64_t logLevel =
    #ifdef DEBUG
	  logging::TRACE
	#else
		logging::INFO
	#endif
  ;
  loggerConfiguration.insert("globalLevel", logLevel);
  common::JsonValue& cfgLoggers = loggerConfiguration.insert("loggers", common::JsonValue::ARRAY);
  common::JsonValue& fileLogger = cfgLoggers.pushBack(common::JsonValue::OBJECT);
  fileLogger.insert("type", "file");
  fileLogger.insert("filename", Settings::instance().getDataDir().absoluteFilePath("UltraNoteInfinity.log").toStdString());
  fileLogger.insert("level", logLevel);
  m_logManager.configure(loggerConfiguration);
}

logging::LoggerManager& LoggerAdapter::getLoggerManager() {
  return m_logManager;
}

}
