import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.13
import QtQuick.Layouts 1.13

import UltraNote.UI 1.0
import UltraNote.UI.Controls 1.0

UNDialogInfinity {
    id: _dialog

    headerAlignmentCenter: true

    implicitWidth: 430
    closePolicy: Popup.NoAutoClose
    title: qsTr("IMPORT WALLET")
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

            UNButton {
                Layout.fillWidth: true
                text: qsTr("IMPORT PRIVATE KEYS")
                onClicked: {
                    _importPrivateKeysDialog.open()
                    _dialog.close()
                }
            }

            UNLayoutSpacer {
                fixedHeight: 20
            }

            UNButton {
                Layout.fillWidth: true
                text: qsTr("IMPORT TRACKING WALLET")
                onClicked: {
                    _ImportTrackingWalletDialog.open()
                    _dialog.close()
                }
            }

            UNLayoutSpacer {
                fixedHeight: 20
            }

            UNButton {
                Layout.fillWidth: true
                text: qsTr("IMPORT SEED")
                onClicked: {
                    _ImportSeedDialog.open()
                    _dialog.close()
                }
            }

            UNLayoutSpacer {
                fixedHeight: 20
            }

            UNButton {
                Layout.fillWidth: true
                text: qsTr("CLOSE")
                activeBorderColor: "#444444"
                onClicked: _dialog.close()
            }
        }
    }
}
