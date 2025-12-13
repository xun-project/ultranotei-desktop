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
  
  // Remove leading whitespace
  while (!tmpMessage.isEmpty() && isEmptyChar(tmpMessage[0])) {
    tmpMessage.remove(0, 1);
  }

  if(tmpMessage.isEmpty()) {
    return res;
  }

  // Parse headers
  int headerEndPos = -1;
  QStringList lines = tmpMessage.split('\n');
  
  // Look for empty line that marks end of headers
  for (int i = 0; i < lines.size(); ++i) {
    if (lines[i].trimmed().isEmpty()) {
      headerEndPos = i;
      break;
    }
  }
  
  // If no empty line found, check if we have any lines that look like headers
  if (headerEndPos == -1) {
    // Check if first line looks like a header (contains colon)
    if (!lines.isEmpty() && lines[0].contains(':')) {
      // First line has colon, might be a header
      // But without empty line, we can't be sure
      // For compatibility, treat entire message as body
      _message = tmpMessage;
      return MessageHeader();
    } else {
      // No colon in first line, definitely not headers
      // Entire message is body
      _message = tmpMessage;
      return MessageHeader();
    }
  }
  
  // We found an empty line - parse lines before it as headers
  for (int i = 0; i < headerEndPos; ++i) {
    QString line = lines[i];
    int colonPos = line.indexOf(':');
    if (colonPos == -1) {
      // Not a valid header line
      // This shouldn't happen if we have proper header format
      // But for robustness, treat everything as message body
      _message = tmpMessage;
      return MessageHeader();
    }
    
    QString key = line.left(colonPos).trimmed();
    QString value = line.mid(colonPos + 1).trimmed();
    res.append(qMakePair(key, value));
  }
  
  // Reconstruct message body (skip header lines and the empty line)
  _message.clear();
  for (int i = headerEndPos + 1; i < lines.size(); ++i) {
    if (!_message.isEmpty()) {
      _message += '\n';
    }
    _message += lines[i];
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
