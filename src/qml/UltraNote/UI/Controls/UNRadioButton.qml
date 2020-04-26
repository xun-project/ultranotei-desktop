import QtQuick 2.12
import QtQuick.Controls 2.12

import UltraNote.UI 1.0
import UltraNote.UI.Controls 1.0

RadioButton {
    id: _itm

    property color textColor: Theme.radioButtonTextColor
    property color frameColor: Theme.radioButtonFrameColor
    property color activeColor: Theme.radioButtonActiveColor
    property int indicatorSize: _privateProperties.defaultIndicatorSize

    QtObject {
        id: _privateProperties

        readonly property int defaultIndicatorSize: 22
    }

    width: _indicatorItem.implicitWidth + _contentItem.implicitWidth + 16
    implicitWidth: width

    states: [
        State {
            name: "checked"
            when: _itm.checked
            PropertyChanges {
                target: _indicator
                scale: 1.0
            }
        },
        State {
            name: "unchecked"
            when: !_itm.checked
            PropertyChanges {
                target: _indicator
                scale: 0.0
            }
        }
    ]

    transitions: Transition {
        SequentialAnimation {
            NumberAnimation {
                target: _indicatorFrame
                property: "scale"
                to: 1 - 2 / _indicatorFrame.width
                duration: 120
            }
            NumberAnimation {
                target: _indicatorFrame
                property: "scale"
                to: 1
                duration: 120
            }
        }
    }

    indicator: Item {
        id: _indicatorItem

        anchors.verticalCenter: parent.verticalCenter

        width: _itm.indicatorSize
        height: _itm.indicatorSize

        Rectangle {
            id: _indicatorFrame

            anchors.centerIn: parent

            width: _itm.indicatorSize
            height: width

            opacity: _itm.state === "checked" ? 1.0 : 0.8
            color: "transparent"
            border.color: _itm.state === "checked" ? _itm.activeColor : _itm.frameColor
            border.width: 2
            radius: width / 2

            Behavior on border.color {
                ColorAnimation {
                    duration: 100
                    easing.type: Easing.OutCubic
                }
            }
        }

        Rectangle {
            id: _indicator

            anchors.centerIn: parent

            width: _itm.indicatorSize - 8
            height: width

            opacity: _itm.state === "checked" ? 1.0 : 0.8
            color: _itm.state === "checked" ? _itm.activeColor : _itm.frameColor
            radius: width / 2

            Behavior on border.color {
                ColorAnimation {
                    duration: 100
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on scale {
                PropertyAnimation {
                    duration: 240
                    easing.type: Easing.OutCubic
                }
            }
        }
    }

    contentItem: UNLabel {
        id: _contentItem

        anchors.left: indicator.right
        anchors.leftMargin: 15
        anchors.verticalCenter: parent.verticalCenter

        type: UNLabel.Type.TypeRadioButton
        font.letterSpacing: 0.0
        lineHeight: font.pixelSize
        lineHeightMode: Text.FixedHeight
        color: _itm.textColor
        elide: Text.ElideNone
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignLeft
        text: _itm.text

        opacity: 0.8
    }
}
