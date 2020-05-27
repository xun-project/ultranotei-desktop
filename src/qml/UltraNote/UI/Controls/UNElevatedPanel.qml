import QtQuick 2.12
import QtGraphicalEffects 1.0

import QtImports.QtQuickControls2.Material 1.0

Item {
    id: _itm

    property color color: _privateProperties.defaultColor
    property int radius: _privateProperties.defaultRadius
    property alias contentItem: _content.children
    property int elevation: 0
    property color borderColor: "transparent"

    QtObject {
        id: _privateProperties

        readonly property color defaultColor: "#ffffff"
        readonly property int defaultRadius: 3
    }

    Rectangle {
        id: _content

        anchors.fill: parent
        anchors.margins: 1

        color: _itm.color
        border.color : _itm.borderColor

        radius: _itm.radius

        layer.enabled: true
        layer.effect: ElevationEffect {
            id: _elevationEffect

            anchors.fill: _content

            source: _content
            elevation: _itm.elevation
        }
    }
}
