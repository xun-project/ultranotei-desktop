import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.13
import QtQuick.Layouts 1.13

import UltraNote.UI 1.0
import UltraNote.UI.Controls 1.0

UNPage {
    id: _page
    
    property int _selectedRow : 0

    objectName: "transactions_page"

    title: qsTr("Transactions")

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

                readonly property var colWidthPercentArr: [0.04, 0.18, 0.12, 0.3, 0.21, 0.15]

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

                Layout.fillWidth: true
                Layout.fillHeight: true

                function columnWidth(column) {
                    return _tableHeader.colWidthPercentArr[column]*_tableHeader.width
                }

                onWidthChanged: {
                    _tableView.forceLayout()
                }

                model: walletAdapter.transactionsTableModel

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

                    Image {
                        id: stateImg
                        anchors.centerIn: parent
                        visible: 0 === _itemController.colNum
                        height: 0.55 * parent.height
                        width: height
                        fillMode: Image.PreserveAspectFit
                        mipmap: true
                        source: stateImg.visible ? display : ""
                    }

                    Item {
                        height: parent.height
                        width: parent.width

                        Image {
                            id: transactionImg
                            anchors.verticalCenter: parent.verticalCenter
                            visible: 3 === _itemController.colNum
                            height: stateImg.height
                            width: transactionImg.visible ? height : 0
                            fillMode: Image.PreserveAspectFit
                            mipmap: true
                            source: transactionImg.visible ? _tableView.model.transactionIcon(_itemController.rowNum) : ""
                        }

                        UNLabel {
                            id: itemLabel
                            anchors.left: transactionImg.right
                            visible: !stateImg.visible
                            height: parent.height
                            width: parent.width - transactionImg.width
                            text: display

                            type: UNLabel.Type.TypeNormal

                            color: Theme.tableTextColor

                            clip: true
                            elide: Text.ElideRight
                            horizontalAlignment: _itemController.colNum < 3 ? Text.AlignHCenter : Text.AlignLeft
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: 5

                            MouseArea {
                                anchors.fill: parent

                                onDoubleClicked: {
                                    walletAdapter.transactionsTableModel.setupTransactionDetails(_itemController.rowNum)
                                    _transactionDetailsDialog.open()
                                }
                                onClicked: {
                                    _selectedRow = _itemController.rowNum
                                }
                            }
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
                    id: _exportButton
                    text: qsTr("Export")

                    onClicked: {
                        _walletDialog.selectFolder = false
                        _walletDialog.selectExisting = false
                        _walletDialog.title = qsTr("Save Transactions to File")
                        _walletDialog.defaultSuffix = "csv"
                        _walletDialog.nameFilters = ["CSV Files (*.csv)"]
                        _walletDialog.acceptedCallback = walletAdapter.transactionsTableModel.exportToCsv
                        _walletDialog.open()
                    }
                }
            }

            UNLayoutSpacer {
                fixedHeight: 32
            }
        }
    }
}
