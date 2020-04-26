import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.13
import QtQuick.Layouts 1.13

import UltraNote.UI 1.0
import UltraNote.UI.Controls 1.0

UNPage {
    id: _page

    property int _selectedRow : 0

    objectName: "messages_page"

    title: qsTr("Messages")

    contentItem: Item {
        anchors.fill: parent

        onWidthChanged: {
            _tableView.forceLayout()
        }

        ColumnLayout {
            id: _pageContent

            anchors.fill: parent
            anchors.margins: 16

            spacing: 0

            Row {
                id: _tableHeader

                readonly property var colWidthPercentArr: [0.18, 0.12, 0.12, 0.58]

                Layout.fillWidth: true
                Layout.preferredHeight: Theme.tableHeaderHeight
                Layout.maximumHeight: Theme.tableHeaderHeight
                Layout.minimumHeight: Theme.tableHeaderHeight

                Repeater {
                    id: _tableHeaderRepeater

                    model: _tableHeader.colWidthPercentArr.length

                    UNTableHeaderLabel {
                        text: _tableView.model.columnName(index)
                        width: _tableHeader.colWidthPercentArr[index]*_tableHeader.width
                        height: _tableHeader.height
                        iconSource: ""
                    }
                }
            }

            TableView {
                id: _tableView

                function columnWidth(column) {
                    return _tableHeader.colWidthPercentArr[column]*_tableHeader.width
                }

                onWidthChanged: {
                    _tableView.forceLayout()
                }

                Layout.fillHeight: true
                Layout.fillWidth: true

                model: walletAdapter.messagesTableModel

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
                    id: _itemController

                    readonly property int rowNum: index % _tableView.model.rowCount
                    readonly property int colNum: Math.floor(index/_tableView.model.rowCount)

                    implicitHeight: 30
                    implicitWidth: parent.width
                    color: rowNum === _selectedRow ? Theme.tableRowActiveColor : Theme.tableRowColor
                    clip: true

                    Item {
                        id: _unreadMessageIcon
                        visible: colNum === 0 ?  !walletAdapter.messagesTableModel.getReadState(rowNum) : false
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left

                        Image {
                            id: _icon
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 5
                            width: 15
                            height: 15
                            source: "qrc:/icons/resources/icons/drawer_messages_list_item_icon.svg"
                        }
                    }

                    UNToolTipLabel {
                        id: _itemLabel

                        anchors.fill: parent
                        anchors.left: _unreadMessageIcon.right
                        text: display
                        font.pointSize: Theme.textPointSize
                        color: Theme.tableTextColor
                        clip: true
                        elide: Text.ElideRight
                        horizontalAlignment: _itemController.colNum < 3 ? Text.AlignHCenter : Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: colNum === 0 ?  25 : 0

                        onDoubleClicked: {
                            _selectedRow = _itemController.rowNum
                            walletAdapter.messagesTableModel.setupMessageDetails(_itemController.rowNum)
                            _messageDetailsDialog.currentRow = _itemController.rowNum
                            _messageDetailsDialog.open()
                        }
                        onClicked: {
                            _selectedRow = _itemController.rowNum
                        }
                    }
                }
            }

            UNLayoutSpacer {
                fixedHeight: 32
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                Layout.maximumHeight: 40
                Layout.minimumHeight: 40

                spacing: 16

                UNLayoutSpacer {}

                UNButton {
                    id: _replyButton
                    text: qsTr("Reply")

                    onClicked: {
                        _globalProperties.setupSendMsg("")
                    }
                }
            }

            UNLayoutSpacer {
                fixedHeight: 32
            }
        }

    }
}
