import QtQuick 2.13
import QtQuick.Layouts 1.13
import QtGraphicalEffects 1.0

Item {
    id: _itm

    property color color: "#ffffff"

    signal closeWindow()
    signal minimizeWindow()
    signal maximizeWindow()

    height: 24

    Rectangle{
        id: background
        anchors.fill: parent
        color: _itm.color
        opacity: 1.0
    }

    RowLayout {
        anchors.fill: parent
        spacing: 8
        opacity: 0.8

        Item {
            Layout.fillHeight: true
            Layout.fillWidth: true
        }

        Item{
            id: minimizeIconWrapper

            Layout.preferredHeight: 24
            Layout.preferredWidth: 24

            Image {
                id: minimizeIcon

                anchors.verticalCenter: parent.verticalCenter

                source: "qrc:/icons/resources/icons/statusbar_minimize.svg"
                width: 24
                height: 24

                mipmap: true
                cache: true
                visible: false
            }

            ColorOverlay {
                anchors.fill: minimizeIcon

                cached: true
                source: minimizeIcon
                color: "white"
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    _itm.minimizeWindow()
                }
            }
        }

        Item{
            id: maximizeIconWrapper

            Layout.preferredHeight: 24
            Layout.preferredWidth: 24

            Image {
                id: maximizeIcon

                anchors.verticalCenter: parent.verticalCenter

                source: "qrc:/icons/resources/icons/statusbar_maximize.svg"
                width: 24
                height: 24

                mipmap: true
                cache: true
                visible: false
            }

            ColorOverlay {
                anchors.fill: maximizeIcon

                cached: true
                source: maximizeIcon
                color: "white"
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    _itm.maximizeWindow()
                }
            }
        }

        Item{
            id: closeIconWrapper

            Layout.rightMargin: 16
            Layout.preferredHeight: 24
            Layout.preferredWidth: 24

            Image {
                id: closeIcon

                anchors.verticalCenter: parent.verticalCenter

                source: "qrc:/icons/resources/icons/statusbar_close.svg"
                width: 24
                height: 24

                mipmap: true
                cache: true
                visible: false
            }

            ColorOverlay {
                anchors.fill: closeIcon

                cached: true
                source: closeIcon
                color: "white"
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    _itm.closeWindow()
                }
            }
        }
    }
}
