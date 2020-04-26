import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.13

import UltraNote.UI 1.0
import UltraNote.UI.Controls 1.0

FocusScope {
    id: _itm

    property color tabBarColor: Theme.pageTabBarColor
    property string title: ""
    property color titleColor: Theme.pageTitleColor
    property alias contentItem: _contentItem.children

    clip: true

    Rectangle {
        id: _background

        anchors.fill: parent

        color: Theme.pageBackgroundColor
    }

    ColumnLayout {
        anchors.fill: parent

        spacing: 0

        UNElevatedPanel {
            id: _tabBar

            Layout.fillWidth: true
            Layout.preferredHeight: 56
            Layout.maximumHeight: 56
            Layout.minimumHeight: 56

            radius: 0
            elevation: 4
            z: _contentItem.z + 1

            color: _itm.tabBarColor

            UNLabel {
                id: _title

                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 32

                type: UNLabel.Type.TypeMedium
                size: 20

                horizontalAlignment: Label.AlignLeft
                verticalAlignment: Label.AlignVCenter

                color: _itm.titleColor
                text: _itm.title
            }
        }

        Item {
            id: _contentItem

            Layout.fillWidth: true
            Layout.fillHeight: true

            clip: true
        }
    }
}
