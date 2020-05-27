import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.13
import QtQuick.Layouts 1.13

import UltraNote.UI 1.0
import UltraNote.UI.Controls 1.0

UNDialog {
    id: _dialog

    implicitWidth: 500

    buttons: ListModel {
        ListElement { type: UNDialog.ButtonType.TypeNormal; role: DialogButtonBox.RejectRole; text: qsTr("Close")}
    }

    title: qsTr("Transaction details")
    closePolicy: Popup.CloseOnEscape
    modal: true

    Action {
        id: focus
        shortcut: StandardKey.Copy
        onTriggered: if(_transactionDetailsText.focus) clipboard.setText(_transactionDetailsText.selectedText)
    }

    Flickable {
        id: _contentItem

        anchors.left: parent.left
        anchors.right: parent.right

        height: 400
        implicitHeight: height

        boundsBehavior: Flickable.StopAtBounds

        ScrollIndicator.vertical: ScrollIndicator {
            orientation: Qt.Vertical
            visible: _contentItem.height < _contentItem.contentHeight
            background: Item {}

            contentItem: Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter

                height: 200
                implicitWidth: 4
                implicitHeight: 200
                radius: width / 2

                color: Theme.scrollIndicatorColor
            }
        }

        contentHeight: _contentData.height

        clip: true

        ColumnLayout {
            id: _contentData

            anchors.left: parent.left
            anchors.right: parent.right

            spacing: 0

            UNLabelSelectable {
                id: _transactionDetailsText
                Layout.fillWidth: true
                Layout.preferredHeight: implicitHeight
                Layout.maximumHeight: implicitHeight
                Layout.minimumHeight: implicitHeight
                Layout.rightMargin: 8

                type: UNLabel.Type.TypeNormal

                color: Theme.dialogTextColor
                wrapMode: Label.WrapAnywhere
                horizontalAlignment: Label.AlignLeft
                verticalAlignment: Label.AlignVCenter

                focus: _dialog.visible
                text: walletAdapter.transactionsTableModel.transactionDetails
            }
        }
    }
}
