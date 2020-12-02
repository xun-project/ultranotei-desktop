import QtQuick 2.13
import QtQuick.Controls 2.13

import UltraNote.UI 1.0
import UltraNote.UI.Controls 1.0

MenuItem {
    id: _itm

    property bool  disabled: false
    property color textColor: disabled ? Theme.statusBarMenuActiveTextColor : Theme.statusBarMenuTextColor
    property color activeTextColor: Theme.statusBarMenuActiveTextColor
    property color checkableFrameColor: Theme.statusBarMenuCheckableFrameColor
    property color checkableActiveColor: Theme.statusBarMenuCheckableActiveColor


    height: 24
    implicitHeight: height

    checkable: false

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

        anchors.leftMargin: 16

        anchors.verticalCenter: parent.verticalCenter

        width: 18

        visible: _itm.checkable

        Rectangle {
            id: _indicatorBackground

            anchors.centerIn: parent

            width: 18
            height: 18

            opacity: _itm.state === "checked" ? 1.0 : 0.8
            color: "transparent"
            border.color: _itm.state === "checked" ? _itm.checkableActiveColor : _itm.checkableFrameColor
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

            Image {
                id: _checkIcon

                x: (parent.width - width) / 2
                y: ((parent.height - height) / 2) - 1

                width: 12
                height: 12

                source: "qrc:/icons/resources/icons/checkbox_arrow_icon.svg"
                fillMode: Image.PreserveAspectFit
                scale: _itm.state === "checked" ? 1 : 0

                Behavior on scale {
                    NumberAnimation {
                        duration: 100
                    }
                }
            }
        }
    }

    background: Item {
        id: _background

        anchors.fill: parent
    }

    contentItem: UNLabel {
        anchors.left: _indicator.visible ? _indicator.right : _itm.left
        anchors.leftMargin: _indicator.visible ? 16 : 0
        anchors.right: parent.right

        type: UNLabel.Type.TypeDropdownListItem
        color: _itm.highlighted ? _itm.activeTextColor : _itm.textColor
        text: _itm.text
        lineHeight: 21
        lineHeightMode: Text.FixedHeight
    }
}
