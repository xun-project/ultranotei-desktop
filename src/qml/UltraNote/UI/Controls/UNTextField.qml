import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.13
import QtQuick.Shapes 1.13

import UltraNote.UI 1.0

TextField {
    id: _itm

    property color activeColor: Theme.textFieldActiveColor
    property color backgroundColor: Theme.textFieldBackgroundColor
    signal enterPressed()


    height: 40
    width: 270

    implicitHeight: height
    implicitWidth: width

    leftPadding: 8
    rightPadding: 8
    bottomPadding: 6

    QtObject {
        id: _privateProperties

        readonly property int textInputHeight: 40
        readonly property int cornerRadius: 4
        readonly property bool active: _itm.focus || _itm.text.length > 0
    }

    Keys.onReturnPressed:{
        _itm.enterPressed()
    }
    Keys.onEnterPressed: {
        _itm.enterPressed()
    }

    color: "#FFFFFF"
    placeholderTextColor: Theme.textFieldPlaceholderTextColor
    font.pixelSize: Theme.textFieldTextSize
    font.family: UNFontsFactory.workSansRegular.name
    selectionColor: Theme.textFieldSelectionColor
    selectedTextColor:Theme.textFieldSelectedTextColor
    persistentSelection: true
    selectByMouse: true
    mouseSelectionMode:
        TextEdit.SelectCharacters

    background: Item {
        anchors.fill: parent

        Canvas {
            id: _background

            anchors.fill: parent

            property double activeOpacity: Theme.textFieldActiveOpacity
            property double restingOpacity: Theme.textFieldRestingOpacity

            property double backgroundOpacity: _privateProperties.active ? activeOpacity
                                                                         : restingOpacity

            onBackgroundOpacityChanged: {
                requestPaint()
            }

            Behavior on backgroundOpacity {
                NumberAnimation{
                    duration: 150
                }
            }

            onPaint: {
                var ctx = getContext("2d")

                ctx.clearRect(0,0, _background.width, _background.height)
                ctx.fillStyle = _itm.backgroundColor
                ctx.globalAlpha = _background.backgroundOpacity
                ctx.beginPath();
                ctx.moveTo(0, _background.height);
                ctx.lineTo(0, _privateProperties.cornerRadius)
                ctx.quadraticCurveTo(0,0,_privateProperties.cornerRadius,0)
                ctx.lineTo(_background.width - _privateProperties.cornerRadius, 0)
                ctx.quadraticCurveTo(_background.width, 0, _background.width, _privateProperties.cornerRadius)
                ctx.lineTo(_background.width, _background.height)
                ctx.lineTo(0, _background.height)
                ctx.closePath()
                ctx.fill();
            }
        }

        Rectangle {
            id: _bottomLine

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            height: 2

            opacity: 0.3
            color: _itm.backgroundColor
        }

        Rectangle {
            id: _bottomLineIndicator

            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter

            color: _itm.activeColor
            height: 2

            states: [
                State {
                    name: "active"
                    when: _privateProperties.active
                    PropertyChanges {
                        target: _bottomLineIndicator
                        width: _itm.width
                        opacity: 1.0
                    }
                },
                State {
                    name: "rested"
                    when: !_privateProperties.active
                    PropertyChanges {
                        target: _bottomLineIndicator
                        width: _itm.width * 0.75
                        opacity: 0.0
                    }
                }
            ]

            transitions: [
                Transition {
                    from: "rested"
                    to: "active"
                    ParallelAnimation {
                        NumberAnimation {
                            target: _bottomLineIndicator
                            properties: "width"
                            duration: 175
                            easing.type: Easing.OutCubic
                        }
                        OpacityAnimator{
                            target: _bottomLineIndicator
                            from: 0.0
                            to: 1.0
                            duration: 75
                        }
                    }
                },
                Transition {
                    from: "active"
                    to: "rested"
                    ParallelAnimation {
                        NumberAnimation {
                            target: _bottomLineIndicator
                            properties: "width"
                            duration: 175
                            easing.type: Easing.OutCubic
                        }
                        OpacityAnimator{
                            target: _bottomLineIndicator
                            from: 1.0
                            to: 0.0
                            duration: 75
                        }
                    }
                }
            ]
        }
    }
}
