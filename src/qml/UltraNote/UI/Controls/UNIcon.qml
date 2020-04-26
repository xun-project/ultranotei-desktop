import QtQuick 2.13
import QtGraphicalEffects 1.0

import UltraNote.UI 1.0
import UltraNote.UI.Controls 1.0

Item {
    id: _itm

    property color color: "transparent"
    property string source: ""
    property int size: 24
    property bool clickable: false
    property string toolTip: ""

    signal clicked()

    width: _itm.size
    height: _itm.size

    implicitWidth: width
    implicitHeight: height

    Image {
        id: _icon

        visible: _itm.color === "transparent"

        anchors.fill: parent

        sourceSize: Qt.size(_itm.size, _itm.size)

        fillMode: Image.PreserveAspectFit
        cache: true
        mipmap: true

        source: _itm.source
    }

    ColorOverlay {
        id: _colorOverlay

        anchors.fill: _icon

        enabled: _itm.color !== undefined

        source: _icon

        color: _itm.color !== undefined ? _itm.color : "transparent"
    }

    UNToolTip {
        id: _tooltip
        timeout: 10000
        delay: 0

        text: _itm.toolTip
    }

    MouseArea {
        anchors.fill: parent

        enabled: _itm.clickable

        hoverEnabled: _itm.toolTip !== ""

        preventStealing: true
        propagateComposedEvents: false

        onEntered: {
            _tooltip.open()
        }

        onExited: {
            _tooltip.hide()
        }

        onClicked: {
            _itm.clicked()
        }
    }
}

