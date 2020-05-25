import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.13
import QtQuick.Layouts 1.13

import UltraNote.UI 1.0
import UltraNote.UI.Controls 1.0

UNPage {
    id: _page

    property int _selectedRow : 0

    objectName: "deposits_page"

    title: qsTr("Deposits")

    contentItem: Item {
        anchors.fill: parent

        onWidthChanged: {
            _tableView.forceLayout()
        }

        Flickable {
            anchors.fill: parent
            anchors.margins: 20

            contentHeight: _pageContent.height

            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: _pageContent

                anchors.left: parent.left
                anchors.right: parent.right

                height: childrenRect.height

                spacing: 0

                RowLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right

                    height: 40

                    spacing: 8

                    UNLabel {
                        id: _amountLabelText

                        Layout.fillHeight: true
                        Layout.preferredWidth: Math.max(_amountLabelText.implicitWidth, _timeLabelText.implicitWidth, _depositFeeLabelText.implicitWidth)
                        Layout.maximumWidth:  Math.max(_amountLabelText.implicitWidth, _timeLabelText.implicitWidth, _depositFeeLabelText.implicitWidth)
                        Layout.minimumWidth:  Math.max(_amountLabelText.implicitWidth, _timeLabelText.implicitWidth, _depositFeeLabelText.implicitWidth)

                        type: UNLabel.Type.TypePageSubcategoryTitle

                        color: Theme.textColor
                        text: qsTr("Amount")
                    }

                    UNLayoutSpacer {}

                    UNAmountBox{
                        id:_amountEditBox
                        value : currencyAdapter.getDepositMinAmount()
                        resetDecimals: "1.000000"
                        onTextChanged:  _percentLabel.calculateInterest(_amountEditBox.value, _timeSpinBox.value)
                    }

                    Text {
                        id: suffix
                        verticalAlignment: Text.AlignVCenter
                        text: _globalProperties.currency
                        color: Theme.spinBoxTextColor
                        font.pixelSize: Theme.spinBoxFontSize
                        font.family: UNFontsFactory.workSansMedium.name
                        anchors {rightMargin: 50}
                    }

                    UNLayoutSpacer {}

                    UNLabel {
                        id: _percentLabel

                        property real interest: 0
                        property real termRate: 0

                        function calculateInterest(amount, term) {
                            var interest = currencyAdapter.calculateInterest(amount, term)
                            _percentLabel.termRate = parseFloat((interest / amount) * 100).toFixed(2)
                            _percentLabel.interest = interest / _globalProperties.actStepSize
                        }

                        Layout.preferredWidth: 150
                        Layout.maximumWidth:  150
                        Layout.minimumWidth:  150
                        Layout.alignment: Qt.AlignVCenter

                        type: UNLabel.Type.TypeMedium

                        color: Theme.textColor
                        verticalAlignment: Label.AlignVCenter
                        horizontalAlignment: Label.AlignRight

                        text: "+ " + _percentLabel.interest + " " + _globalProperties.currency + " (" + _percentLabel.termRate + " %)"
                    }
                }

                Item {
                    anchors.left: parent.left
                    anchors.right: parent.right

                    height: 16
                }

                RowLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right

                    height: 40

                    spacing: 8

                    UNLabel {
                        id: _timeLabelText

                        Layout.fillHeight: true
                        Layout.preferredWidth: Math.max(_amountLabelText.implicitWidth, _timeLabelText.implicitWidth, _depositFeeLabelText.implicitWidth)
                        Layout.maximumWidth:  Math.max(_amountLabelText.implicitWidth, _timeLabelText.implicitWidth, _depositFeeLabelText.implicitWidth)
                        Layout.minimumWidth:  Math.max(_amountLabelText.implicitWidth, _timeLabelText.implicitWidth, _depositFeeLabelText.implicitWidth)

                        type: UNLabel.Type.TypePageSubcategoryTitle

                        color: Theme.textColor
                        text: qsTr("Time")
                    }

                    UNLayoutSpacer {}

                    UNSpinBox {
                        id: _timeSpinBox

                        Layout.preferredWidth: implicitWidth
                        Layout.maximumWidth: implicitWidth
                        Layout.minimumWidth: implicitWidth
                        Layout.alignment: Qt.AlignVCenter

                        value: currencyAdapter.getDepositMinTerm()
                        from: currencyAdapter.getDepositMinTerm()
                        stepSize: currencyAdapter.getDepositMinTerm()
                        to: currencyAdapter.getDepositMaxTerm()
                        editable: true

                        validator: IntValidator {
                            bottom: Math.min(_timeSpinBox.from, _timeSpinBox.to)
                            top: Math.max(_timeSpinBox.from, _timeSpinBox.to)
                        }
                        textFromValue: function(value, locale) {
                            _percentLabel.calculateInterest(_amountEditBox.value,
                                                            value)
                            _timeLabel.text = walletAdapter.secondsToNativeTime(value * currencyAdapter.getDifficultyTarget())
                            return value + " Blocks"
                        }
                        valueFromText: function(text, locale) {
                            var textVal = text.split(" ")[0]
                            return Number.fromLocaleString(locale, textVal)
                        }
                    }

                    UNLayoutSpacer {}

                    UNLabel {
                        id: _timeLabel

                        Layout.preferredWidth: 150
                        Layout.maximumWidth:  150
                        Layout.minimumWidth:  150
                        Layout.alignment: Qt.AlignVCenter

                        type: UNLabel.Type.TypeMedium

                        color: Theme.textColor
                        verticalAlignment: Label.AlignVCenter
                        horizontalAlignment: Label.AlignRight
                    }
                }

                Item {
                    anchors.left: parent.left
                    anchors.right: parent.right

                    height: 16
                }

                RowLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right

                    height: 40

                    spacing: 8

                    UNLabel {
                        id: _depositFeeLabelText

                        Layout.fillHeight: true
                        Layout.preferredWidth: Math.max(_amountLabelText.implicitWidth, _timeLabelText.implicitWidth, _depositFeeLabelText.implicitWidth)
                        Layout.maximumWidth:  Math.max(_amountLabelText.implicitWidth, _timeLabelText.implicitWidth, _depositFeeLabelText.implicitWidth)
                        Layout.minimumWidth:  Math.max(_amountLabelText.implicitWidth, _timeLabelText.implicitWidth, _depositFeeLabelText.implicitWidth)

                        type: UNLabel.Type.TypePageSubcategoryTitle
                        color: Theme.textColor
                        text: qsTr("Deposit Fee")
                    }

                    UNLayoutSpacer {}

                    UNLabel {

                        Layout.preferredWidth: 150
                        Layout.maximumWidth:  150
                        Layout.minimumWidth:  150
                        Layout.alignment: Qt.AlignVCenter

                        type: UNLabel.Type.TypeMedium

                        color: Theme.textColor
                        verticalAlignment: Label.AlignVCenter
                        horizontalAlignment: Label.AlignRight

                        text: _globalProperties.convertToAmount(currencyAdapter.getMinimumFee(), Qt.locale()) + " " + _globalProperties.currency
                    }
                }

                Item {
                    anchors.left: parent.left
                    anchors.right: parent.right

                    height: 16
                }

                RowLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right

                    height: 40

                    spacing: 16

                    UNLayoutSpacer {}

                    UNButton {
                        text: qsTr("Deposit")

                        onClicked: {
                            if ((0 === _amountEditBox.value) || ((_amountEditBox.value + currencyAdapter.getMinimumFee()) > _globalProperties.actualBalance)) {
                                _messageDialogProperties.title = qsTr("Critical")
                                _messageDialogProperties.text = qsTr("You don't have enough balance in your account!")
                                _messageDialogProperties.okCancel = false
                                return
                            }
                            walletAdapter.deposit(_timeSpinBox.value, _amountEditBox.value,
                                                  currencyAdapter.getMinimumFee(), 0)
                        }
                    }
                    UNButton {
                        enabled: 0 < walletAdapter.depositTableModel.unlockedDepositCount
                        text: qsTr("Withdraw")
                        onClicked: walletAdapter.withdraw()
                    }
                }

                Item {
                    anchors.left: parent.left
                    anchors.right: parent.right

                    height: 32
                }

                Row {
                    id: _tableHeader

                    readonly property var colWidthPercentArr: [0.12, 0.12, 0.12, 0.12, 0.12, 0.12, 0.12, 0.16]

                    anchors.left: parent.left
                    anchors.right: parent.right

                    height: Theme.tableHeaderHeight

                    Repeater {
                        id: _tableHeaderRepeater

                        function setHeaderIcons(idx, asc) {
                            for (var i = 0; i < _tableHeaderRepeater.count; ++i) {
                                if (idx === i) {
                                    _tableHeaderRepeater.itemAt(i).iconSource = asc ? "qrc:/icons/chevron-circle-up" : "qrc:/icons/chevron-circle-down"
                                } else {
                                    _tableHeaderRepeater.itemAt(i).iconSource = ""
                                }
                            }
                        }

                        model: _tableHeader.colWidthPercentArr.length

                        UNTableHeaderLabel {
                            text: walletAdapter.depositTableModel.columnName(index)
                            width: _tableHeader.colWidthPercentArr[index]*_tableHeader.width
                            height: _tableHeader.height
                            iconSource: ""
                            onAscendingListSortChanged: {
                                _tableView.model.sortAfterColumn(index, ascendingListSort)
                                _tableHeaderRepeater.setHeaderIcons(index, ascendingListSort)
                            }
                        }
                    }
                }

                TableView {
                    id: _tableView

                    anchors.left: parent.left
                    anchors.right: parent.right

                    height: 500

                    function columnWidth(column) {
                        return _tableHeader.colWidthPercentArr[column]*_tableHeader.width
                    }

                    onWidthChanged: {
                        _tableView.forceLayout()
                    }

                    model: walletAdapter.depositTableModel

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

                        readonly property int rowNum: index % _tableView.model.depositCount

                        implicitHeight: 30
                        implicitWidth: parent.width

                        color: rowNum === _selectedRow ? Theme.tableRowActiveColor : Theme.tableRowColor
                        clip: true

                        UNToolTipLabel {
                            height: parent.height
                            width: parent.width

                            text: display
                            font.pointSize: Theme.textPointSize
                            color: Theme.tableTextColor
                            clip: true
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            MouseArea {
                                anchors.fill: parent

                                onDoubleClicked: {
                                    _tableView.model.setupDepositDetails(_itemController.rowNum)
                                    _depositDetailsDialog.open()
                                }
                                onClicked: {
                                    _selectedRow = _itemController.rowNum
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
