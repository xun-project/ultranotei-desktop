import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.13
import QtQuick.Layouts 1.13

import UltraNote.UI 1.0
import UltraNote.UI.Controls 1.0

UNDialog {
    id: _dialog

    function acceptAction() {
        if (-1 !== _tableView.selectedRow) {
            walletAdapter.addressBookTableModel.selectedRow = _tableView.selectedRow
            _tableView.selectedRow = -1
            _addressBookDialog.close()
        } else {
            _addressBookDialog.open()
        }
    }

    buttons: ListModel {
        ListElement { type: UNDialog.ButtonType.TypeNormal; role: DialogButtonBox.AcceptRole; text: qsTr("Accept")}
        ListElement { type: UNDialog.ButtonType.TypeNormal; role: DialogButtonBox.RejectRole; text: qsTr("Cancel")}
    }

    implicitWidth: 600
    closePolicy: Popup.CloseOnEscape
    title: qsTr("Select Address")
    modal: true
    onAccepted: _dialog.acceptAction()
    onRejected: _tableView.selectedRow = -1

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

            Row {
                id: _tableHeader
                readonly property var colWidthPercentArr: [0.3, 0.7]

                Layout.fillWidth: true
                Layout.preferredHeight: Theme.tableHeaderHeight
                Layout.maximumHeight: Theme.tableHeaderHeight
                Layout.minimumHeight: Theme.tableHeaderHeight

                Repeater {
                    model: _tableHeader.colWidthPercentArr.length

                    UNTableHeaderLabel {
                        width: _tableHeader.colWidthPercentArr[index]*_tableHeader.width
                        height: _tableHeader.height
                        iconSource: ""
                        text: walletAdapter.addressBookTableModel.columnName(index)
                        isLeftAligned: index === 0
                    }
                }
            }

            TableView {
                id: _tableView

                property int selectedRow: -1

                Layout.fillWidth: true
                Layout.preferredHeight: 500
                Layout.maximumHeight: 500
                Layout.minimumHeight: 500

                function columnWidth(column) {
                    return _tableHeader.colWidthPercentArr[column]*_tableHeader.width
                }

                model: walletAdapter.addressBookTableModel

                ScrollIndicator.vertical: ScrollIndicator {
                    orientation: Qt.Vertical
                    visible: _tableView.height < _tableView.contentHeight
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

                boundsBehavior: Flickable.StopAtBounds
                columnWidthProvider: columnWidth
                columnSpacing: 0
                rowSpacing: 0
                clip: true
                flickableDirection: Flickable.VerticalFlick

                delegate: Rectangle {
                    id: delegateControl
                    readonly property int rowNum: index % _tableView.model.rowCount
                    readonly property int colNum: Math.floor(index/_tableView.model.rowCount)
                    property bool isSelected: delegateControl.rowNum == _tableView.selectedRow
                    implicitHeight: delegateLbl.height + Theme.verticalMargin
                    color: "transparent"
                    border {
                        width: delegateControl.isSelected ? 1 : 0
                        color: "black"
                    }

                    UNLabel {
                        id: delegateLbl
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: delegateControl.colNum === 0 ? 16 : 0
                        width: parent.width

                        type: UNLabel.Type.TypeNormal

                        text: display
                        font.pointSize: Theme.textPointSize
                        color: "black"
                        elide: Text.ElideRight
                        horizontalAlignment: colNum === 0 ? Text.AlignLeft : Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: _tableView.selectedRow = delegateControl.rowNum
                        onDoubleClicked: {
                            _tableView.selectedRow = delegateControl.rowNum
                            _dialog.acceptAction()
                        }
                    }
                    Rectangle {
                        visible: delegateControl.isSelected
                        anchors {
                            left: ((_tableView.model.colCount - 1) == delegateControl.colNum) ? parent.left : undefined
                            right: (0 == delegateControl.colNum) ? parent.right : undefined
                        }
                        height: parent.height - 2
                        anchors.verticalCenter: parent.verticalCenter
                        width: 1
                        color: "white"
                    }
                }
            }
        }
    }
}
