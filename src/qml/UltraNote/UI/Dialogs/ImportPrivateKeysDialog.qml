import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.13
import QtQuick.Layouts 1.13
import QtQuick.Dialogs 1.2 as OldDialogs

import UltraNote.UI 1.0
import UltraNote.UI.Controls 1.0

UNDialogInfinity {
    id: _dialog

    function showImportKeyDlg() {
        _importPrivateKeysDialog.open()
    }

    function acceptPrivateKey() {
        if ("" === _PrivateSpendkeyTextField.text) {
            _messageDialogProperties.acceptCallback = _dialog.showImportKeyDlg
            _messageDialogProperties.showMessage(qsTr("Error"), qsTr("Spend Key cannot be empty"))
            return
        }
        if ("" === _PrivateViewkeyTextField.text) {
            _messageDialogProperties.acceptCallback = _dialog.showImportKeyDlg
            _messageDialogProperties.showMessage(qsTr("Error"), qsTr("View Key cannot be empty"))
            return
        }
        if ("" === _walletPathField.text) {
            _messageDialogProperties.acceptCallback = _dialog.showImportKeyDlg
            _messageDialogProperties.showMessage(qsTr("Error"), qsTr("Wallet path cannot be empty"))
            return
        }

        walletAdapter.importSecretkeys(_PrivateSpendkeyTextField.text
                                       , _PrivateViewkeyTextField.text
                                       ,_walletPathField.text)

        _PrivateSpendkeyTextField.text = ""
        _PrivateViewkeyTextField.text = ""
        _walletPathField.text = ""

        _importPrivateKeysDialog.close()
        _ImportWalletDialog.close()
    }

    headerAlignmentCenter: true

    implicitWidth: 430
    closePolicy: Popup.NoAutoClose
    title: qsTr("Import private keys")
    modal: true

    Item {
        id: _contentItem

        anchors.left: parent.left
        anchors.right: parent.right

        height: _contentData.height
        implicitHeight: height

        clip: true

        ColumnLayout {
            id: _contentData

            anchors.left: parent.left
            anchors.right: parent.right

            spacing: 0
            UNLabel {
                id: _noteLabel

                Layout.fillWidth: true
                Layout.preferredHeight: implicitHeight
                Layout.maximumHeight: implicitHeight
                Layout.minimumHeight: implicitHeight

                type: UNLabel.Type.TypeNormal

                lineHeight: 17
                lineHeightMode: Label.FixedHeight
                color: Theme.dialogInfinityTextColor
                elide: Label.ElideNone
                wrapMode: Label.WordWrap
                maximumLineCount: 10
                horizontalAlignment: Label.AlignLeft
                verticalAlignment: Label.AlignVCenter

                text: qsTr("Create your wallet with the secret spend and view key")
            }

            UNLayoutSpacer {
                fixedHeight: 30
            }

            UNLabel {
                id: _PrivateSpendKeyLabel

                Layout.fillWidth: true
                Layout.preferredHeight: implicitHeight
                Layout.maximumHeight: implicitHeight
                Layout.minimumHeight: implicitHeight

                type: UNLabel.Type.TypeNormal

                lineHeight: 17
                lineHeightMode: Label.FixedHeight
                color: Theme.dialogInfinityTextColor

                elide: Label.ElideNone
                wrapMode: Label.WordWrap

                horizontalAlignment: Label.AlignLeft
                verticalAlignment: Label.AlignVCenter
                text: "Private Spend Key"
            }
            UNLayoutSpacer {
                fixedHeight: 5
            }
            UNTextField {
                id: _PrivateSpendkeyTextField
                height:35
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                focus: _dialog.visible
            }
            UNLayoutSpacer {
                fixedHeight: 15
            }
            UNLabel {
                id: _PrivateViewKeyLabel

                Layout.fillWidth: true
                Layout.preferredHeight: implicitHeight
                Layout.maximumHeight: implicitHeight
                Layout.minimumHeight: implicitHeight

                type: UNLabel.Type.TypeNormal

                lineHeight: 17
                lineHeightMode: Label.FixedHeight
                color: Theme.dialogInfinityTextColor

                elide: Label.ElideNone
                wrapMode: Label.WordWrap

                horizontalAlignment: Label.AlignLeft
                verticalAlignment: Label.AlignVCenter
                text: "Private View Key"
            }
            UNLayoutSpacer {
                fixedHeight: 5
            }
            UNTextField {
                id: _PrivateViewkeyTextField
                height:35
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                focus: _dialog.visible
            }
            UNLayoutSpacer {
                fixedHeight: 15
            }
            UNLabel {
                id: _WalletPathLabel

                Layout.fillWidth: true
                Layout.preferredHeight: implicitHeight
                Layout.maximumHeight: implicitHeight
                Layout.minimumHeight: implicitHeight

                type: UNLabel.Type.TypeNormal

                lineHeight: 17
                lineHeightMode: Label.FixedHeight
                color: Theme.dialogInfinityTextColor

                elide: Label.ElideNone
                wrapMode: Label.WordWrap

                horizontalAlignment: Label.AlignLeft
                verticalAlignment: Label.AlignVCenter
                text: "Wallet Path"
            }
            UNLayoutSpacer {
                fixedHeight: 5
            }

            RowLayout {
                spacing: 5
                UNTextField {
                    id: _walletPathField
                    height:35
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                }

                UNButton {
                    id: _browseButton
                    Layout.alignment: Qt.AlignVCenter

                    height:35
                    width:50
                    text: "..."
                    activeBorderColor: "#444444"
                    onClicked: _walletPathFileDialog.open()
                }
            }

            UNLayoutSpacer {
                fixedHeight: 30
            }

            UNButton {
                Layout.fillWidth: true
                text: qsTr("IMPORT")
                onClicked: _dialog.acceptPrivateKey()
            }

            UNLayoutSpacer {
                fixedHeight: 15
            }

            UNButton {
                Layout.fillWidth: true
                text: qsTr("CANCEL")
                activeBorderColor: "#444444"
                onClicked:
                {
                    _ImportWalletDialog.close()
                    _importPrivateKeysDialog.close()
                }
            }
        }
    }

    OldDialogs.FileDialog {
        id: _walletPathFileDialog

        visible: false

        selectExisting: false
        folder: shortcuts.home
        title: qsTr("Wallet file")
        defaultSuffix: "wallet"
        nameFilters: ["Wallet Files (*.wallet)"]

        onAccepted: {
            _walletPathField.text = walletAdapter.toLocalFile(_walletPathFileDialog.fileUrl)
        }
    }
}
