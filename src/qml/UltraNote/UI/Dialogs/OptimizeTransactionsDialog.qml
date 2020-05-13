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
    title: qsTr("OPTIMIZE WALLET")
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

                text: qsTr("This process will optimize your wallet for large transactions.\nThe optimization will take approximately 22 minutes. Please\nnote that you will not be able to spend any of your funds\nuntil the optimization process is complete. In some cases,\nthe wallet might need optimization more than once.")
            }

            UNLayoutSpacer {
                fixedHeight: 30
            }

            UNLabel {
                id: _errorLabel2

                Layout.fillWidth: true
                Layout.preferredHeight: implicitHeight
                Layout.maximumHeight: implicitHeight
                Layout.minimumHeight: implicitHeight

                type: UNLabel.Type.TypeBold

                lineHeight: 20
                lineHeightMode: Label.FixedHeight
                color: Theme.dialogInfinityTextColor
                elide: Label.ElideNone
                wrapMode: Label.WordWrap
                maximumLineCount: 10
                horizontalAlignment: Label.AlignHCenter
                verticalAlignment: Label.AlignVCenter

                text: walletAdapter.optimizationState
            }

            UNLayoutSpacer {
                fixedHeight: 30
            }

            UNButton {
                Layout.fillWidth: true
                text: qsTr("OPTIMIZE")
                onClicked: walletAdapter.optimizeClicked()
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
