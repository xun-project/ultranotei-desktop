import QtQuick 2.13
import QtQuick.Controls 2.13

import UltraNote.UI 1.0
import UltraNote.UI.Controls 1.0

Menu {
    id: _itm

    property color color: Theme.statusBarMenuColor

    enter: Transition {
        NumberAnimation { property: "scale"; from: 0.9; to: 1.0; easing.type: Easing.OutQuint; duration: 220 }
        NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; easing.type: Easing.OutCubic; duration: 150 }
    }

    exit: Transition {
        NumberAnimation { property: "scale"; from: 1.0; to: 0.9; easing.type: Easing.OutQuint; duration: 220 }
        NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; easing.type: Easing.OutCubic; duration: 150 }
    }

    background: UNElevatedPanel {
        color: _itm.color
        implicitWidth: 220
        radius: 0
    }

    contentItem: ListView {
        leftMargin: 16
        implicitHeight: contentHeight

        model: _itm.contentModel
        interactive:  false
        clip: true
        currentIndex: _itm.currentIndex
        spacing: 21
    }
}
