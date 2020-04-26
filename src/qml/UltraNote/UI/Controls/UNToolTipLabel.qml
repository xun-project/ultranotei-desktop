import QtQuick 2.13
import QtQuick.Controls 2.13

Label {
    id: control
    signal doubleClicked()
    signal clicked()
    elide: Text.ElideRight
    clip: true
    MouseArea {
        id: controlMouseArea
        anchors.fill: parent
        hoverEnabled: false
        onDoubleClicked: control.doubleClicked()
        onClicked: control.clicked()
    }
}
