import QtQuick 2.13
import QtQuick.Controls 2.13

import UltraNote.UI 1.0
import UltraNote.UI.Controls 1.0

CheckBox {
    id: _itm

    property color textColor: Theme.checkboxTextColor
    property color frameColor: Theme.checkboxFrameColor
    property color activeColor: Theme.checkboxActiveColor
    property alias labelTextSize: _contentItem.font.pixelSize

    width: _indicator.width + 15 + _contentItem.implicitWidth
    implicitWidth: width
    height: 40
    implicitHeight: height

    states: [
        State {
            name: "checked"
            when: _itm.checked
            PropertyChanges {
                target: _itm

            }
        },
        State {
            name: "unchecked"
            when: !_itm.checked
            PropertyChanges {
                target: _itm

            }
        }
    ]

    transitions: Transition {
        SequentialAnimation {
            NumberAnimation {
                target: _indicatorBackground
                property: "scale"
                // Go down 2 pixels in size.
                to: 1 - 2 / _indicatorBackground.width
                duration: 120
            }
            NumberAnimation {
                target: _indicatorBackground
                property: "scale"
                to: 1
                duration: 120
            }
        }
    }

    indicator: Item {
        id: _indicator

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left

        width: 18
        
        Rectangle {
            id: _indicatorBackground

            anchors.centerIn: parent

            width: 18
            height: 18
            
            opacity: _itm.state === "checked" ? 1.0 : 0.8
            color: "transparent"
            border.color: _itm.state === "checked" ? _itm.activeColor : _itm.frameColor
            border.width: _itm.state === "checked" ? width / 2 : 2
            radius: 2

            Behavior on border.width {
                NumberAnimation {
                    duration: 100
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on border.color {
                ColorAnimation {
                    duration: 100
                    easing.type: Easing.OutCubic
                }
            }

            UNIcon {
                id: _checkIcon

                x: (parent.width - width) / 2
                y: ((parent.height - height) / 2) - 1

                size: 12

                source: "qrc:/icons/resources/icons/checkbox_arrow_icon.svg"
                color: Theme.checkboxIndicatorColor
                scale: _itm.state === "checked" ? 1 : 0

                Behavior on scale {
                    NumberAnimation {
                        duration: 100
                    }
                }
            }
        }
    }

    contentItem: UNLabel {
        id: _contentItem

        anchors.left: indicator.right
        anchors.leftMargin: 15
        anchors.verticalCenter: parent.verticalCenter

        width: implicitWidth

        type: UNLabel.Type.TypeCheckbox
        size: Theme.checkboxTextSize
        font.letterSpacing: 0.0
        color: _itm.textColor
        elide: Text.ElideNone
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignLeft
        text: _itm.text

        opacity: 0.8
    }
}

