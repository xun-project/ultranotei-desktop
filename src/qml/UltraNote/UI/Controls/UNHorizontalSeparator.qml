import QtQuick 2.13

Rectangle {
    id: _itm

    color: _privateProperties.defaultColor
    opacity: _privateProperties.defaultOpacity

    height: 1

    QtObject {
        id: _privateProperties

        readonly property color defaultColor: "#000000"
        readonly property double defaultOpacity: 1.0
    }
}
