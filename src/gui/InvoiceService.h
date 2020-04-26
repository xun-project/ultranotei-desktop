// Copyright (c) 2011-2017 The Cryptonote developers
// Copyright (c) 2014-2017 XDN developers
// Copyright (c) 2016-2017 BXC developers
// Copyright (c) 2017 UltraNote developers
// Distributed under the MIT/X11 software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#pragma once

#include <QDrag>
#include <QDragEnterEvent>
#include <QDragMoveEvent>
#include <QDropEvent>
#include <QFrame>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QStringListModel>

#include "CurrencyAdapter.h"
#include "qmlhelpers.h"
#include <IWalletLegacy.h>

namespace WalletGui {

	class AliasProvider;

	class InvoiceService : public QObject {
		Q_OBJECT

			QML_WRITABLE_PROPERTY(QString, address, setAddress, "")
			QML_WRITABLE_PROPERTY(QString, label, setLabel, "")
			QML_WRITABLE_PROPERTY(QString, paymentID, setPaymentID, "")
			QML_WRITABLE_PROPERTY_FLOAT(qreal, amount, setAmount, 0.0)
			QML_WRITABLE_PROPERTY(QString, invoiceID, setInvoiceID, "")
			QML_WRITABLE_PROPERTY(QString, qrPayload, setQrPayload, "")
			QML_WRITABLE_PROPERTY(QString, invoiceMessageText, setinvoiceMessageText, "")
			QML_CONSTANT_PROPERTY_PTR(QStringListModel, attachmentsModel)
			QML_WRITABLE_PROPERTY(bool, replyToEnabled, setReplyToEnabled, false)
			QML_WRITABLE_PROPERTY(bool, replyToChecked, setReplyToChecked, true)
			QML_WRITABLE_PROPERTY(bool, ttlEnabled, setTtlEnabled, false)
			QML_WRITABLE_PROPERTY(int, ttlMinimalValue, setTtlMinimalValue, 1)
			QML_WRITABLE_PROPERTY(int, ttlMaximumValue, setTtlMaximumValue, 0)
			QML_WRITABLE_PROPERTY(int, ttlValue, setTtlValue, 0)
			QML_WRITABLE_PROPERTY(QString, ttlDecoratedValue, setTtlDecoratedValue, "")
			QML_WRITABLE_PROPERTY_FLOAT(double, feeMinimalValue, setFeeMinimalValue, 0.0)
			QML_WRITABLE_PROPERTY_FLOAT(double, feeValue, setFeeValue, 0.0)
			QML_WRITABLE_PROPERTY(int, mixinValue, setMixinValue, 2)

	public:
		InvoiceService(QObject* _parent);
		~InvoiceService() override;

		void reset() const;
		QString getAddress() const;
		QString getLabel() const;
		qreal getAmount() const;
		QString getAmountString() const;
		QString getInvoiceId() const;
		QString getPaymentId() const;
		QString base64Encode(QString string);

		Q_INVOKABLE void recalculateFeeValue();
		Q_INVOKABLE void addAttachmentClicked(const QString& fileUrl);
		Q_INVOKABLE void onMessageTextChanged();
		Q_INVOKABLE void mixinValueChanged(int _value);
		Q_INVOKABLE void sendClicked();
		Q_INVOKABLE void ttlCheckStateChanged(int _state);
		Q_INVOKABLE void ttlValueChanged(int _ttlValue);
		Q_INVOKABLE void addressEdited();
		Q_INVOKABLE void invoiceIdEdited(const QString& _text);
		Q_INVOKABLE void pasteClicked();
		Q_INVOKABLE void removeAttachment(int index);
	public slots:
		void updateQRCode();
		void sendMessageCompleted(CryptoNote::TransactionId _transactionId, bool _error, const QString& _errorText);

	private slots:
		void onAliasFound(const QString& _name, const QString& _address);
		void checkAddressAlias();

	private:
		AliasProvider* m_aliasProvider;
		QTimer* m_addressInputTimer;

		static const QString IPFS_API_URL;
		static const QString IPFS_RESPONSE_HASH_FIELD;

		QNetworkAccessManager networkAccessManager;
		QMutex timerMutex;

		void sendMessage(const QString& ipfsHash, const QString& encrpyptionKey);
		void reset();
		qint64 totalAttachmentsSize();
		bool isAttachmentExist(const QString& filename);
		void packAttachments(QTemporaryFile* archive);
		void uploadAttachments(QTemporaryFile* archive);
		void showUploadProgress(QNetworkReply* reply);
		void attachmentUploaded(QNetworkReply* reply, const QString& encryptionKey);
		void packAttachmentsToArchive(const QIODevice* archive);
		bool isValidPaymentId(const QByteArray& _paymentIdString);
		void addAttachments(const QStringList& filenames);
		QString extractAddress(const QString& _addressString) const;
	};

}
