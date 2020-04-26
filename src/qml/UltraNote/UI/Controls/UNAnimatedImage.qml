import QtQuick 2.13
import QtQuick.Controls 2.13

import UltraNote.UI.Controls 1.0

AnimatedImage {
    id: _itm

    property alias toolTip: _tooltip.text

    visible: "" !== _itm.source
    mipmap: true
    fillMode: Image.PreserveAspectFit

    UNToolTip {
        id: _tooltip
        timeout: 10000
        delay: 0
        visible: _mouseArea.containsMouse && ("" !== _tooltip.text)
    }

    MouseArea {
        id: _mouseArea
        anchors.fill: parent
        hoverEnabled: _itm.visible
    }
}
