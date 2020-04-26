import QtQuick 2.13
import QtQuick.Controls 2.13

import UltraNote.UI.Controls 1.0

ScrollIndicator {
    id: _itm

    property color color: _privateProperties.defaultColor
    opacity: _privateProperties.defaultOpacity

    QtObject {
        id: _privateProperties

        readonly property color defaultColor: "#383941"
        readonly property double defaultOpacity: 0.8
    }

    contentItem: Rectangle {
        id: _background

        width: 5
        height: 70
        radius: 4
        color: _itm.color
    }
}
