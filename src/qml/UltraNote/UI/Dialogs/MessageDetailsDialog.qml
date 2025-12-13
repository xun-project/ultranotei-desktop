import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.13
import QtQuick.Layouts 1.13

import UltraNote.UI 1.0
import UltraNote.UI.Controls 1.0

UNDialog {
    id: _dialog

    property int currentRow: -1
    property var model: walletAdapter.messagesTableModel

    buttons: ListModel {
        ListElement { type: UNDialog.ButtonType.TypeNormal; role: DialogButtonBox.RejectRole; text: qsTr("Close")}
    }

    implicitWidth: Theme.messageDetailsDialogWindowWidth
    closePolicy: Popup.CloseOnEscape
    title: qsTr("Message details")
    modal: true

    Item {
        id: _contentItem

        anchors.left: parent.left
        anchors.right: parent.right

        height: _contentData.height
        implicitHeight: height

        clip: true

        DownloadProgressDialog {
            id: _progressDialog

            visible: false

            onRejected: {
                walletAdapter.messagesTableModel.cancelDownload()
            }
        }

        Connections {
            target: walletAdapter.messagesTableModel
            onDownloadProgressChanged: {
                _progressDialog.value = value
                _progressDialog.open()
            }
            onAbortDownload: {
                _progressDialog.value = 1
                _progressDialog.close()
            }
            onShowDownloadProgress: {
                _progressDialog.value = 0
                _progressDialog.open()
            }
        }

        ColumnLayout {
            id: _contentData

            anchors.left: parent.left
            anchors.right: parent.right

            spacing: 0

            property int labelWidth: Math.max(
                                         _blockHeightLabel.implicitWidth,
                                         _transactionHashLabel.implicitWidth,
                                         _amountLabel.implicitWidth,
                                         _messageSizeLabel.implicitWidth,
                                         )

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: implicitHeight
                Layout.maximumHeight: implicitHeight
                Layout.minimumHeight: implicitHeight

                spacing: 24

                UNLabel {
                    id: _blockHeightLabel

                    Layout.preferredWidth: _contentData.labelWidth
                    Layout.maximumWidth: _contentData.labelWidth
                    Layout.minimumWidth: _contentData.labelWidth
                    Layout.alignment: Qt.AlignVCenter

                    type: UNLabel.Type.TypeNormal

                    lineHeight: 17
                    lineHeightMode: Label.FixedHeight
                    color: Theme.dialogTextColor
                    elide: Label.ElideNone
                    wrapMode: Label.WordWrap
                    maximumLineCount: 10
                    horizontalAlignment: Label.AlignLeft
                    verticalAlignment: Label.AlignVCenter

                    text: qsTr("Block height:")
                }

                UNLabel {
                    id: _blockHeight

                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter

                    type: UNLabel.Type.TypeNormal

                    lineHeight: 17
                    lineHeightMode: Label.FixedHeight
                    color: Theme.dialogTextColor
                    elide: Label.ElideNone
                    wrapMode: Label.WordWrap
                    maximumLineCount: 10
                    horizontalAlignment: Label.AlignLeft
                    verticalAlignment: Label.AlignVCenter

                    text: _dialog.model.msgHeight
                }
            }

            UNLayoutSpacer {
                fixedHeight: 16
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: implicitHeight
                Layout.maximumHeight: implicitHeight
                Layout.minimumHeight: implicitHeight

                spacing: 24

                UNLabel {
                    id: _transactionHashLabel

                    Layout.preferredWidth: _contentData.labelWidth
                    Layout.maximumWidth: _contentData.labelWidth
                    Layout.minimumWidth: _contentData.labelWidth
                    Layout.alignment: Qt.AlignVCenter

                    type: UNLabel.Type.TypeNormal

                    lineHeight: 17
                    lineHeightMode: Label.FixedHeight
                    color: Theme.dialogTextColor
                    elide: Label.ElideNone
                    wrapMode: Label.WordWrap
                    maximumLineCount: 10
                    horizontalAlignment: Label.AlignLeft
                    verticalAlignment: Label.AlignVCenter

                    text: qsTr("Transaction hash:")
                }

                UNLabel {
                    id: _transactionHash

                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter

                    type: UNLabel.Type.TypeNormal

                    lineHeight: 17
                    lineHeightMode: Label.FixedHeight
                    color: Theme.dialogTextColor
                    elide: Label.ElideNone
                    wrapMode: Label.WordWrap
                    maximumLineCount: 10
                    horizontalAlignment: Label.AlignLeft
                    verticalAlignment: Label.AlignVCenter

                    text: _dialog.model.msgHash
                }
            }

            UNLayoutSpacer {
                fixedHeight: 16
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: implicitHeight
                Layout.maximumHeight: implicitHeight
                Layout.minimumHeight: implicitHeight

                spacing: 24

                UNLabel {
                    id: _amountLabel

                    Layout.preferredWidth: _contentData.labelWidth
                    Layout.maximumWidth: _contentData.labelWidth
                    Layout.minimumWidth: _contentData.labelWidth
                    Layout.alignment: Qt.AlignVCenter

                    type: UNLabel.Type.TypeNormal

                    lineHeight: 17
                    lineHeightMode: Label.FixedHeight
                    color: Theme.dialogTextColor
                    elide: Label.ElideNone
                    wrapMode: Label.WordWrap
                    maximumLineCount: 10
                    horizontalAlignment: Label.AlignLeft
                    verticalAlignment: Label.AlignVCenter

                    text: qsTr("Amount:")
                }

                UNLabel {
                    id: _amount

                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter

                    type: UNLabel.Type.TypeNormal

                    lineHeight: 17
                    lineHeightMode: Label.FixedHeight
                    color: Theme.dialogTextColor
                    elide: Label.ElideNone
                    wrapMode: Label.WordWrap
                    maximumLineCount: 10
                    horizontalAlignment: Label.AlignLeft
                    verticalAlignment: Label.AlignVCenter

                    text: _dialog.model.msgAmount
                }
            }

            UNLayoutSpacer {
                fixedHeight: 16
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: implicitHeight
                Layout.maximumHeight: implicitHeight
                Layout.minimumHeight: implicitHeight

                spacing: 24

                UNLabel {
                    id: _messageSizeLabel

                    Layout.preferredWidth: _contentData.labelWidth
                    Layout.maximumWidth: _contentData.labelWidth
                    Layout.minimumWidth: _contentData.labelWidth
                    Layout.alignment: Qt.AlignVCenter

                    type: UNLabel.Type.TypeNormal

                    lineHeight: 17
                    lineHeightMode: Label.FixedHeight
                    color: Theme.dialogTextColor
                    elide: Label.ElideNone
                    wrapMode: Label.WordWrap
                    maximumLineCount: 10
                    horizontalAlignment: Label.AlignLeft
                    verticalAlignment: Label.AlignVCenter

                    text: qsTr("Message size (bytes):")
                }

                UNLabel {
                    id: _messageSize

                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter

                    type: UNLabel.Type.TypeNormal

                    lineHeight: 17
                    lineHeightMode: Label.FixedHeight
                    color: Theme.dialogTextColor
                    elide: Label.ElideNone
                    wrapMode: Label.WordWrap
                    maximumLineCount: 10
                    horizontalAlignment: Label.AlignLeft
                    verticalAlignment: Label.AlignVCenter

                    text: _dialog.model.msgSize
                }
            }

            UNLayoutSpacer {
                fixedHeight: 16
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: implicitHeight
                Layout.maximumHeight: implicitHeight
                Layout.minimumHeight: implicitHeight

                spacing: 8

                UNLabel {
                    type: UNLabel.Type.TypeMedium
                    size: 17
                    color: Theme.primaryDarkColor
                    text: qsTr("Message data")
                    wrapMode: Label.WordWrap
                    elide: Label.ElideNone
                }

                UNLayoutSpacer {}
            }

            UNLayoutSpacer {
                fixedHeight: 16
            }

            UNTextArea {
                id: _messageTextArea

                Layout.fillWidth: true
                Layout.preferredHeight: 200
                Layout.maximumHeight: 200
                Layout.minimumHeight: 200

                focus: true

                text: _dialog.model.msgFullText
                readOnly: true

                //placeholderText: qsTr("Message text")
                textColor: Theme.dialogTextColor

                function copySelected() {
                    clipboard.setText(_messageTextArea._textArea.selectedText)
                }

                function selectAll() {
                    _messageTextArea._textArea.select(0,_messageTextArea.text.length);
                }

                Shortcut {
                    sequence: StandardKey.Copy
                    onActivated: _messageTextArea.copySelected()
                    enabled: _dialog.visible
                }

                Shortcut {
                    sequence: StandardKey.SelectAll
                    onActivated: _messageTextArea.selectAll()
                }

                property int selectionStartOnClick: 0
                property int selectionEndOnClick: 0

                MouseArea {
                    anchors.fill: parent

                    propagateComposedEvents: true
                    preventStealing: false

                    acceptedButtons: Qt.RightButton

                    onClicked: {
                        _textActionsMenu.x = mouseX
                        _textActionsMenu.y = mouseY
                        _textActionsMenu.open()
                    }
                }

                UNMenu {
                    id: _textActionsMenu

                    margins: 20
                    topPadding: 24
                    bottomPadding: 27
                    rightPadding: 50

                    color: Theme.statusBarMenuColor

                    UNMenuItem {
                        text: qsTr("Select All")

                        onClicked: {
                            _messageTextArea.selectAll()
                        }
                    }

                    UNMenuItem {
                        text: qsTr("Copy")

                        onClicked: {
                            _messageTextArea.copySelected()
                        }
                    }
                }
            }

            UNLayoutSpacer {
                fixedHeight: 16
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: implicitHeight
                Layout.maximumHeight: implicitHeight
                Layout.minimumHeight: implicitHeight

                spacing: 8

                UNButton {
                    id: _replyButton

                    Layout.preferredWidth: implicitWidth
                    Layout.maximumWidth: implicitWidth
                    Layout.alignment: Qt.AlignVCenter
                    activeColor:Theme.messageDetailsDialogButtonActiveColor
                    baseColor: Theme.messageDetailsDialogButtonColor
                    textColor: Theme.messageDetailsDialogButtonTextColor
                    width: Theme.messageDetailsDialogButtonwidth
                    height:  Theme.messageDetailsDialogButtonheight
                    lableTextSize: Theme.messageDetailsDialogButtonFontSize
                    enabled: "" !== _dialog.model.msgReplyTo
                    visible: !_dialog.model.hasInvoiceId
                    text: qsTr("Reply")

                    onClicked: {
                        _messageDetailsDialog.close()
                        _globalProperties.setupSendMsg(_dialog.model.msgReplyTo)
                    }
                }
                UNButton {
                    id: _payButton

                    Layout.preferredWidth: implicitWidth
                    Layout.maximumWidth: implicitWidth
                    Layout.alignment: Qt.AlignVCenter
                    activeColor:Theme.messageDetailsDialogButtonActiveColor
                    baseColor: Theme.messageDetailsDialogButtonColor
                    textColor: Theme.messageDetailsDialogButtonTextColor
                    width: Theme.messageDetailsDialogButtonwidth
                    height:  Theme.messageDetailsDialogButtonheight
                    lableTextSize: Theme.messageDetailsDialogButtonFontSize
                    visible: _dialog.model.hasInvoiceId
                    text: qsTr("Pay")

                    onClicked: {
                        _messageDetailsDialog.close()
                        // The invoice data should already be set in messages table model by setupMessageDetails
                        // But we set them explicitly to be sure
                        walletAdapter.messagesTableModel.msgInvoiceId = _dialog.model.msgInvoiceId
                        walletAdapter.messagesTableModel.msgPaymentId = _dialog.model.msgPaymentId
                        walletAdapter.messagesTableModel.msgInvoiceAmount = _dialog.model.msgInvoiceAmount
                        _globalProperties.setupPayMsg(_dialog.model.msgReplyTo)
                    }
                }

                UNButton {
                    Layout.preferredWidth: implicitWidth
                    Layout.maximumWidth: implicitWidth
                    Layout.minimumWidth: implicitWidth
                    Layout.alignment: Qt.AlignVCenter
                    activeColor:Theme.messageDetailsDialogButtonActiveColor
                    baseColor: Theme.messageDetailsDialogButtonColor
                    textColor: Theme.messageDetailsDialogButtonTextColor
                    height:  Theme.messageDetailsDialogButtonheight
                    lableTextSize: Theme.messageDetailsDialogButtonFontSize
                    enabled: 0 < _dialog.currentRow

                    text: qsTr("Save to file")

                    onClicked: {
                        _walletDialog.selectFolder = false
                        _walletDialog.selectExisting = false
                        _walletDialog.acceptedCallback = walletAdapter.messagesTableModel.save
                        _walletDialog.visible = true
                    }
                }

                UNButton {
                    Layout.preferredWidth: implicitWidth
                    Layout.maximumWidth: implicitWidth
                    Layout.minimumWidth: implicitWidth
                    Layout.alignment: Qt.AlignVCenter
                    activeColor:Theme.messageDetailsDialogButtonActiveColor
                    baseColor: Theme.messageDetailsDialogButtonColor
                    textColor: Theme.messageDetailsDialogButtonTextColor
                    height:  Theme.messageDetailsDialogButtonheight
                    lableTextSize: Theme.messageDetailsDialogButtonFontSize
                    enabled: "" !== _dialog.model.msgAttachment

                    text: qsTr("Download attachment")

                    onClicked: {
                        _walletDialog.selectFolder = true
                        _walletDialog.selectExisting = true
                        _walletDialog.acceptedCallback = walletAdapter.messagesTableModel.download
                        _walletDialog.visible = true
                    }
                }

                UNLayoutSpacer {}
                UNButton {

                    Layout.preferredWidth: implicitWidth
                    Layout.maximumWidth: implicitWidth
                    Layout.minimumWidth: implicitWidth
                    Layout.alignment: Qt.AlignVCenter
                    activeColor:Theme.messageDetailsDialogButtonActiveColor
                    baseColor: Theme.messageDetailsDialogButtonColor
                    textColor: Theme.messageDetailsDialogButtonTextColor
                    width: Theme.messageDetailsDialogButtonwidth
                    height:  Theme.messageDetailsDialogButtonheight
                    lableTextSize: Theme.messageDetailsDialogButtonFontSize
                    enabled: 0 < _dialog.currentRow

                    text: "<<"

                    onClicked: {
                        _dialog.currentRow -= 1
                        _dialog.model.setupMessageDetails(_dialog.currentRow)
                    }
                }

                UNButton {
                    Layout.preferredWidth: implicitWidth
                    Layout.maximumWidth: implicitWidth
                    Layout.minimumWidth: implicitWidth
                    Layout.alignment: Qt.AlignVCenter
                    activeColor:Theme.messageDetailsDialogButtonActiveColor
                    baseColor: Theme.messageDetailsDialogButtonColor
                    textColor: Theme.messageDetailsDialogButtonTextColor
                    width: Theme.messageDetailsDialogButtonwidth
                    height:  Theme.messageDetailsDialogButtonheight
                    lableTextSize: Theme.messageDetailsDialogButtonFontSize
                    enabled: _dialog.model.rowCount > (_dialog.currentRow + 1)

                    text: ">>"

                    onClicked: {
                        _dialog.currentRow += 1
                        _dialog.model.setupMessageDetails(_dialog.currentRow)
                    }
                }
            }
        }
    }
}
