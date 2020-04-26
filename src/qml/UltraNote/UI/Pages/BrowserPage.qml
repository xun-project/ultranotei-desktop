import QtQuick 2.13
import QtQuick.Layouts 1.13

import UltraNote.UI 1.0
import UltraNote.UI.Controls 1.0

UNPage {
    id: _page
    objectName: "browser_page"
    title: qsTr("Tor Browser")

    contentItem: Item {
        anchors.fill: parent
        ColumnLayout {
            id: _pageContent
            anchors.fill: parent

            BrowserWindow{
                id:_BrowserWindow
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.leftMargin: 8
                Layout.rightMargin: 8
            }
        }
    }
}
