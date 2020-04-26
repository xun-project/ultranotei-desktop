// Copyright (c) 2011-2017 The Cryptonote developers
// Copyright (c) 2014-2017 XDN developers
// Copyright (c) 2016-2017 BXC developers
// Copyright (c) 2017 UltraNote developers
// Distributed under the MIT/X11 software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#include "CurrencyAdapter.h"
#include "CryptoNoteWalletConfig.h"
#include "LoggerAdapter.h"
#include "Settings.h"
#include "NodeAdapter.h"

namespace WalletGui {

CurrencyAdapter& CurrencyAdapter::instance() {
  static CurrencyAdapter inst;
  return inst;
}

CurrencyAdapter::CurrencyAdapter() : m_currency(CryptoNote::CurrencyBuilder(LoggerAdapter::instance().getLoggerManager()).testnet(Settings::instance().isTestnet()).currency()) {
    setObjectName("currencyAdapter");
}

const CryptoNote::Currency& CurrencyAdapter::getCurrency() {
  return m_currency;
}

int CurrencyAdapter::getNumberOfDecimalPlaces() const {
  return static_cast<int>(m_currency.numberOfDecimalPlaces());
}

QString CurrencyAdapter::getCurrencyDisplayName() const {
  return WALLET_CURRENCY_DISPLAY_NAME;
}

QString CurrencyAdapter::getCurrencyName() const {
  return CryptoNote::CRYPTONOTE_NAME;
}

QString CurrencyAdapter::getCurrencyTicker() const {
  return WALLET_CURRENCY_TICKER;
}

int CurrencyAdapter::calculateInterest(int amount, int term) {
    return CurrencyAdapter::instance().calculateInterest(amount, term, NodeAdapter::instance().getLastKnownBlockHeight());
}

quint64 CurrencyAdapter::calculateInterest(quint64 _amount, quint32 _term, uint32_t height) const {
  return m_currency.calculateInterest(_amount, _term, height);
}

int CurrencyAdapter::getMinimumFee() const {
  return static_cast<int>(m_currency.minimumFee());
}

quint64 CurrencyAdapter::getAddressPrefix() const {
  return m_currency.publicAddressBase58Prefix();
}

int CurrencyAdapter::getDepositMinAmount() const {
  return static_cast<int>(m_currency.depositMinAmount());
}

int CurrencyAdapter::getDepositMinTerm() const {
  return static_cast<int>(m_currency.depositMinTerm());
}

int CurrencyAdapter::getDepositMaxTerm() const {
  return static_cast<int>(m_currency.depositMaxTerm());
}

int CurrencyAdapter::getDifficultyTarget() const {
  return static_cast<int>(m_currency.difficultyTarget());
}

QString CurrencyAdapter::formatAmount(quint64 _amount) const {
  QString result = QString::number(_amount);
  if (result.length() < getNumberOfDecimalPlaces() + 1) {
    result = result.rightJustified(getNumberOfDecimalPlaces() + 1, '0');
  }

  quint32 dot_pos = result.length() - getNumberOfDecimalPlaces();
  for (quint32 pos = result.length() - 1; pos > dot_pos + 1; --pos) {
    if (result[pos] == '0') {
      result.remove(pos, 1);
    } else {
      break;
    }
  }

  result.insert(dot_pos, ".");
  for (qint32 pos = dot_pos - 3; pos > 0; pos -= 3) {
    if (result[pos - 1].isDigit()) {
      result.insert(pos, ',');
    }
  }

  return result;
}

quint64 CurrencyAdapter::parseAmount(const QString& _amountString) const {
  QString amountString = _amountString.trimmed();
  amountString.remove(',');

  int pointIndex = amountString.indexOf('.');
  int fractionSize;
  if (pointIndex != -1) {
    fractionSize = amountString.length() - pointIndex - 1;
    while (getNumberOfDecimalPlaces() < fractionSize && amountString.right(1) == "0") {
      amountString.remove(amountString.length() - 1, 1);
      --fractionSize;
    }

    if (getNumberOfDecimalPlaces() < fractionSize) {
      return 0;
    }

    amountString.remove(pointIndex, 1);
  } else {
    fractionSize = 0;
  }

  if (amountString.isEmpty()) {
    return 0;
  }

  for (qint32 i = 0; i < getNumberOfDecimalPlaces() - fractionSize; ++i) {
    amountString.append('0');
  }

  return amountString.toULongLong();
}

bool CurrencyAdapter::validateAddress(const QString& _address) const {
  CryptoNote::AccountPublicAddress internalAddress;
  return m_currency.parseAccountAddressString(_address.toStdString(), internalAddress);
}

bool CurrencyAdapter::validatePaymentId(const QString& _paymentIdString) const {
    if (_paymentIdString.isEmpty()) {
      return true;
    }

    QByteArray paymentId = QByteArray::fromHex(_paymentIdString.toUtf8());
    return (paymentId.size() == sizeof(Crypto::Hash)) && (_paymentIdString.toUpper() == paymentId.toHex().toUpper());
}

}
