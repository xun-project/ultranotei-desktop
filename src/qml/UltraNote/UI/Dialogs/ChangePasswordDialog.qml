import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.13
import QtQuick.Layouts 1.13

import UltraNote.UI 1.0
import UltraNote.UI.Controls 1.0

UNDialog {
    id: _dialog

    property bool changePwd: false

    function clear() {
        _newPasswordField.text = ''
        _confirmField.text = ''
        _oldPasswordField.text = ''
    }

    function acceptPassword() {
        if (('' === _newPasswordField.text) || (_newPasswordField.text !== _confirmField.text)) {
            _changePasswordDialog.open()
            return
        }
        if (!_dialog.changePwd) {
            walletAdapter.encryptWallet(_oldPasswordField.text, _newPasswordField.text)
        } else if (!walletAdapter.encryptWallet(_oldPasswordField.text, _newPasswordField.text)) {
            _changePasswordDialog.open()
            return
        }
        _changePasswordDialog.close()
    }

    buttons: ListModel {
        ListElement { type: UNDialog.ButtonType.TypeNormal; role: DialogButtonBox.AcceptRole; text: qsTr("Accept")}
        ListElement { type: UNDialog.ButtonType.TypeNormal; role: DialogButtonBox.RejectRole; text: qsTr("Cancel")}
    }

    title: _dialog.changePwd ? qsTr("Change password") : qsTr("Set password")
    closePolicy: Popup.NoAutoClose
    modal: true
    implicitWidth: 400
    onAccepted: _dialog.acceptPassword()
    onRejected: _changePasswordDialog.close()


    Item {
        id: _contentItem

        anchors.left: parent.left
        anchors.right: parent.right

        height: _contentData.height
        implicitHeight: height

        clip: true
        focus: _dialog.visible

        onFocusChanged: {
            if(!_dialog.changePwd){
                if(!_newPasswordField.activeFocus){
                    _newPasswordField.forceActiveFocus()
                }
            }else {
                if(!_oldPasswordField.activeFocus){
                    _oldPasswordField.forceActiveFocus()
                }
            }
        }

        ColumnLayout {
            id: _contentData

            anchors.left: parent.left
            anchors.right: parent.right

            spacing: 0

            Keys.onReturnPressed: _dialog.acceptPassword()
            focus: _dialog.visible

            property int labelWidth: Math.max(
                                         (_oldPasswordLabel.visible ? _oldPasswordLabel.implicitWidth : 0),
                                         (_newPasswordLabel.visible ? _newPasswordLabel.implicitWidth : 0),
                                         (_confirmLabel.visible ? _confirmLabel.implicitWidth : 0)
                                         )

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: implicitHeight
                Layout.maximumHeight: implicitHeight
                Layout.minimumHeight: implicitHeight

                height: 48

                visible: _dialog.changePwd
                focus: _dialog.visible

                spacing: 24

                UNLabel {
                    id: _oldPasswordLabel

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

                    text: qsTr("Old password:")
                }

                UNTextField {
                    id: _oldPasswordField

                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter

                    echoMode: TextInput.Password
                    focus: _dialog.visible
                }
            }

            UNLayoutSpacer {
                fixedHeight: 8
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: implicitHeight
                Layout.maximumHeight: implicitHeight
                Layout.minimumHeight: implicitHeight

                spacing: 24
                focus: _dialog.visible

                UNLabel {
                    id: _newPasswordLabel

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
                    text: _dialog.changePwd ? qsTr("New password:") : qsTr("Password:")
                }

                UNTextField {
                    id: _newPasswordField

                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter

                    echoMode: TextInput.Password
                    focus: _dialog.visible
                }
            }

            UNLayoutSpacer {
                fixedHeight: 8
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: implicitHeight
                Layout.maximumHeight: implicitHeight
                Layout.minimumHeight: implicitHeight

                spacing: 24

                UNLabel {
                    id: _confirmLabel

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

                    text: qsTr("Confirm:")
                }

                UNTextField {
                    id: _confirmField

                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter

                    echoMode: TextInput.Password
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

                visible: _newPasswordField.text !== _confirmField.text

                type: UNLabel.Type.TypeNormal

                lineHeight: 17
                lineHeightMode: Label.FixedHeight
                color: Theme.errorColor
                elide: Label.ElideNone
                wrapMode: Label.WordWrap
                maximumLineCount: 10
                horizontalAlignment: Label.AlignHCenter
                verticalAlignment: Label.AlignVCenter

                text: qsTr("Password not confirmed")
            }
        }
    }
}
