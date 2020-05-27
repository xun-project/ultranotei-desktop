import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.13
import QtQuick.Layouts 1.13

import UltraNote.UI 1.0
import UltraNote.UI.Controls 1.0

UNDialogInfinity {
    id: _dialog

    headerAlignmentCenter: true

    implicitWidth: 800
    closePolicy: Popup.NoAutoClose
    title: qsTr("YOUR 25 MNEMONIC SEED")
    modal: true

    Action {
        id: focus
        shortcut: StandardKey.Copy
        onTriggered: {
            if(_mnemonicSeedText.focus) clipboard.setText(_mnemonicSeedText.selectedText)
            if(_guiKeyText.focus) clipboard.setText(_guiKeyText.selectedText)
        }
    }

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
                id: _mnemonicSeedLabel

                Layout.fillWidth: true
                Layout.preferredHeight: implicitHeight
                Layout.maximumHeight: implicitHeight
                Layout.minimumHeight: implicitHeight

                type: UNLabel.Type.TypeBold
                size:16

                lineHeight: 17
                lineHeightMode: Label.FixedHeight
                color: Theme.dialogInfinityTitleTextColor

                elide: Label.ElideNone
                wrapMode: Label.WordWrap

                horizontalAlignment: Label.AlignLeft
                verticalAlignment: Label.AlignVCenter
                text: "YOUR 25 WORD MNEMONIC SEED"
            }

            UNLayoutSpacer {
                fixedHeight: 10
            }

            RowLayout {
                UNLabelSelectable {
                    id: _mnemonicSeedText
                    Layout.fillWidth: true
                    Layout.preferredHeight: implicitHeight
                    Layout.maximumHeight: implicitHeight
                    Layout.minimumHeight: implicitHeight
                    Layout.rightMargin: 8

                    isReachText:false

                    type: UNLabel.Type.TypeNormal

                    color: Theme.dialogInfinityTextColor

                    wrapMode: Label.WrapAnywhere
                    horizontalAlignment: Label.AlignLeft
                    verticalAlignment: Label.AlignVCenter

                    focus: _dialog.visible

                    text: walletAdapter.mnemonicSeed
                }
                UNLayoutSpacer {
                    fixedHeight: 20
                }
                UNIcon {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter

                    size: 24
                    source: "qrc:/icons/resources/icons/clipboard_copy_icon.svg"
                    toolTip: qsTr("Copy to Clipboard")
                    color: Theme.barcodeIconColor
                    clickable: true

                    onClicked: clipboard.setText(walletAdapter.mnemonicSeed)
                }
            }

            UNLayoutSpacer {
                fixedHeight: 40
            }
            UNLabel {
                id: _guiKeyLabel

                Layout.fillWidth: true
                Layout.preferredHeight: implicitHeight
                Layout.maximumHeight: implicitHeight
                Layout.minimumHeight: implicitHeight

                type: UNLabel.Type.TypeBold
                size:16

                lineHeight: 17
                lineHeightMode: Label.FixedHeight
                color: Theme.dialogInfinityTitleTextColor

                elide: Label.ElideNone
                wrapMode: Label.WordWrap

                horizontalAlignment: Label.AlignLeft
                verticalAlignment: Label.AlignVCenter
                text: "YOUR TRACKING KEY"
            }

            UNLayoutSpacer {
                fixedHeight: 10
            }

            RowLayout {
                UNLabelSelectable {
                    id: _guiKeyText
                    Layout.fillWidth: true
                    Layout.preferredHeight: implicitHeight
                    Layout.maximumHeight: implicitHeight
                    Layout.minimumHeight: implicitHeight
                    Layout.rightMargin: 8

                    type: UNLabel.Type.TypeNormal

                    isReachText:false

                    color: Theme.dialogInfinityTextColor

                    wrapMode: Label.WrapAnywhere
                    horizontalAlignment: Label.AlignLeft
                    verticalAlignment: Label.AlignVCenter

                    focus: _dialog.visible

                    text: walletAdapter.guiKey
                }
                UNLayoutSpacer {
                    fixedHeight: 20
                }
                UNIcon {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter

                    size: 24
                    source: "qrc:/icons/resources/icons/clipboard_copy_icon.svg"
                    toolTip: qsTr("Copy to Clipboard")
                    color: Theme.barcodeIconColor
                    clickable: true

                    onClicked: clipboard.setText(walletAdapter.guiKey)
                }
            }
            UNLayoutSpacer {
                fixedHeight: 30
            }

            UNButton {
                Layout.fillWidth: true
                text: qsTr("CANCEL")
                activeBorderColor: "#444444"
                onClicked: _dialog.close()
            }
        }
    }
}
