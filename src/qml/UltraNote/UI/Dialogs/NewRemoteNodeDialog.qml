import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.13
import QtQuick.Layouts 1.13

import UltraNote.UI 1.0
import UltraNote.UI.Controls 1.0

UNDialog {
    id: _dialog

    function acceptAction() {
        if ('' === _hostField.text) {
            _newRemoteNodeDialog.open()
            return
        }
        walletAdapter.nodeModel.addNode(_hostField.text, _portSpinBox.value)
        _newRemoteNodeDialog.close()
    }

    buttons: ListModel {
        ListElement { type: UNDialog.ButtonType.TypeNormal; role: DialogButtonBox.AcceptRole; text: qsTr("Accept")}
        ListElement { type: UNDialog.ButtonType.TypeNormal; role: DialogButtonBox.RejectRole; text: qsTr("Cancel")}
    }

    implicitWidth: 400
    closePolicy: Popup.CloseOnEscape
    onAccepted: _dialog.acceptAction()
    onRejected: _newRemoteNodeDialog.close()
    title: qsTr("Set node")
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

            focus: true

            Keys.onReturnPressed: _dialog.acceptPassword()

            property int labelWidth: Math.max(_hostLabel.implicitWidth, _portLabel.implicitWidth)

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: implicitHeight
                Layout.maximumHeight: implicitHeight
                Layout.minimumHeight: implicitHeight

                spacing: 24

                UNLabel {
                    id: _hostLabel

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

                    text: qsTr("Host:")
                }

                UNTextField {
                    id: _hostField

                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter

                    echoMode: TextInput.Password
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
                    id: _portLabel

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

                    text: qsTr("Port:")
                }

                UNLayoutSpacer{}

                UNSpinBox {
                    id: _portSpinBox

                    Layout.preferredWidth: implicitWidth
                    Layout.maximumWidth: implicitWidth
                    Layout.minimumWidth: implicitWidth
                    Layout.alignment: Qt.AlignVCenter

                    Material.theme: Material.Dark
                    Material.accent: Theme.dialogSpinBoxActiveColor
                    Material.foreground: Theme.dialogSpinBoxTextColor

                    value: walletAdapter.defaultDaemonPort
                    from: 0
                    to: 65535
                    validator: IntValidator { bottom: 0; top: 65535 }
                    editable: true
                }
            }
        }
    }
}
