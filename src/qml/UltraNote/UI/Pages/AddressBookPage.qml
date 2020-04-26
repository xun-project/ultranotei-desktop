import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.13
import QtQuick.Layouts 1.13

import Qt.labs.qmlmodels 1.0

import QrImage 1.0

import UltraNote.UI 1.0
import UltraNote.UI.Controls 1.0

UNPage {
    id: _page

    objectName: "address_book_page"

    title: qsTr("Address Book")

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

                readonly property var colWidthPercentArr: [0.2, 0.8]

                Layout.fillWidth: true
                Layout.preferredHeight: Theme.tableHeaderHeight
                Layout.maximumHeight: Theme.tableHeaderHeight
                Layout.minimumHeight: Theme.tableHeaderHeight

                spacing: 0

                Repeater {
                    id: _tableHeaderRepeater

                    model: _tableHeader.colWidthPercentArr.length

                    UNTableHeaderLabel {
                        text: _tableView.model.columnName(index)
                        width: _tableHeader.colWidthPercentArr[index]*_tableHeader.width
                        height: _tableHeader.height
                        iconSource: ""
                        isLeftAligned: index === 0
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
                columnWidthProvider: _tableView.columnWidth
                columnSpacing: 0
                rowSpacing: 0
                clip: true
                flickableDirection: Flickable.VerticalFlick

                property int selectedRow: -1

                delegate: Rectangle {
                    id: _itemController

                    readonly property int rowNum: index % _tableView.model.rowCount
                    readonly property int colNum: Math.floor(index/_tableView.model.rowCount)

                    implicitHeight: 40
                    implicitWidth: _tableHeader.colWidthPercentArr[colNum]*_tableHeader.width
                    color: rowNum === _tableView.selectedRow ? Theme.tableRowActiveColor
                                                             : Theme.tableRowColor
                    clip: true

                    UNLabel {
                        id: itemLabel
                        anchors.fill: parent
                        anchors.leftMargin: _itemController.colNum === 0 ? 16 : 0
                        anchors.rightMargin: _itemController.colNum === walletAdapter.addressBookTableModel.colCount ? 16 : 0

                        type: UNLabel.Type.TypeNormal

                        color: Theme.tableTextColor
                        clip: true
                        elide: Text.ElideRight
                        horizontalAlignment: colNum === 0 ? Text.AlignLeft : Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter

                        text: display
                    }

                    MouseArea {
                        anchors.fill: parent

                        onDoubleClicked: {
                            walletAdapter.transactionsTableModel.setupTransactionDetails(_itemController.rowNum)
                            _transactionDetailsDialog.open()
                        }

                        onClicked: {
                            _tableView.selectedRow = _tableView.selectedRow === rowNum ? -1 : rowNum
                            walletAdapter.addressBookTableModel.selectedRow = _tableView.selectedRow
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
                    id: _newAddressButton
                    text: qsTr("New Address")

                    onClicked: {
                        _newAddressDialog.open()
                    }
                }

                UNButton {
                    id: _deleteAddressButton
                    text: qsTr("Delete Address")

                    enabled: _tableView.selectedRow !== -1

                    onClicked: {
                        walletAdapter.addressBookTableModel.removeAddress(_tableView.selectedRow)
                        _tableView.selectedRow =  -1
                        walletAdapter.addressBookTableModel.selectedRow = _tableView.selectedRow
                    }
                }

                UNButton {
                    id: _copyAddressButton
                    text: qsTr("Copy Address")

                    enabled: _tableView.selectedRow !== -1

                    onClicked: {
                        clipboard.setText(walletAdapter.addressBookTableModel.selectedAddress)
                    }
                }
            }

            UNLayoutSpacer {
                fixedHeight: 32
            }
        }

    }
}
