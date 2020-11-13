import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.13
import QtQuick.Layouts 1.13

import UltraNote.UI 1.0
import UltraNote.UI.Controls 1.0

UNDialogInfinity {
    id: _dialog

    headerAlignmentCenter: true

    implicitWidth: 470
    closePolicy: Popup.NoAutoClose
    title: qsTr("Settings was changed")
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

                text: qsTr("Please restart the wallet for the new settings to take effect.")
            }

            UNLayoutSpacer {
                fixedHeight: 30
            }

            UNButton {
                Layout.fillWidth: true
                text: qsTr("Restart now")
                onClicked:
                {
                    _appWindow.close()
                    walletAdapter.restartWallet()
                }
            }

            UNLayoutSpacer {
                fixedHeight: 20
            }

            UNButton {
                Layout.fillWidth: true
                text: qsTr("Restart later")
                activeBorderColor: "#444444"
                onClicked: _dialog.close()
            }
        }
    }
}
