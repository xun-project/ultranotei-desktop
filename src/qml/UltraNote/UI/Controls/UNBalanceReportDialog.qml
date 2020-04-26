import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.13
import QtQuick.Layouts 1.13

import UltraNote.UI 1.0
import UltraNote.UI.Controls 1.0

Dialog {
    id: _itm

    property int maximumContentSize: _privateProperties.defaultMaximumContentSize
    property color overlayColor: _privateProperties.defaultOverlayColor
    property int pointerSize: 18
    property int pointerOffset: 25

    implicitWidth: 400

    height: implicitHeight
    width: implicitWidth

    spacing: 20

    modal: false

    QtObject {
        id: _privateProperties

        readonly property int defaultMaximumContentSize: 400
        readonly property color defaultOverlayColor: "#232f34"
    }

    enter: Transition {
        NumberAnimation { property: "scale"; from: 0.5; to: 1.0; easing.type: Easing.OutQuint; duration: 150 }
        NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; easing.type: Easing.OutCubic; duration: 150 }
    }

    exit: Transition {
        NumberAnimation { property: "scale"; from: 1.0; to: 0.8; easing.type: Easing.OutQuint; duration: 100 }
        NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; easing.type: Easing.OutCubic; duration: 100 }
    }

    header: Item { height: 0}
    footer: Item { height: 0}

    background: UNElevatedPanel {
        id: _background

        anchors.fill: parent

        color: Theme.balanceReportBackgroundColor
        radius: 8
        elevation: 24

        Canvas {
            anchors.right: parent.left
            anchors.rightMargin: -4
            anchors.top: parent.top
            anchors.topMargin: _itm.pointerOffset

            width: _itm.pointerSize
            height: _itm.pointerSize

            antialiasing: true
            smooth: true

            onPaint: {
                var context = getContext("2d");

                context.strokeStyle = Theme.balanceReportBackgroundColor;
                context.fillStyle = Theme.balanceReportBackgroundColor;
                context.lineJoin = "round";
                context.lineWidth = 2;

                context.beginPath();
                context.moveTo(0, _itm.pointerSize / 2);
                context.lineTo(_itm.pointerSize, 0)
                context.lineTo(_itm.pointerSize, _itm.pointerSize)
                context.lineTo(0, _itm.pointerSize / 2)
                context.closePath();
                context.stroke();
                context.fill();
            }
        }

    }

    Overlay.modeless: Item {
        Rectangle {
            anchors.fill: parent
            anchors.margins: 10

            color: Qt.rgba(_itm.overlayColor.r, _itm.overlayColor.g, _itm.overlayColor.b, 0.32)

            Behavior on opacity {
                NumberAnimation {
                    duration: 100
                    easing.type: Easing.OutCubic
                }
            }
        }
    }
}
