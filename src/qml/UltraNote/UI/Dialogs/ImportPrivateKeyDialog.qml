import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.13
import QtQuick.Layouts 1.13
import QtQuick.Dialogs 1.2 as OldDialogs

import UltraNote.UI 1.0
import UltraNote.UI.Controls 1.0

UNDialog {
    id: _dialog

    function showImportKeyDlg() {
        _importPrivateKeyDialog.open()
    }

    function acceptPrivateKey() {
        if ("" === _keyTextField.text) {
            _messageDialogProperties.acceptCallback = _dialog.showImportKeyDlg
            _messageDialogProperties.showMessage(qsTr("Error"), qsTr("Key cannot be empty"))
            return
        }
        if ("" === _walletPathField.text) {
            _messageDialogProperties.acceptCallback = _dialog.showImportKeyDlg
            _messageDialogProperties.showMessage(qsTr("Error"), qsTr("Wallet path cannot be empty"))
            return
        }
        _importPrivateKeyDialog.close()
    }

    buttons: ListModel {
        ListElement { type: UNDialog.ButtonType.TypeNormal; role: DialogButtonBox.AcceptRole; text: qsTr("Accept")}
        ListElement { type: UNDialog.ButtonType.TypeNormal; role: DialogButtonBox.RejectRole; text: qsTr("Cancel")}
    }

    implicitWidth: 500
    closePolicy: Popup.NoAutoClose
    title: qsTr("Import private key")
    modal: true

    onAccepted: _dialog.acceptPrivateKey()
    onRejected: _importPrivateKeyDialog.close()

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

            property int labelWidth: Math.max(_keyLabel.implicitWidth, _walletPathLabel.implicitWidth)

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: implicitHeight
                Layout.maximumHeight: implicitHeight
                Layout.minimumHeight: implicitHeight

                UNLabel {
                    id: _keyLabel

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

                    text: qsTr("Key:")
                }

                UNLayoutSpacer{
                    fixedWidth: 24
                }

                UNTextField {
                    id: _keyTextField

                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter

                    focus: _dialog.visible
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

                UNLabel {
                    id: _walletPathLabel

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

                    text: qsTr("Wallet path:")
                }

                UNLayoutSpacer{
                    fixedWidth: 24
                }


                UNTextField {
                    id: _walletPathField

                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                }

                UNLayoutSpacer{
                    fixedWidth: 16
                }

                UNButton {
                    id: _browseButton

                    Layout.preferredWidth: implicitWidth
                    Layout.maximumWidth: implicitWidth
                    Layout.minimumWidth: implicitWidth
                    Layout.alignment: Qt.AlignVCenter

                    text: qsTr("Browse")

                    onClicked: {
                        _walletPathFileDialog.open()
                    }
                }
            }
        }
    }

    OldDialogs.FileDialog {
        id: _walletPathFileDialog

        visible: false

        selectExisting: false
        folder: shortcuts.home
        title: qsTr("New wallet file")
        defaultSuffix: "wallet"
        nameFilters: ["Wallet Files (*.wallet)"]

        onAccepted: {
            _walletPathField.text = walletAdapter.toLocalFile(_walletPathFileDialog.fileUrl)
        }
    }
}
