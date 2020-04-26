import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.13

import UltraNote.UI.Controls 1.0

Item {
    id: _itm

    property int columnsCount
    property var columns: []
    property ListModel model: ListModel {}
    property bool allowSelection: false
    property ListModel selectionModel: ListModel {}

    property color headerColor: _privateProperties.defaultHeaderColor
    property color scrollBarIndicatorColor: _privateProperties.defaultScrollBarIndicatorColor
    property color selectionColor: _privateProperties.defaultSelectionColor

    QtObject {
        id: _privateProperties

        readonly property color defaultHeaderColor: "#EEEEF3"
        readonly property color defaultScrollBarIndicatorColor: "#383941"
        readonly property color defaultSelectionColor: "#4F97F0"
        readonly property var columnsProportions: {
            var proportionsList = [];

            var proportionsSum = 0

            columns.forEach(function(item) {
                if(item.proportion && item.proportion !== undefined) {
                    proportionsSum += item.proportion
                    proportionsList.push(item.proportion)
                }
            });

            return proportionsList.map(function(proportion) { return proportion / proportionsSum; });
        }

    }

    enum DelegateType {
        DelegateTypeIcon,
        DelegateTypeLabel,
        DelegateTypeCheckBox,
        DelegateTypeTextInput,
        DelegateTypeComboBox
    }

    Rectangle {
        anchors.fill: parent

        ColumnLayout {
            anchors.fill: parent

            spacing: 0

            Rectangle {
                id: _header

                Layout.fillWidth: true
                Layout.preferredHeight: 50
                Layout.maximumHeight: 50
                Layout.minimumHeight: 50

                color: _itm.headerColor
                z: 2

                RowLayout {
                    id: _headerRow

                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 32

                    spacing: 0

                    Repeater {
                        model: _itm.columnsCount

                        Item {
                            id: _headerColumnTitle

                            Layout.fillHeight: true
                            Layout.preferredWidth: _headerRow.width * _privateProperties.columnsProportions[index]
                            Layout.maximumWidth: _headerRow.width * _privateProperties.columnsProportions[index]
                            Layout.minimumWidth: _headerRow.width * _privateProperties.columnsProportions[index]

                            RowLayout {
                                anchors.centerIn: parent

                                width: childrenRect.width
                                height: parent.height
                                spacing: 5

                                UNLabel {
                                    Layout.preferredWidth: implicitWidth
                                    Layout.maximumWidth: implicitWidth
                                    Layout.minimumWidth: implicitWidth
                                    Layout.alignment: Qt.AlignVCenter

                                    type: UNLabel.Type.TypeTableViewHeader
                                    font.letterSpacing: 20 / 1000
                                    text: columns[index].text !== undefined ? columns[index].text : qsTr("")
                                }

                                Image {
                                    id: _headerColumnTitleTooltipIcon

                                    Layout.preferredWidth: sourceSize.width
                                    Layout.maximumWidth: sourceSize.width
                                    Layout.minimumWidth: sourceSize.width
                                    Layout.alignment: Qt.AlignVCenter

                                    visible: columns[index].tooltip !== undefined

                                    fillMode: Image.PreserveAspectFit
                                    source: "qrc:/resources/icons/tooltip_icon.svg"

                                    MouseArea {
                                        id: _headerColumnTitleTooltipMouseArea

                                        anchors.fill: parent

                                        onClicked: {
                                            _headerColumnTitleTooltip.visible = true
                                        }
                                    }

                                    UNToolTip {
                                        id: _headerColumnTitleTooltip

                                        timeout: 10000
                                        text: columns[index].tooltip !== undefined ? columns[index].tooltip : qsTr("")
                                    }
                                }
                            }
                        }
                    }
                }
            }

            ListView {
                id: _contentListView

                Layout.fillHeight: true
                Layout.fillWidth: true

                clip: true
                z: 1

                ScrollBar.vertical: ScrollBar {
                    interactive: true
                    orientation: Qt.Vertical
                    policy: ScrollBar.AsNeeded
                    visible: _contentListView.height < _contentListView.contentItem.height

                    background: Rectangle {
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.right: parent.right
                        width: 5
                        color: _itm.headerColor
                    }

                    contentItem: Rectangle {

                        anchors.horizontalCenter: parent.horizontalCenter

                        implicitWidth: 5
                        implicitHeight: 200
                        radius: width / 2

                        opacity: 0.8

                        color: _itm.scrollBarIndicatorColor
                    }
                }

                model: _itm.model

                delegate: Item {
                    id: _contentDelegate

                    property int rowIndex: index
                    property bool selected: _itm.allowSelection ? _itm.selectionModel.get(index).selected : false

                    anchors.left: parent.left
                    anchors.right: parent.right


                    height: 50

                    MouseArea {
                        id: _selectionArea

                        anchors.fill: parent

                        hoverEnabled: true

                        onClicked: {
                            if(_itm.allowSelection) {
                                _itm.selectionModel.set(_contentDelegate.rowIndex, { 'selected': !_contentDelegate.selected } )
                            }
                        }
                    }

                    Rectangle {
                        anchors.fill: parent

                        color: _itm.selectionColor

                        opacity: !_contentDelegate.selected && _selectionArea.containsMouse ? 0.05 : 0.0

                        Behavior on opacity {
                            OpacityAnimator{
                                duration: 125
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    Rectangle {
                        anchors.fill: parent

                        color: _itm.selectionColor

                        opacity: _contentDelegate.selected ? 0.12 : 0.0

                        Behavior on opacity {
                            OpacityAnimator{
                                duration: 225
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    RowLayout {
                        id: _contentDelegateLayout

                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 32

                        spacing: 0

                        Repeater {
                            model: _itm.columnsCount
                            delegate: Item {
                                id: _itemDelegate

                                property int columnIndex: index

                                Layout.fillHeight: true
                                Layout.preferredWidth: _contentDelegateLayout.width * _privateProperties.columnsProportions[columnIndex]
                                Layout.maximumWidth: _contentDelegateLayout.width * _privateProperties.columnsProportions[columnIndex]
                                Layout.minimumWidth: _contentDelegateLayout.width * _privateProperties.columnsProportions[columnIndex]

                                Loader {
                                    id: _itemDelegateLoader

                                    anchors.fill: parent

                                    sourceComponent: _labelComponent

                                    onLoaded: {
                                        item.itemData = _itm.model.get(_contentDelegate.rowIndex).data.get(_itemDelegate.columnIndex)
                                        if(_itm.columns[_itemDelegate.columnIndex].callback !== undefined) {
                                            item.emitCallback.connect(_itm.columns[_itemDelegate.columnIndex].callback)
                                        }
                                    }

                                    Component {
                                        id: _labelComponent
                                        Item {
                                            id: _labelComponentItem

                                            property var itemData
                                            property int rowIndex: _contentDelegate.rowIndex
                                            property int columnIndex: _itemDelegate.columnIndex

                                            signal emitCallback(var rowIndex, var columnIndex, var params)

                                            UNLabel {
                                                id: _labelComponentText

                                                anchors.fill: parent
                                                anchors.leftMargin: 5
                                                anchors.rightMargin: 5

                                                type: UNLabel.Type.TypeNormal
                                                size: 12
                                                text: _labelComponentItem.itemData !== undefined ? _labelComponentItem.itemData.value : ""
                                                color: "#656878"
                                                horizontalAlignment: Qt.AlignHCenter
                                                verticalAlignment: Qt.AlignVCenter
                                                elide: Text.ElideRight
                                                maximumLineCount: 2
                                                lineHeightMode: Text.FixedHeight
                                                lineHeight: 21
                                            }
                                        }
                                    }

                                    Component {
                                        id: _checkboxComponent

                                        Item {
                                            id: _checkboxComponentItem

                                            property var itemData
                                            property int rowIndex: _contentDelegate.rowIndex
                                            property int columnIndex: _itemDelegate.columnIndex

                                            signal emitCallback(var rowIndex, var columnIndex, var params)

                                            UNCheckBox {
                                                id: _checkboxComponentCheckBox

                                                anchors.centerIn: parent

                                                checked: _checkboxComponentItem.itemData !== undefined ? _checkboxComponentItem.itemData.value : false

                                                text: ""
                                                onClicked: {
                                                    _checkboxComponentItem.emitCallback(rowIndex, columnIndex, _checkboxComponentCheckBox.checked)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    //TODO Commented. Without it looks better
                    //Rectangle {
                    //  anchors.left: parent.left
                    //  anchors.right: parent.right
                    //  anchors.bottom: parent.bottom
                    //
                    //  height: 1
                    //
                    //  color: _itm.headerColor
                    //}
                }
            }
        }
    }
}
