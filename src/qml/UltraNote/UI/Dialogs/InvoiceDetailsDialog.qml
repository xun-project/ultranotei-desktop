import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.13
import QtQuick.Layouts 1.13

import UltraNote.UI 1.0
import UltraNote.UI.Controls 1.0

UNDialog {
    id: _dialog

    property int currentRow: -1
    property var model: walletAdapter.invoicesTableModel

    buttons: ListModel {
        ListElement { type: UNDialog.ButtonType.TypeNormal; role: DialogButtonBox.RejectRole; text: qsTr("Close")}
    }

    implicitWidth: Theme.messageDetailsDialogWindowWidth
    closePolicy: Popup.CloseOnEscape
    title: qsTr("Invoice details")
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
                walletAdapter.invoicesTableModel.cancelDownload()
            }
        }

        Connections {
            target: walletAdapter.invoicesTableModel
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
                                         _invoiceIdLabel.implicitWidth,
                                         _paymentIdLabel.implicitWidth,
                                         _blockHeightLabel.implicitWidth,
                                         _transactionHashLabel.implicitWidth,
                                         _amountLabel.implicitWidth,
                                         _senderAddressLabel.implicitWidth,
                                         _invoiceSizeLabel.implicitWidth
                                         )

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: implicitHeight
                Layout.maximumHeight: implicitHeight
                Layout.minimumHeight: implicitHeight

                spacing: 24

                UNLabel {
                    id: _invoiceIdLabel

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

                    text: qsTr("Invoice ID:")
                }

                UNLabel {
                    id: _invoiceId

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

                    text: _dialog.model.invoiceId
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
                    id: _paymentIdLabel

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

                    text: qsTr("Payment ID:")
                }

                UNLabel {
                    id: _paymentId

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

                    text: _dialog.model.paymentId
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

                    text: _dialog.model.invoiceHeight
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

                    text: _dialog.model.invoiceHash
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

                    text: _dialog.model.invoiceAmount
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
                    id: _senderAddressLabel

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

                    text: qsTr("Sender address:")
                }

                UNLabel {
                    id: _senderAddress

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

                    text: _dialog.model.senderAddress
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
                    id: _invoiceSizeLabel

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

                    text: qsTr("Invoice size (bytes):")
                }

                UNLabel {
                    id: _invoiceSize

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

                    text: _dialog.model.invoiceSize
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
                    text: qsTr("Invoice message")
                    wrapMode: Label.WordWrap
                    elide: Label.ElideNone
                }

                UNLayoutSpacer {}
            }

            UNLayoutSpacer {
                fixedHeight: 16
            }

            UNTextArea {
                id: _invoiceTextArea

                Layout.fillWidth: true
                Layout.preferredHeight: 200
                Layout.maximumHeight: 200
                Layout.minimumHeight: 200

                focus: true

                text: _dialog.model.invoiceFullText
                readOnly: true

                textColor: Theme.dialogTextColor

                function copySelected() {
                    clipboard.setText(_invoiceTextArea._textArea.selectedText)
                }

                function selectAll() {
                    _invoiceTextArea._textArea.select(0,_invoiceTextArea.text.length);
                }

                Shortcut {
                    sequence: StandardKey.Copy
                    onActivated: _invoiceTextArea.copySelected()
                    enabled: _dialog.visible
                }

                Shortcut {
                    sequence: StandardKey.SelectAll
                    onActivated: _invoiceTextArea.selectAll()
                }

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
                            _invoiceTextArea.selectAll()
                        }
                    }

                    UNMenuItem {
                        text: qsTr("Copy")

                        onClicked: {
                            _invoiceTextArea.copySelected()
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
                    visible: _dialog.model.hasInvoiceId && _dialog.model.invoiceReplyTo !== ""
                    text: qsTr("Pay")

                    onClicked: {
                        _invoiceDetailsDialog.close()
                        _globalProperties.setupPayMsg(_dialog.model.invoiceReplyTo)
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
                        _walletDialog.acceptedCallback = walletAdapter.invoicesTableModel.save
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
                    enabled: "" !== _dialog.model.invoiceAttachment

                    text: qsTr("Download attachment")

                    onClicked: {
                        _walletDialog.selectFolder = true
                        _walletDialog.selectExisting = true
                        _walletDialog.acceptedCallback = walletAdapter.invoicesTableModel.download
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
                        _dialog.model.setupInvoiceDetails(_dialog.currentRow)
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
                        _dialog.model.setupInvoiceDetails(_dialog.currentRow)
                    }
                }
            }
        }
    }
}
