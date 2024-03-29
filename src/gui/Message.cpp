// Copyright (c) 2011-2017 The Cryptonote developers
// Copyright (c) 2014-2017 XDN developers
// Copyright (c) 2016-2017 BXC developers
// Copyright (c) 2017 UltraNote developers
// Distributed under the MIT/X11 software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#include <QTextStream>
#include <QTextDocumentFragment>

#include "Message.h"

namespace WalletGui {

namespace {

bool isEmptyChar(const QChar& _char) {
  return _char == ' ' || _char == '\t' || _char == '\n' || _char == '\r';
}

MessageHeader parseMessage(QString& _message) {
  QString tmpMessage(_message);
  MessageHeader res;
  while (!tmpMessage.isEmpty() && isEmptyChar(tmpMessage[0])) {
    tmpMessage.remove(0, 1);
  }

  if(tmpMessage.isEmpty()) {
    return res;
  }

  QTextStream messageStream(&tmpMessage);
  while (!messageStream.atEnd()) {
    QString line = messageStream.readLine();
    if (line.isEmpty()) {
      _message = tmpMessage.mid(messageStream.pos());
      break;
    }

    QStringList keyValue = line.split(":");
    if (keyValue.size() < 2) {
      return MessageHeader();
    }

    res.append(qMakePair(keyValue[0].trimmed(), keyValue[1].trimmed()));
  }

  return res;
}

}

Message::Message() : m_message(), m_header() {
}

Message::Message(const Message& _message) : m_message(_message.m_message), m_header(_message.m_header) {
}

Message::Message(const Message&& _message) : m_message(std::move(_message.m_message)), m_header(std::move(_message.m_header)) {
}

Message::Message(const QString& _message) : m_message(_message), m_header(parseMessage(m_message)) {
}

Message::~Message() {
}

QString Message::getMessage() const {
  return QTextDocumentFragment::fromHtml(m_message).toPlainText();
}

QString Message::getFullMessage() const {
  return makeTextMessage(m_message, m_header,false);
}

QString Message::getHeaderValue(const QString& _key) const {
  for (const auto& header : m_header) {
    if (header.first.compare(_key, Qt::CaseInsensitive) == 0) {
      return header.second;
    }
  }

  return QString();
}

Message& Message::operator=(const Message& _message) {
  m_message = _message.m_message;
  m_header = _message.m_header;
  return *this;
}

QString Message::makeTextMessage(const QString& _message, const MessageHeader& _header, bool _toBeSent)
{
	QString res;
	Q_FOREACH(const auto& headerItem, _header) {
		_toBeSent ? res.append(QString("%1: %2\n").arg(headerItem.first).arg(headerItem.second)) 
		: res.append(QString("<span style=\" font-weight:600;\">%1 :</span>%2</p><br>\n").arg(headerItem.first).arg(headerItem.second));
	}

	if (!res.isEmpty()) {
		res.append("\n");
	}

	if (_toBeSent) { res.append(_message); }
	else {
		res.append(QString("<span style=\" font-weight:600;\">Message body :</span></p><br>"));
		res.append(_message);
	}
	return res;
}
}
