import QtQuick 2.13
import QtQuick.Controls 2.13

import UltraNote.UI 1.0
import UltraNote.UI.Controls 1.0

Button {
    id: _itm

    property color backgroundColor: "#ffffff"
    property color textColor: "#ffffff"

    width: contentItem.implicitWidth + 2 * 16

    background: Rectangle {
        anchors.fill: parent

        color: _itm.backgroundColor
        opacity: _itm.down ? 0.2 : 0.0

        Behavior on opacity {
            OpacityAnimator {
                duration: 250
            }
        }
    }

    contentItem: UNLabel {
        type: UNLabel.Type.TypeNormal

        color: _itm.textColor

        text: _itm.text

        horizontalAlignment: Label.AlignHCenter
    }
}
