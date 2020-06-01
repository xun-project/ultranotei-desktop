import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.13
import QtQuick.Window 2.13

import UltraNote.UI 1.0
import UltraNote.UI.Controls 1.0
import UltraNote.UI.Controls.Private 1.0

ApplicationWindow {
    id: _window

    property alias contentStack: mainView.children
    property bool maximized: visibility === Window.Maximized
    property int shadowLayerWidth: 10
    property color backgroundColor: "white"
    property alias statusBarColor: statusBar.color
    property bool isMinimize: false

    width: 1024 + 2 * shadowLayerWidth
    height: 768 + 2 * shadowLayerWidth

    color: "transparent"
    visible: true

    flags: Qt.Window | Qt.FramelessWindowHint | Qt.WindowMinimizeButtonHint

    onWindowStateChanged: {
        switch(windowState) {
        case 0:
            console.log("Main Window State: NORMALIZED")
            break;
        case 1:
            console.log("Main Window State: MINIMIZED")
            if(_globalProperties.minTrayEnabled === true){
                _window.isMinimize = true
                _window.close()
            }
            break;
        case 2:
            console.log("Main Window State: MAXIMIZED")
            break;
        default:
            break;
        }
    }

    UNElevatedPanel {
        id: shadowWrapper

        width: appWindow.width
        height: appWindow.height
        x: (_window.width - width) / 2
        y: (_window.height - height) / 2

        property int elevation: 5
        property bool shadowVisible: true

        Behavior on elevation {
            PropertyAnimation {
                target: shadowWrapper
                property: "elevation"
                duration: 100
            }
        }
    }

    MouseArea {
        id: resizeClicker

        anchors.centerIn: parent

        width: appWindow.width + 2 * resizeClicker_private.resizeFrameWidth
        height: appWindow.height + 2 * resizeClicker_private.resizeFrameWidth

        property point startPos: Qt.point(0,0)

        QtObject {
            id: resizeClicker_private
            readonly property int resizeFrameWidth: 5
        }

        hoverEnabled: true

        state: "NULL"

        states: [
            State {
                name: "HORIZONTAL"
                PropertyChanges {
                    target: resizeClicker
                    cursorShape: Qt.SizeHorCursor
                }
            },
            State {
                name: "VERTICAL"
                PropertyChanges {
                    target: resizeClicker
                    cursorShape: Qt.SizeVerCursor
                }
            },
            State {
                name: "TOPBOTTOMDIAG"
                PropertyChanges {
                    target: resizeClicker
                    cursorShape: Qt.SizeFDiagCursor
                }
            },
            State {
                name: "BOTTOMTOPDIAG"
                PropertyChanges {
                    target: resizeClicker
                    cursorShape: Qt.SizeBDiagCursor
                }
            },
            //NOTE diagonal states must have more priority than straight - please do not move or replace them
            State {
                name: "TOPLEFT"
                when: (resizeClicker.mouseX < (resizeClicker.pressed ? 50 : resizeClicker_private.resizeFrameWidth)) &&
                      (resizeClicker.mouseY < (resizeClicker.pressed ? 50 : resizeClicker_private.resizeFrameWidth))
                extend: "TOPBOTTOMDIAG"
            },
            State {
                name: "BOTTOMRIGHT"
                when: (resizeClicker.mouseX > appWindow.width - (resizeClicker.pressed ? 50 : 0)) &&
                      (resizeClicker.mouseY > appWindow.height - (resizeClicker.pressed ? 50 : 0))
                extend: "TOPBOTTOMDIAG"
            },
            State {
                name: "BOTTOMLEFT"
                when: (resizeClicker.mouseX < (resizeClicker.pressed ? 50 : resizeClicker_private.resizeFrameWidth)) &&
                      (resizeClicker.mouseY > appWindow.height - (resizeClicker.pressed ? 50 : resizeClicker_private.resizeFrameWidth))
                extend: "BOTTOMTOPDIAG"
            },
            State {
                name: "TOPRIGHT"
                when: (resizeClicker.mouseX > appWindow.width - (resizeClicker.pressed ? 50 : 0)) &&
                      (resizeClicker.mouseY < (resizeClicker.pressed ? 50 : resizeClicker_private.resizeFrameWidth))
                extend: "BOTTOMTOPDIAG"
            },
            State {
                name: "LEFT"
                when: (resizeClicker.mouseX < resizeClicker_private.resizeFrameWidth + (resizeClicker.pressed ? Math.min(200, appWindow.width) : 0)) &&
                      (resizeClicker.mouseY > resizeClicker_private.resizeFrameWidth) &&
                      (resizeClicker.mouseY < appWindow.width + resizeClicker_private.resizeFrameWidth)
                extend: "HORIZONTAL"
            },
            State {
                name: "RIGHT"
                when: (resizeClicker.mouseX > appWindow.width - (resizeClicker.pressed ? Math.min(200, appWindow.width) : 0)) &&
                      (resizeClicker.mouseY > resizeClicker_private.resizeFrameWidth) &&
                      (resizeClicker.mouseY < appWindow.width + resizeClicker_private.resizeFrameWidth)
                extend: "HORIZONTAL"
            },
            State {
                name: "TOP"
                when: (resizeClicker.mouseY < resizeClicker_private.resizeFrameWidth + (resizeClicker.pressed ? Math.min(200, appWindow.height) : 0))  &&
                      (resizeClicker.mouseX > resizeClicker_private.resizeFrameWidth) &&
                      (resizeClicker.mouseX < appWindow.width + resizeClicker_private.resizeFrameWidth)
                extend: "VERTICAL"
            },
            State {
                name: "BOTTOM"
                when: (resizeClicker.mouseY > appWindow.height - (resizeClicker.pressed ? Math.min(200, appWindow.width) : 0))  &&
                      (resizeClicker.mouseX > resizeClicker_private.resizeFrameWidth) &&
                      (resizeClicker.mouseX < appWindow.width + resizeClicker_private.resizeFrameWidth)
                extend: "VERTICAL"
            },
            State {
                name: "NULL"
            }
        ]

        onPressed: {
            startPos = Qt.point(mouse.x,mouse.y)
            shadowWrapper.visible = false
            shadowWrapper.shadowVisible = false
            shadowWrapper.elevation = 2
        }

        onReleased: {
            shadowWrapper.visible = true
            shadowWrapper.shadowVisible = true
            shadowWrapper.elevation = 5
        }

        onPositionChanged: {

            if(resizeClicker.pressed === true) {

                var deltaPosition = Qt.point(mouseX - startPos.x,
                                             mouseY - startPos.y)
                switch(state) {
                case "LEFT" :
                    _window.x = _window.x + deltaPosition.x
                    _window.width = _window.width - deltaPosition.x
                    break;
                case "RIGHT" :
                    _window.width = _window.width + deltaPosition.x
                    startPos = Qt.point(mouseX, mouseY)
                    break;
                case "TOP" :
                    _window.y = _window.y + deltaPosition.y
                    _window.height = _window.height - deltaPosition.y
                    break;
                case "BOTTOM" :
                    _window.height = _window.height + deltaPosition.y
                    startPos = Qt.point(mouseX, mouseY)
                    break;
                case "TOPLEFT" :
                    _window.x = _window.x + deltaPosition.x
                    _window.width = _window.width - deltaPosition.x
                    _window.y = _window.y + deltaPosition.y
                    _window.height = _window.height - deltaPosition.y
                    break;
                case "BOTTOMRIGHT" :
                    _window.width = _window.width + deltaPosition.x
                    _window.height = _window.height + deltaPosition.y
                    startPos = Qt.point(mouseX, mouseY)
                    break;
                case "BOTTOMLEFT" :
                    _window.x = _window.x + deltaPosition.x
                    _window.width = _window.width - deltaPosition.x
                    _window.height = _window.height + deltaPosition.y
                    startPos = Qt.point(0, mouseY)
                    break;
                case "TOPRIGHT" :
                    _window.y = _window.y + deltaPosition.y
                    _window.height = _window.height - deltaPosition.y
                    _window.width = _window.width + deltaPosition.x
                    startPos = Qt.point(mouseX, 0)
                    break;
                default:
                    state = "NULL"
                }
            }
        }

        onClicked: {
            mouse.accepted = false
        }
    }

    Rectangle {
        id: appWindow
        anchors.centerIn: parent
        width: _window.maximized === false ? _window.width - 2 * shadowLayerWidth : _window.width
        height: _window.maximized === false ? _window.height - 2 * shadowLayerWidth : _window.height
        color: _window.backgroundColor

        visible: true

        property bool maximized: _window.visibility === Window.Maximized

        MouseArea {
            anchors.fill: parent
            propagateComposedEvents: false
            preventStealing: true
        }

        ColumnLayout {
            id: applicationLayout

            anchors.fill: parent

            spacing: 0

            UNWindowStatusBar {
                id: statusBar

                Layout.fillWidth: true
                Layout.preferredHeight: 32

                z: mainView.z + 1

                onCloseWindow: {
                    _window.close()
                }

                onMaximizeWindow: {
                    _window.visibility = _window.visibility === Window.Windowed ?
                                Window.Maximized :
                                Window.Windowed
                }

                onMinimizeWindow: {
                    _window.visibility = Window.Minimized
                }

                MouseArea {
                    id: moveClicker

                    anchors.fill: parent

                    property var startPos: Qt.point(1,1)

                    propagateComposedEvents: true
                    preventStealing: false

                    onPressed: {
                        startPos = Qt.point(mouse.x,mouse.y)
                    }

                    onReleased: {
                    }

                    onPositionChanged: {
                        if(moveClicker.pressed === true) {
                            var deltaPosition = Qt.point(mouseX - startPos.x,
                                                         mouseY - startPos.y)

                            _window.x = _window.x + deltaPosition.x
                            _window.y = _window.y + deltaPosition.y

                            appWindow.x = appWindow.x + deltaPosition.x
                            appWindow.y = appWindow.y + deltaPosition.y
                        }
                    }

                    onClicked: {
                        mouse.accepted = false
                    }
                }

                UNLabel {
                    anchors.centerIn: parent
                    width: implicitWidth

                    type: UNLabel.Type.TypeMedium

                    size: 16
                    color: Theme.statusBarTitleColor
                    horizontalAlignment: Label.AlignHCenter
                    verticalAlignment: Label.AlignVCenter

                    text: currencyAdapter.getCurrencyDisplayName() + qsTr(" Infinity ") + settings.getVersion()
                }


            }


            Rectangle {
                id: mainView
                Layout.fillWidth: true
                Layout.fillHeight: true

                color: Theme.pageBackgroundColor
            }
        }
    }
}
