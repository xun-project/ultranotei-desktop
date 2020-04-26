import QtQuick 2.13
import QtQuick.Controls 2.13

import UltraNote.UI 1.0
import UltraNote.UI.Controls 1.0

Image {
    id: control

    property alias toolTip: imgToolTip.text
    signal clicked()
    visible: "" !== control.source
    mipmap: true
    fillMode: Image.PreserveAspectFit

    UNToolTip {
        id: imgToolTip
        timeout: 10000
        delay: 0
    }

    MouseArea {
        id: imgMouseArea
        anchors.fill: parent
        hoverEnabled: control.visible
        onEntered: {
            if(toolTip.length > 0) {
                imgToolTip.open()
            }
        }

        onExited: {
            imgToolTip.hide()
        }

        onClicked: control.clicked()
    }
}
