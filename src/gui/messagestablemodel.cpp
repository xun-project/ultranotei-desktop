#include "messagestablemodel.h"
#include "WalletAdapter.h"
#include "CurrencyAdapter.h"
#include "../qzipreader_p.h"
#include <QTextStream>
#include <QNetworkReply>
#include <QTemporaryFile>
#include <QDir>
#include <QDebug>

namespace WalletGui {

Q_DECL_CONSTEXPR quint64 DOWNLOAD_BUFFER_SIZE = 100 * 1024 * 1024;

static
const QString HEADER_REPLY_TO_KEY = "Reply-To";
static
const QString HEADER_ATTACHMENT = "Attachment";
static
const QString HEADER_ATTACHMENT_ENCRYPTION_KEY = "Attachment-Encryption-Key";
static
const QString IPFS_API_URL = "http://backup.ultranote.org:8080/ipfs/";
const QString HEADER_INVOICE_ID = "Invoice-ID";
const QString HEADER_INVOICE_AMOUNT = "Invoice-Amount";
const QString HEADER_PAYMENT_ID = "Payment-ID";

MessagesTableModel::MessagesTableModel(QObject *parent) : QAbstractTableModel(parent)
{
	initUnseenCacheFile();
    connect(&m_networAccesskManager, &QNetworkAccessManager::finished, this,
            &MessagesTableModel::attachmentDownloaded);
}

int MessagesTableModel::rowCount(const QModelIndex &index) const
{
    Q_UNUSED(index)
    return m_messages.size();
}

int MessagesTableModel::columnCount(const QModelIndex &index) const
{
    Q_UNUSED(index)
    return ColumnName::Count;
}

QVariant MessagesTableModel::data(const QModelIndex &index, int role) const
{
    const int col = index.column();
    const int row = index.row();

    if ((0 > row) || (m_messages.size() <= row)) {
        qCritical() << "Invalid row index" << row;
        return QVariant();
    }

    cn::WalletLegacyTransaction transaction;
    cn::TransactionId transactionId = m_messages.value(row).first;
    WalletGui::Message message = m_messages.value(row).second;
    if(!WalletAdapter::instance().getTransaction(transactionId, transaction)) {
      return QVariant();
    }

    QVariant out;
    switch (role) {
    case Qt::DisplayRole:
        switch (col) {
        case Date: {
            const auto date = (transaction.timestamp > 0 ? QDateTime::fromTime_t(static_cast<uint>(transaction.timestamp)) : QDateTime());
            out = (date.isNull() || !date.isValid() ? "-" : date.toString("yyyy-MM-dd HH:mm"));
        }
            break;
        case Type:
            out = (transaction.totalAmount < 0) ? tr("Out") : tr("In");
            break;
        case Height: {
            const auto height = transaction.blockHeight;
            out = (height == cn::WALLET_LEGACY_UNCONFIRMED_TRANSACTION_HEIGHT ? "-" : QString::number(height));
        }
            break;
        case Message: {
            auto msg = message.getMessage();
            QTextStream messageStream(&msg);
            out = messageStream.readLine();
        }
            break;
        default:
            ;
        }
        break;
    default:
        ;
    }
    return out;
}

QHash<int, QByteArray> MessagesTableModel::roleNames() const
{
    static const auto roles = QHash<int, QByteArray>{
        { Qt::DisplayRole, "display" }
    };
    return roles;
}

QString MessagesTableModel::columnName(int index)
{
    QString name;
    switch (index) {
    case ColumnName::Date:
        name = getColumnName(Date);
        break;
    case ColumnName::Type:
        name = getColumnName(Type);
        break;
    case ColumnName::Height:
        name = getColumnName(Height);
        break;
    case ColumnName::Message:
        name = getColumnName(Message);
        break;
    }
    return name;
}

void MessagesTableModel::setupMessageDetails(int row)
{
    if ((0 > row) || (m_messages.size() <= row)) {
        qCritical() << "Invalid row index" << row;
        return;
    }
    cn::WalletLegacyTransaction transaction;
    cn::TransactionId transactionId = m_messages.value(row).first;
    WalletGui::Message message = m_messages.value(row).second;

	int transactionIndex = indexAtUnseen(transactionId);
	if (transactionIndex >= 0) {
		removeFromUnseen(transactionId);
		saveChangesToCache();
		Q_EMIT layoutAboutToBeChanged();
		Q_EMIT layoutChanged();
	}

    if(!WalletAdapter::instance().getTransaction(transactionId, transaction)) {
      return;
    }

    const auto height = transaction.blockHeight;
    const QString msgHeight = (height == cn::WALLET_LEGACY_UNCONFIRMED_TRANSACTION_HEIGHT ? "-" : QString::number(height));
    setMsgHeight(msgHeight);

    const auto hash = QByteArray(reinterpret_cast<char*>(&transaction.hash),
                                 sizeof(transaction.hash));
    setMsgHash(hash.toHex().toUpper());

    const auto amount = static_cast<qint64>(transaction.totalAmount);
    setMsgAmount(CurrencyAdapter::instance().formatAmount(qAbs(amount)));

    setMsgSize(message.getMessage().size());

    setMsgFullText(message.getFullMessage());

    setMsgReplyTo(message.getHeaderValue(HEADER_REPLY_TO_KEY));

	 QString INVOICE_AMOUNT = message.getHeaderValue(HEADER_INVOICE_AMOUNT);
	if ("" != INVOICE_AMOUNT) {
		setMsgInvoice(true);
		setmsgInvoiceId(message.getHeaderValue(HEADER_INVOICE_ID));
		setmsgPaymentId(message.getHeaderValue(HEADER_PAYMENT_ID));
		setmsgInvoiceAmount(INVOICE_AMOUNT);
	}
	else{ 
		setMsgInvoice(false);
	}
    qDebug() << "[messagestablemodel] Invoice headers:" << message.getHeaderValue(HEADER_INVOICE_ID) << message.getHeaderValue(HEADER_INVOICE_AMOUNT) << message.getHeaderValue(HEADER_PAYMENT_ID);

    setMsgAttachment(message.getHeaderValue(HEADER_ATTACHMENT));

    m_encryptionKey = QByteArray::fromHex(message.getHeaderValue(HEADER_ATTACHMENT_ENCRYPTION_KEY).toUtf8());
}

void MessagesTableModel::save(const QUrl &fileName)
{
    m_fileNameToSave = fileName.toLocalFile();
    QFile file(m_fileNameToSave);
    if (file.exists(m_fileNameToSave)) {
        qWarning() << "File already exists" << m_fileNameToSave;
    }

    if (!file.open(QFile::WriteOnly | QFile::Truncate)) {
      emit showErrorDialog(tr("File error"), file.errorString());
      return;
    }
    file.write(m_msgFullText.toUtf8());
    file.close();
}

void MessagesTableModel::download(const QUrl &folderName)
{
    m_attachmentDirectory = folderName.toLocalFile();
    if(m_attachmentDirectory.isEmpty()) {
      return;
    }

    const QNetworkRequest request = QNetworkRequest(QUrl(IPFS_API_URL + m_msgAttachment));
    QNetworkReply* reply = m_networAccesskManager.get(request);
    reply->setReadBufferSize(DOWNLOAD_BUFFER_SIZE);
    showUploadProgress(reply);
}

void MessagesTableModel::showUploadProgress(QNetworkReply* reply)
{
    connect(reply, &QNetworkReply::downloadProgress, this,
            [&](qint64 bytesReceived, qint64 bytesTotal) {
        if (0 != bytesTotal) {
            emit downloadProgressChanged(static_cast<double>(bytesReceived) / bytesTotal);
        } else {
            emit abortDownload();
        }

    });
    connect(reply, &QNetworkReply::finished, this, &MessagesTableModel::abortDownload);
    emit showDownloadProgress();
}

void MessagesTableModel::cancelDownload()
{
    if (nullptr != m_downloadReply) {
        m_downloadReply->abort();
    }
}

bool MessagesTableModel::getReadState(int row) const
{
	cn::TransactionId transactionId = m_messages.value(row).first;
	cn::WalletLegacyTransaction transaction;

	if (!WalletAdapter::instance().getTransaction(transactionId, transaction)) {
		return true;
	}

	int transactionIndex = indexAtUnseen(transactionId);
	if (transactionIndex >= 0 && transaction.totalAmount > 0) return false;
	else return true;
}

void MessagesTableModel::attachmentDownloaded(QNetworkReply* reply)
{
    reply->deleteLater();
    m_downloadReply = nullptr;

    if(reply->error() == QNetworkReply::OperationCanceledError) {
      emit abortDownload();
      return;
    }

    if(reply->error()) {
      emit showErrorDialog(tr("Error"), tr("Can't download attachment: ") +
                           reply->errorString());
      return;
    }

    QByteArray payload = reply->readAll();
    WalletAdapter::instance().decryptAttachment(payload, m_encryptionKey);

    extractAttachment(payload);
}

void MessagesTableModel::extractAttachment(const QByteArray &data)
{
    QTemporaryFile tempFile;
    if(!tempFile.open()) {
        emit showErrorDialog(tr("Error"), tr("Can't create temporary file for attachment"));
        return;
    }

    tempFile.write(data);
    tempFile.close();
    tempFile.open();

    QZipReader zipReader(&tempFile);
    if(zipReader.status() != QZipReader::NoError) {
        emit showErrorDialog(tr("Error"), tr("Can't open attachment zip archive"));
        return;
    }

    const QString dir = m_attachmentDirectory + "/" + m_msgHash;
    if(!QDir(dir).exists()) {
        if(!QDir().mkdir(dir)) {
            emit showErrorDialog(tr("Error"), tr("Can't create attachment directory"));
            return;
        }
    }

    if(!zipReader.extractAll(dir)) {
        emit showErrorDialog(tr("Error"), tr("Can't unpack attachment"));
    }
    zipReader.close();
}

void MessagesTableModel::reloadWalletTransactions()
{
    emit layoutAboutToBeChanged();
    m_transactionRow.clear();
    m_messages.clear();
    emit layoutChanged();

    quint32 rowCount = 0;
	messagesListTransactionId.clear();
    for (cn::TransactionId transactionId = 0; transactionId < WalletAdapter::instance().getTransactionCount(); ++transactionId) {
      appendTransaction(transactionId, rowCount);
    }
	
	int messagesCount = messagesListTransactionId.size();
	int savedMessageLastCount = getMsgLastCount();
	if (savedMessageLastCount  != messagesCount) {
		setMsgLastCount(messagesCount);
		int msgDifference = messagesCount - savedMessageLastCount;
		for (int i = 0; i < msgDifference; i++) {
			cn::TransactionId transactionId = messagesListTransactionId.at(messagesCount - i - 1);
			cn::WalletLegacyTransaction transaction;

			if (WalletAdapter::instance().getTransaction(transactionId, transaction)) {
				if (transaction.totalAmount > 0) {
					appendToUnseen(transactionId);
				}
			}
		}
		 saveChangesToCache();
	}
    sortMessages();
    emit rowCountChanged();
}

void MessagesTableModel::appendTransaction(cn::TransactionId _id,
                                           quint32& _row_count)
{
    cn::WalletLegacyTransaction transaction;
    if (!WalletAdapter::instance().getTransaction(_id, transaction)) {
      return;
    }

    m_transactionRow.insert(_id, qMakePair(std::numeric_limits<quint32>::max(), std::numeric_limits<quint32>::max()));
    if (transaction.messages.empty()) {
      return;
    }

    m_transactionRow[_id] = qMakePair(m_messages.size(), transaction.messages.size());
    for (quint32 i = 0; i < transaction.messages.size(); ++i) {
      QString rawMessage = QString::fromStdString(transaction.messages[i]);
      
      WalletGui::Message message(rawMessage);
      QString parsedMessage = message.getMessage();
      
      // Check for headers
      QString replyTo = message.getHeaderValue(HEADER_REPLY_TO_KEY);
      QString attachment = message.getHeaderValue(HEADER_ATTACHMENT);
      
      m_messages.append(TransactionMessageId(_id, std::move(message)));
	  messagesListTransactionId.append(_id);
      ++_row_count;
    }
}

void MessagesTableModel::appendTransaction(cn::TransactionId _id)
{
    if (m_transactionRow.contains(_id)) {
        return;
    }

    quint32 insertedRowCount = 0;
    emit layoutAboutToBeChanged();
    for (cn::TransactionId transactionId =
         static_cast<cn::TransactionId>(m_transactionRow.size());
         transactionId <= _id; ++transactionId) {
        appendTransaction(transactionId, insertedRowCount);
		cn::WalletLegacyTransaction transaction;
		if (WalletAdapter::instance().getTransaction(transactionId, transaction)) {
			if (transaction.totalAmount > 0)
				appendToUnseen(transactionId);
		}
    }
	setMsgLastCount(messagesListTransactionId.size());
	saveChangesToCache();

    sortMessages();
    emit layoutChanged();
    emit rowCountChanged();
}

void MessagesTableModel::updateWalletTransaction(cn::TransactionId _id)
{
    Q_UNUSED(_id)
    emit layoutAboutToBeChanged();
    emit layoutChanged();
}

void MessagesTableModel::reset()
{
    emit layoutAboutToBeChanged();
    m_messages.clear();
    m_transactionRow.clear();
    emit layoutChanged();
    emit rowCountChanged();
}

void MessagesTableModel::lastKnownHeightUpdated(quint64 _height)
{
    Q_UNUSED(_height)
    emit layoutAboutToBeChanged();
    emit layoutChanged();
}

void MessagesTableModel::sortMessages()
{
    std::sort(m_messages.begin(), m_messages.end(),
              [&](TransactionMessageId &left, TransactionMessageId &right) {
        const cn::TransactionId leftTransactionId = left.first;
        const cn::TransactionId rightTransactionId = right.first;
        cn::WalletLegacyTransaction leftTransaction;
        cn::WalletLegacyTransaction rightTransaction;
        if (WalletAdapter::instance().getTransaction(leftTransactionId, leftTransaction) &&
            WalletAdapter::instance().getTransaction(rightTransactionId, rightTransaction)) {
            const QDateTime leftDate = (leftTransaction.timestamp > 0 ? QDateTime::fromTime_t(static_cast<uint>(leftTransaction.timestamp)) : QDateTime());
            const QDateTime rightDate = (rightTransaction.timestamp > 0 ? QDateTime::fromTime_t(static_cast<uint>(rightTransaction.timestamp)) : QDateTime());
            if (leftDate.isNull() || !leftDate.isValid()) {
                return true;
            }
            if (rightDate.isNull() || !rightDate.isValid()) {
                return false;
            }
            return leftDate > rightDate;
        }
        return true;//should not happen
    });
}

int MessagesTableModel::getMsgLastCount() const
{
	return msgLastCount;
}

void MessagesTableModel::setMsgLastCount(int newCount)
{
	msgLastCount = newCount;
}

void MessagesTableModel::saveChangesToCache()
{
	QFile UnreadFile(Settings::instance().getUnreadMessagesFile());
	if (!UnreadFile.open(QIODevice::WriteOnly | QIODevice::Text | QFile::Truncate))
		return;
	QTextStream out(&UnreadFile);
	out << "MsgNo:" << msgLastCount << "\n" << "Unseen:";
	for (int i = 0; i < unseenList.size(); i++) {
		out << QString::number(unseenList.at(i)) << ",";

	}
	UnreadFile.flush();
	UnreadFile.close();
}

void MessagesTableModel::appendToUnseen(cn::TransactionId transactionId)
{
	unseenList.append(transactionId);
}

void MessagesTableModel::removeFromUnseen(cn::TransactionId transactionId)
{
	unseenList.remove(indexAtUnseen(transactionId));
}

int MessagesTableModel::indexAtUnseen(cn::TransactionId transactionId) const
{
	return unseenList.indexOf(transactionId);
}
void MessagesTableModel::initUnseenCacheFile()
{
	QFile UnreadFile(Settings::instance().getUnreadMessagesFile());
	if (!UnreadFile.open(QIODevice::ReadWrite | QIODevice::Text))
		return;
	msgLastCount = 0;
	while (!UnreadFile.atEnd()) {
		QByteArray line = UnreadFile.readLine();
		if (line.contains("MsgNo:")) {
			line.remove(0, 6);
			msgLastCount = QString(line).toInt();

		}
		if (line.contains("Unseen:")) {
			line.remove(0, 7);
			QStringList	list = QString(line).split(',', QString::SkipEmptyParts);
			foreach(QString num, list)
				unseenList.append(num.toInt());

		}

	}
	UnreadFile.flush();
	UnreadFile.close();
}

QString MessagesTableModel::getColumnName(ColumnName columnName)
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
        case Date:
            headerName = "Date";
            break;
        case Type:
            headerName = "Type";
            break;
        case Height:
            headerName = "Height";
            break;
        case Message:
            headerName = "Message";
            break;
        default:
            break;
        }
    }

    return headerName;
}

} //WalletGui
