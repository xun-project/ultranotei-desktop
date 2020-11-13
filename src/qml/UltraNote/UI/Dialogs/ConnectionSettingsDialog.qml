import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.13
import QtQuick.Layouts 1.13

import WalletAdapter 1.0
import UltraNote.UI 1.0
import UltraNote.UI.Controls 1.0

UNDialog {
    id: _dialog

    buttons: ListModel {
        ListElement { type: UNDialog.ButtonType.TypeNormal; role: DialogButtonBox.AcceptRole; text: qsTr("Save")}
        ListElement { type: UNDialog.ButtonType.TypeNormal; role: DialogButtonBox.RejectRole; text: qsTr("Cancel")}
    }

    implicitWidth: 800

    closePolicy: Popup.CloseOnEscape
    onAccepted: {
        walletAdapter.saveConnectionSettings()
        _dialog.close()
        _RestartWalletDialog.open()
    }
    onRejected: _connectionSettingsDialog.close()
    title: qsTr("Connection settings")
    modal: true

    Item {
        id: _contentItem

        anchors.left: parent.left
        anchors.right: parent.right

        height: _contentData.height
        implicitHeight: height

        ButtonGroup { id: _connectionModeButtonGroup }

        ColumnLayout {
            id: _contentData

            anchors.left: parent.left
            anchors.right: parent.right

            spacing: 0

            UNRadioButton {
                id: _autoSelectionRadioButton

                Layout.fillWidth: true
                Layout.preferredHeight: implicitHeight
                Layout.maximumHeight: implicitHeight
                Layout.minimumHeight: implicitHeight

                textColor: Theme.dialogTextColor
                frameColor: Theme.dialogTextColor
                activeColor: "#1A237E"

                ButtonGroup.group: _connectionModeButtonGroup

                text: qsTr("Auto selection")

                checked: WalletAdapter.CONNECTION_MODE_AUTO === walletAdapter.connectionMode
                onCheckedChanged: {
                    if (checked) {
                        walletAdapter.connectionMode = WalletAdapter.CONNECTION_MODE_AUTO
                    }
                }
            }

            UNLayoutSpacer {
                fixedHeight: 8
            }

            UNLabel {
                Layout.fillWidth: true
                Layout.preferredHeight: implicitHeight
                Layout.maximumHeight: implicitHeight
                Layout.minimumHeight: implicitHeight

                type: UNLabel.Type.TypeNormal

                lineHeight: 17
                lineHeightMode: Label.FixedHeight
                color: Theme.dialogTextColor
                elide: Label.ElideNone
                wrapMode: Label.WordWrap
                maximumLineCount: 10
                horizontalAlignment: Label.AlignLeft
                verticalAlignment: Label.AlignVCenter

                text: qsTr("Wallet will connect to local daemon on default port. In case of no local daemon running it will launch build-in node.")
            }

            UNLayoutSpacer {
                fixedHeight: 16
            }

            UNRadioButton {
                id: _embeddedRadioButton

                Layout.fillWidth: true
                Layout.preferredHeight: implicitHeight
                Layout.maximumHeight: implicitHeight
                Layout.minimumHeight: implicitHeight

                textColor: Theme.dialogTextColor
                frameColor: Theme.dialogTextColor
                activeColor: "#1A237E"

                ButtonGroup.group: _connectionModeButtonGroup

                text: qsTr("Embedded")

                checked: WalletAdapter.CONNECTION_MODE_EMBEDDED === walletAdapter.connectionMode
                onCheckedChanged: {
                    if (checked) {
                        walletAdapter.connectionMode = WalletAdapter.CONNECTION_MODE_EMBEDDED
                    }
                }
            }

            UNLayoutSpacer {
                fixedHeight: 8
            }

            UNLabel {
                Layout.fillWidth: true
                Layout.preferredHeight: implicitHeight
                Layout.maximumHeight: implicitHeight
                Layout.minimumHeight: implicitHeight

                type: UNLabel.Type.TypeNormal

                lineHeight: 17
                lineHeightMode: Label.FixedHeight
                color: Theme.dialogTextColor
                elide: Label.ElideNone
                wrapMode: Label.WordWrap
                maximumLineCount: 10
                horizontalAlignment: Label.AlignLeft
                verticalAlignment: Label.AlignVCenter

                text: qsTr("Build-in embedded node will be used.")
            }

            UNLayoutSpacer {
                fixedHeight: 16
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: implicitHeight
                Layout.maximumHeight: implicitHeight
                Layout.minimumHeight: implicitHeight

                UNRadioButton {
                    id: _localDaemonRadioButton

                    Layout.preferredWidth: implicitWidth
                    Layout.maximumWidth: implicitWidth
                    Layout.minimumWidth: implicitWidth
                    Layout.alignment: Qt.AlignVCenter

                    textColor: Theme.dialogTextColor
                    frameColor: Theme.dialogTextColor
                    activeColor: "#1A237E"

                    ButtonGroup.group: _connectionModeButtonGroup

                    text: qsTr("Local daemon")

                    checked: WalletAdapter.CONNECTION_MODE_LOCAL === walletAdapter.connectionMode
                    onCheckedChanged: {
                        if (checked) {
                            walletAdapter.connectionMode = WalletAdapter.CONNECTION_MODE_LOCAL
                        }
                    }
                }

                UNLayoutSpacer{}

                UNLabel {
                    Layout.preferredWidth: implicitWidth
                    Layout.maximumWidth: implicitWidth
                    Layout.minimumWidth: implicitWidth
                    Layout.alignment: Qt.AlignVCenter

                    type: UNLabel.Type.TypeNormal

                    color: Theme.dialogTextColor
                    elide: Label.ElideNone
                    wrapMode: Label.WordWrap
                    maximumLineCount: 10
                    horizontalAlignment: Label.AlignLeft
                    verticalAlignment: Label.AlignVCenter

                    text: qsTr("Port:")
                }

                UNSpinBox {
                    id: _localDaemonPortSpinBox

                    Layout.preferredWidth: implicitWidth
                    Layout.maximumWidth: implicitWidth
                    Layout.minimumWidth: implicitWidth
                    Layout.alignment: Qt.AlignVCenter

                    Material.theme: Material.Dark
                    Material.accent: Theme.dialogSpinBoxActiveColor
                    Material.foreground: Theme.dialogSpinBoxTextColor

                    enabled: _localDaemonRadioButton.checked

                    value: walletAdapter.localDaemonPort

                    from: 0
                    to: 65535
                    validator: IntValidator { bottom: 0; top: 65535 }
                    editable: true
                    onValueChanged: walletAdapter.localDaemonPort = value
                }
            }

            UNLayoutSpacer {
                fixedHeight: 8
            }

            UNLabel {
                Layout.fillWidth: true
                Layout.preferredHeight: implicitHeight
                Layout.maximumHeight: implicitHeight
                Layout.minimumHeight: implicitHeight

                type: UNLabel.Type.TypeNormal

                lineHeight: 17
                lineHeightMode: Label.FixedHeight
                color: Theme.dialogTextColor
                elide: Label.ElideNone
                wrapMode: Label.WordWrap
                maximumLineCount: 10
                horizontalAlignment: Label.AlignLeft
                verticalAlignment: Label.AlignVCenter

                text: qsTr("Wallet will connect to local daemon on specified port.")
            }

            UNLayoutSpacer {
                fixedHeight: 16
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: implicitHeight
                Layout.maximumHeight: implicitHeight
                Layout.minimumHeight: implicitHeight

                UNRadioButton {
                    id: _remoteDaemonRadioButton

                    Layout.preferredWidth: implicitWidth
                    Layout.maximumWidth: implicitWidth
                    Layout.minimumWidth: implicitWidth
                    Layout.alignment: Qt.AlignVCenter

                    textColor: Theme.dialogTextColor
                    frameColor: Theme.dialogTextColor
                    activeColor: "#1A237E"

                    ButtonGroup.group: _connectionModeButtonGroup

                    text: qsTr("Remote daemon")

                    checked: WalletAdapter.CONNECTION_MODE_REMOTE === walletAdapter.connectionMode
                    onCheckedChanged: {
                        if (checked) {
                            walletAdapter.connectionMode = WalletAdapter.CONNECTION_MODE_REMOTE
                        }
                    }
                }

                UNLayoutSpacer{}

                UNLabel {
                    Layout.preferredWidth: implicitWidth
                    Layout.maximumWidth: implicitWidth
                    Layout.minimumWidth: implicitWidth
                    Layout.alignment: Qt.AlignVCenter

                    type: UNLabel.Type.TypeNormal

                    color: Theme.dialogTextColor
                    elide: Label.ElideNone
                    wrapMode: Label.WordWrap
                    maximumLineCount: 10
                    horizontalAlignment: Label.AlignLeft
                    verticalAlignment: Label.AlignVCenter

                    text: qsTr("Address:")
                }

                ComboBox {
                    id: addressCombo

                    Layout.preferredWidth: 300
                    Layout.maximumWidth: 300
                    Layout.minimumWidth: 300
                    Layout.alignment: Qt.AlignVCenter

                    enabled: _remoteDaemonRadioButton.checked
                    popup.z: 2000
                    textRole: "display"
                    model: walletAdapter.nodeModel
                    currentIndex: walletAdapter.nodeModel.currentIndex
                    onCurrentIndexChanged: walletAdapter.nodeModel.currentIndex = currentIndex
                }

                UNLayoutSpacer{
                    fixedWidth: 16
                }

                UNButton {
                    Layout.preferredWidth: implicitWidth
                    Layout.maximumWidth: implicitWidth
                    Layout.minimumWidth: implicitWidth
                    Layout.alignment: Qt.AlignVCenter

                    enabled: _remoteDaemonRadioButton.checked

                    text: qsTr("Add node")

                    onClicked: {
                        _newRemoteNodeDialog.open()
                    }
                }
            }

            UNLayoutSpacer {
                fixedHeight: 8
            }

            UNLabel {
                Layout.fillWidth: true
                Layout.preferredHeight: implicitHeight
                Layout.maximumHeight: implicitHeight
                Layout.minimumHeight: implicitHeight

                type: UNLabel.Type.TypeNormal

                lineHeight: 17
                lineHeightMode: Label.FixedHeight
                color: Theme.dialogTextColor
                elide: Label.ElideNone
                wrapMode: Label.WordWrap
                maximumLineCount: 10
                horizontalAlignment: Label.AlignLeft
                verticalAlignment: Label.AlignVCenter

                text: qsTr("Wallet will connect to remote node running in local or global network. Please select node or specify IP address or domain name and port.")
            }
        }
    }
}
