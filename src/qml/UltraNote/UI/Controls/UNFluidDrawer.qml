import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.13

import UltraNote.UI.Controls 1.0

UNElevatedPanel {
    id: _itm

    property color backgroundColor: "#ffffff"
    property alias contentItem: _contentItem.data

    color: _itm.backgroundColor

    implicitHeight: height
    implicitWidth: width

    state: "expanded"

    states: [
        State {
            name: "collapsed"
            PropertyChanges {
                target: _itm
                width: 88
            }
        },
        State {
            name: "expanded"
            PropertyChanges {
                target: _itm
                width: 280
            }
        }
    ]

    Behavior on width {
        SmoothedAnimation {
            duration: 250
        }
    }

    Item {
        id: _contentItem

        anchors.fill: parent

        clip: true
    }
}
