import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.13
import QtGraphicalEffects 1.0

import UltraNote.UI 1.0
import UltraNote.UI.Controls 1.0

Button {
    id: _itm

    property color backgroundColor: Material.color(Material.Yellow, Material.Shade500)
    property color borderColor: Theme.drawerMainActionButtonBorderColor
    property color textColor: "white"
    property string iconSource: ""

    height: 56

    Behavior on width {
        SmoothedAnimation {
            duration: 250
        }
    }

    states: [
        State {
            name: "collapsed"
            PropertyChanges {
                target: _itm
                width: 56
                height: 56
            }
        },
        State {
            name: "expanded"
            PropertyChanges {
                target: _itm
                width: 176
                height: 56
            }
        }
    ]

    transitions: [
        Transition {
            from: "collapsed"
            to: "expanded"
            SequentialAnimation {
                PauseAnimation {
                    duration: 200
                }
                OpacityAnimator {
                    target: _text
                    from: 0.0
                    to: 1.0
                    duration: 150
                }
            }
        },
        Transition {
            from: "expanded"
            to: "collapsed"
            ParallelAnimation {
                OpacityAnimator {
                    target: _text
                    from: 1.0
                    to: 0.0
                    duration: 150
                }
            }
        }
    ]

    background: Rectangle {
        id: _background

        anchors.fill: parent

        radius: height / 2

        color: _itm.backgroundColor
        border.color:_itm.borderColor
    }

    contentItem: Item {
        id: _contentItem

        anchors.fill: parent

        Image {
            id: _icon

            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 16

            width: Theme.drawerIconSize
            height: Theme.drawerIconSize

            source: _itm.iconSource

            layer.enabled: true
            layer.effect: ColorOverlay {
                anchors.fill: _icon
                source: _icon
                color: _itm.textColor
            }
        }

        UNLabel {
            id: _text

            anchors.verticalCenter: parent.verticalCenter
            anchors.left: _icon.right
            anchors.right: _contentItem.right
            anchors.leftMargin: 16
            anchors.rightMargin: 16

            type: UNLabel.Type.TypeDrawerMainActionButton
            font.letterSpacing: 1.15
            elide: Label.ElideNone
            wrapMode: Label.NoWrap
            color: _itm.textColor
            horizontalAlignment: Label.AlignHCenter
            verticalAlignment: Label.AlignVCenter
            font.capitalization: Font.AllUppercase

            text: _itm.text
        }
    }
}
