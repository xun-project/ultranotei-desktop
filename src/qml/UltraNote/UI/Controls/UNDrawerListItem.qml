import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.13
import QtGraphicalEffects 1.0

import UltraNote.UI 1.0
import UltraNote.UI.Controls 1.0

AbstractButton {
    id: _itm

    property string iconSource: ""
    property color defaultColor: "white"
    property color activeColor: "grey"

    checkable: true
    checked: false

    height: 48
    implicitHeight: height
    implicitWidth: width

    background: RowLayout {
        anchors.fill: parent

        spacing: 16

        Image {
            id: _icon

            Layout.preferredWidth: Theme.drawerIconSize
            Layout.maximumWidth: Theme.drawerIconSize
            Layout.minimumWidth: Theme.drawerIconSize
            Layout.leftMargin: 16
            Layout.alignment: Qt.AlignVCenter

            fillMode: Image.PreserveAspectFit
            smooth: true

            source: _itm.iconSource

            opacity: _itm.checked ? 1.0 : 0.6

            layer.enabled: true
            layer.effect: ColorOverlay {
                //anchors.fill: _icon
                source: _icon
                color: _itm.checked ? _itm.activeColor : _itm.defaultColor
            }
        }

        UNLabel {
            id: _text

            Layout.preferredWidth: implicitWidth
            Layout.maximumWidth: implicitWidth
            Layout.minimumWidth: implicitWidth
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 8

            type: UNLabel.Type.TypeDrawerListItem
            horizontalAlignment: Label.AlignLeft
            verticalAlignment: Label.AlignVCenter
            color: _itm.checked ? _itm.activeColor : _itm.defaultColor

            text: _itm.text

            opacity: _itm.width > _icon.width + _text.implicitWidth + 48 ? 1.0 : 0.0

            Behavior on opacity {
                OpacityAnimator{
                    duration: 125
                }
            }
        }

        Item {
            Layout.fillWidth: true
        }
    }

    contentItem: Item{}
}
