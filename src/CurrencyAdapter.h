// Copyright (c) 2011-2017 The Cryptonote developers
// Copyright (c) 2014-2017 XDN developers
// Copyright (c) 2016-2017 BXC developers
// Copyright (c) 2017 UltraNote developers
// Distributed under the MIT/X11 software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#pragma once

#include <QString>
#include <QObject>

#include "CryptoNoteCore/Currency.h"

namespace WalletGui {

class CurrencyAdapter : public QObject {
  Q_OBJECT
public:
  static CurrencyAdapter& instance();

  const CryptoNote::Currency& getCurrency();
  Q_INVOKABLE QString getCurrencyDisplayName() const;
  QString getCurrencyName() const;
  Q_INVOKABLE QString getCurrencyTicker() const;
  Q_INVOKABLE quint64 calculateInterest(quint64 amount, quint32 term);
  quint64 calculateInterest(quint64 _amount, quint32 _term, uint32_t height) const;
  Q_INVOKABLE int getMinimumFee() const;
  quint64 getAddressPrefix() const;
  Q_INVOKABLE int getDepositMinAmount() const;
  Q_INVOKABLE int getDepositMinTerm() const;
  Q_INVOKABLE int getDepositMaxTerm() const;
  Q_INVOKABLE int getDifficultyTarget() const;
  Q_INVOKABLE int getNumberOfDecimalPlaces() const;
  QString formatAmount(quint64 _amount) const;
  Q_INVOKABLE quint64 parseAmount(const QString& _amountString) const;
  Q_INVOKABLE bool validateAddress(const QString& _address) const;
  Q_INVOKABLE bool validatePaymentId(const QString& _paymentIdString) const;

private:
  CryptoNote::Currency m_currency;

  CurrencyAdapter();
  ~CurrencyAdapter() = default;
};

}
