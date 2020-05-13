import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.13
import QtQuick.Layouts 1.13

import UltraNote.UI 1.0
import UltraNote.UI.Controls 1.0

Dialog {
    id: _itm

    anchors.centerIn: parent

    property color overlayColor: _privateProperties.defaultOverlayColor
    property color dialogBackgroundColor: Theme.dialogInfinityBackgroundColor
    property color dialogTitleTextColor: Theme.dialogInfinityTitleTextColor
    property bool  headerAlignmentCenter: false

    implicitWidth: 200

    height: implicitHeight
    width: implicitWidth

    spacing: 20

    modal: true

    QtObject {
        id: _privateProperties
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


    background: UNElevatedPanel {
        id: _background

        anchors.fill: parent

        radius: 4

        elevation: 24

        color: _itm.dialogBackgroundColor
    }

    header: UNLabel {
        id: _header

        leftPadding: 30
        rightPadding: 30
        topPadding: 30

        type: UNLabel.Type.TypeDialogTitle
        color: _itm.dialogTitleTextColor
        text: _itm.title
        wrapMode: Label.WordWrap
        elide: Label.ElideNone
        horizontalAlignment: _itm.headerAlignmentCenter? Label.AlignHCenter : Label.AlignLeft
    }

    Overlay.modal: Item {
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
