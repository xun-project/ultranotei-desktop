import QtQuick 2.13
import QtQuick.Window 2.13
import QtQuick.Controls 2.13

Window {
    id: _splash

    property int timeoutInterval: 2000

    signal timeout()

    width: _background.width
    height: _background.height

    //TODO move
    title: currencyAdapter.getCurrencyDisplayName() + qsTr(" Infinity ") + settings.getVersion()
    modality: Qt.ApplicationModal
    flags: Qt.SplashScreen
    color: "transparent"

    Image {
        id: _background

        source: "qrc:/images/splash"

        MouseArea {
            anchors.fill: parent
            onClicked: Qt.quit()
        }

        Label {
            anchors.bottom: parent.bottom
            text: qsTr("Loading blockchain...")
            color: "black"
            font {
                bold: true
                pointSize: 14
            }
        }
    }

    Timer {
        interval: timeoutInterval; running: true; repeat: false
        onTriggered: {
            visible = false
            _splash.timeout()
        }
    }

    Component.onCompleted: visible = true
}
