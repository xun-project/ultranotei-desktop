import QtQuick 2.13
import QtQuick.Controls 2.13

import UltraNote.UI 1.0
import UltraNote.UI.Controls 1.0

ToolTip {
    id: _itm

    property color backgroundColor: Theme.tooltipBackgroundColor
    property color textColor: Theme.tooltipTextColor
    property color borderColor: "transparent"
    property var alignment: Qt.AlignBottom

    y: alignment === Qt.AlignBottom ? parent.height + 5 : - height -5
    x: (parent.width - _itm.width) / 2

    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent | Popup.CloseOnReleaseOutsideParent

    Behavior on visible {
        ParallelAnimation {
            PropertyAnimation {
                target: _background
                property: "opacity"
                duration: 150
                easing.type: Easing.OutCubic
                from:  0.0
                to: 1.0
            }
            PropertyAnimation {
                target: _backgroundScale
                properties: "xScale, yScale"
                from: 0.8
                to: 1.0
                duration: 150
                easing.type: Easing.OutCubic
            }
            PropertyAnimation {
                target: _contentItem
                property: "opacity"
                duration: 150
                easing.type: Easing.OutCubic
                from:  0.0
                to: 1.0
            }
        }
    }

    background: Rectangle {
        id: _background

        anchors.centerIn: parent

        height: Math.max(32, _contentItem.implicitHeight + 18)
        width: Math.min(_contentItem.implicitWidth + 2 * 16, 320)
        radius: 4
        color: _itm.backgroundColor
        border.color: _itm.borderColor

        transform: [
            Scale {
                id: _backgroundScale
            },
            Translate {
                x: _background.width * (1 - _backgroundScale.xScale) / 2
            }
        ]
    }

    contentItem: Label {
        id: _contentItem

        anchors.left: _background.left
        anchors.right: _background.right
        anchors.verticalCenter: _background.verticalCenter
        anchors.leftMargin: 16
        anchors.rightMargin: 16

        font.family: UNFontsFactory.workSansMedium.name
        font.pixelSize: 14
        font.letterSpacing: 0.0
        lineHeight: 19
        lineHeightMode: Text.FixedHeight
        color: _itm.textColor
        elide: Text.ElideNone
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Label.WordWrap
        maximumLineCount: 3
        text: _itm.text

        opacity: 0.8
    }
}
