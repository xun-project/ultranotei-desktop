import QtQuick 2.13
import QtQuick.Controls 2.13

import UltraNote.UI 1.0
import UltraNote.UI.Controls 1.0

Rectangle {
    id: control

    property bool ascendingListSort: false
    property alias text: hdrLabel.text
    property alias leftPadding: hdrLabel.leftPadding
    property alias iconSource: hdrBtn.source
    property alias iconScale: hdrBtn.scale
    property alias textColor: hdrLabel.color
    property bool isLeftAligned: false

    color: Theme.tableHeaderLabelBackgroundColor

    UNLabel {
        id: hdrLabel
        anchors.fill: parent
        anchors.leftMargin: control.isLeftAligned ? 16 : 0

        type: UNLabel.Type.TypeNormal

        color: Theme.tableHeaderLabelColor

        horizontalAlignment: control.isLeftAligned ? Text.AlignLeft : Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        width: implicitWidth
        clip: true
        elide: Text.ElideRight
        wrapMode: Text.WordWrap
    }

    Image {
        id: hdrBtn
        visible: ("" !== control.iconSource)
        anchors {
            left: hdrLabel.right
            leftMargin: 6
            verticalCenter: parent.verticalCenter
        }
        height: 15
        width: visible ? height : 0
        mipmap: true
        fillMode: Image.PreserveAspectFit
    }

    UNMouseArea {
        enabled: hdrBtn.visible
        anchors.fill: parent
        onClicked: control.ascendingListSort = !control.ascendingListSort
    }
}
