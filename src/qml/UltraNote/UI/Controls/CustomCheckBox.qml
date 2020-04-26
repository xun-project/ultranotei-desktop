import QtQuick 2.13
import QtQuick.Controls 2.13

import UltraNote.UI 1.0
import UltraNote.UI.Controls 1.0

CheckBox {
    id: control
    font.pointSize: Theme.textPointSize
    contentItem: Text {
        text: control.text
        font: control.font
        color: "white"
        verticalAlignment: Text.AlignVCenter
        leftPadding: control.indicator.width + control.spacing
    }
}
