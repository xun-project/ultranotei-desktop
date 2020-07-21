import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.13
import QtQuick.Layouts 1.13

import UltraNote.UI 1.0
import UltraNote.UI.Controls 1.0

UNDialog {
    id: _dialog

    property bool  unlocking: false
    property alias error: _errorLabel.visible

    function setFocusOnPass() {
        if(!_passwordField.activeFocus){
            console.log("setFocusOnPass")
            _passwordField.forceActiveFocus()
        }
    }

    function clear() {
        _passwordField.text = ''
    }

    function acceptPassword() {
        if ('' === _passwordField.text) {
            _requestPasswordDialog.open()
            return
        }
        if(!_dialog.unlocking)
        {walletAdapter.open(_passwordField.text)
        }
        else
        {walletAdapter.removeLock(_passwordField.text)
        }
        _requestPasswordDialog.close()
    }

    function cancelPassword(){
        _requestPasswordDialog.close()
        walletAdapter.isWalletOpen = false
        if(!_dialog.unlocking){
            _walletDialog.selectFolder = false
            _walletDialog.selectExisting = false
            _walletDialog.title = qsTr("New wallet file")
            _walletDialog.defaultSuffix = "wallet"
            _walletDialog.nameFilters = ["Wallet Files (*.wallet)"]
            _walletDialog.acceptedCallback = walletAdapter.createWallet
            _walletDialog.open()
        }
    }

    buttons: ListModel {
        ListElement { type: UNDialog.ButtonType.TypeNormal; role: DialogButtonBox.AcceptRole; text: qsTr("Accept")}
        ListElement { type: UNDialog.ButtonType.TypeNormal; role: DialogButtonBox.RejectRole; text: qsTr("Cancel")}
    }

    implicitWidth: 400
    closePolicy: Popup.NoAutoClose
    onAccepted: _dialog.acceptPassword()
    onRejected: _dialog.cancelPassword()
    title: qsTr("Enter password")
    modal: true

    Item {
        id: _contentItem

        anchors.left: parent.left
        anchors.right: parent.right

        height: _contentData.height
        implicitHeight: height

        clip: true
        focus: _dialog.visible

        onFocusChanged: {
            console.log("focus changed")
            _passwordField.forceActiveFocus()
        }

        Component.onCompleted: {
            console.log("component completed")
            if(!_passwordField.activeFocus)
                _passwordField.forceActiveFocus()
        }

        ColumnLayout {
            id: _contentData

            anchors.left: parent.left
            anchors.right: parent.right

            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: implicitHeight
                Layout.maximumHeight: implicitHeight
                Layout.minimumHeight: implicitHeight

                spacing: 24

                UNLabel {
                    id: _passwordLabel

                    Layout.preferredWidth: implicitWidth
                    Layout.maximumWidth: implicitWidth
                    Layout.minimumWidth: implicitWidth
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

                    text: qsTr("Password:")
                }

                UNTextField {
                    id: _passwordField

                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter

                    echoMode: TextInput.Password
                    focus: _dialog.visible
                    onTextChanged: _dialog.error = false

                    Keys.onReturnPressed: _dialog.acceptPassword()
                }
            }

            UNLayoutSpacer {
                fixedHeight: 8

                visible: _errorLabel.visible
            }

            UNLabel {
                id: _errorLabel

                Layout.fillWidth: true
                Layout.preferredHeight: implicitHeight
                Layout.maximumHeight: implicitHeight
                Layout.minimumHeight: implicitHeight

                type: UNLabel.Type.TypeNormal

                lineHeight: 17
                lineHeightMode: Label.FixedHeight
                color: Theme.errorColor
                elide: Label.ElideNone
                wrapMode: Label.WordWrap
                maximumLineCount: 10
                horizontalAlignment: Label.AlignHCenter
                verticalAlignment: Label.AlignVCenter

                text: qsTr("Wrong password")
            }
        }
    }
}
