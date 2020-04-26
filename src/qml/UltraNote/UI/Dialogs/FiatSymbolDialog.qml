import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.13
import QtQuick.Layouts 1.13

import UltraNote.UI 1.0
import UltraNote.UI.Controls 1.0

UNDialog {
    id: _dialog

    property int selectedIndex: 0
    property var fiatModel: ListModel{}

    implicitWidth: 300

    buttons: ListModel {
        ListElement { type: UNDialog.ButtonType.TypeNormal; role: DialogButtonBox.RejectRole; text: qsTr("Cancel")}
    }

    title: qsTr("Select Fiat Symbol")
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    modal: true

    Item {
        id: _contentItem

        anchors.left: parent.left
        anchors.right: parent.right

        height: 300
        implicitHeight: height

        clip: true

        ListView {
            id: _fiatListView

            anchors.fill: parent

            ScrollIndicator.vertical: ScrollIndicator {
                orientation: Qt.Vertical
                visible: _fiatListView.height < _fiatListView.contentItem.height
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

            model: _dialog.fiatModel

            delegate: UNRadioButton {
                anchors.left: parent.left
                anchors.right: parent.right

                height: 40

                textColor: Theme.dialogTextColor
                frameColor: Theme.dialogTextColor
                activeColor: "#1A237E"

                checkable: true
                checked: index === _dialog.selectedIndex

                text: modelData

                onClicked: {
                    _dialog.selectedIndex = index
                    _dialog.accepted()
                    _dialog.accept()
                }
            }
        }
    }
}
