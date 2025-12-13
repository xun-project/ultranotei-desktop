import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.13
import QtQuick.Shapes 1.13

import UltraNote.UI 1.0

Item {
    id: _itm

    property alias placeholderText: _placeholder.text
    property alias text: _textEdit.text
    property bool readOnly: false

    property color activeColor: Theme.textAreaActiveColor
    property color backgroundColor: Theme.messageDetailsDialogTextAreaColor
    property color textColor: "#FFFFFF"
    property string placeholderText: ""
    property var inputMethodHints: Qt.ImhNone
    property color selectedTextColor: Theme.textAreaSelectedTextColor
    property color selectionColor: Theme.textAreaSelectionColor
    property alias _textArea: _textEdit
    property var textAppearance: TextEdit.RichText

    QtObject {
        id: _privateProperties

        readonly property int textInputHeight: 40
        readonly property int cornerRadius: 0
        readonly property bool active: _textEdit.activeFocus || _textEdit.length > 0
    }

    clip: true

    Canvas {
        id: _background

        anchors.fill: parent

        property double activeOpacity: Theme.textAreaActiveOpacity
        property double restingOpacity: Theme.textAreaRestingOpacity

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

    UNLabel {
        id: _placeholder

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: (_privateProperties.active ? 16 : Theme.textAreaTextSize + 11) - _placeholder.size
        anchors.leftMargin: 12
        anchors.rightMargin: 12

        type: UNLabel.Type.TypeNormal
        size: (_privateProperties.active ? 12 : Theme.textAreaTextSize)
        text: _itm.placeholderText
        color: _privateProperties.active ? Qt.lighter(Theme.textAreaPlaceholderTextColor) : Theme.textAreaPlaceholderTextColor
        elide: Text.ElideRight
        lineHeight: (_privateProperties.active ? 12 : Theme.textAreaTextSize)
        lineHeightMode: Text.FixedHeight

        Behavior on anchors.topMargin {
            SmoothedAnimation{
                duration: 150
            }
        }

        Behavior on size {
            SmoothedAnimation{
                duration: 150
            }
        }

        Behavior on lineHeight {
            SmoothedAnimation{
                duration: 150
            }
        }

        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }
    }

    Flickable {
        id: _textEditFlickable

        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.topMargin: 16
        anchors.bottomMargin: 16

        contentHeight: _textEdit.height
        clip: true

        boundsBehavior: Flickable.StopAtBounds

        ScrollIndicator.vertical: ScrollIndicator {
            orientation: Qt.Vertical
            visible: _textEditFlickable.height < _textEdit.implicitHeight
            background: Item {}

            contentItem: Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter

                height: 200
                implicitWidth: 4
                implicitHeight: 200
                radius: width / 2

                color: Theme.scrollIndicatorColor
            }
        }

        TextEdit {
            id: _textEdit

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.rightMargin: 8

            height: Math.max(_itm.height, implicitHeight)

            readOnly: _itm.readOnly



            wrapMode: TextArea.WrapAnywhere

            clip: true
            textFormat: textAppearance
            color: _itm.textColor
            font.pixelSize: Theme.textAreaTextSize
            font.family: UNFontsFactory.workSansRegular.name
            verticalAlignment: Qt.AlignTop
            horizontalAlignment: Qt.AlignLeft
            persistentSelection: true
            selectByKeyboard: true
            selectByMouse: true
            mouseSelectionMode:
                TextEdit.SelectCharacters
            selectedTextColor: _itm.selectedTextColor
            selectionColor: _itm.selectionColor

            inputMethodHints: Qt.ImhNoPredictiveText |
                              Qt.ImhNoAutoUppercase  |
                              Qt.ImhSensitiveData

            cursorDelegate: Rectangle {
                id: _indicator

                height: 22
                width: 1
                color: _itm.activeColor

                Timer {
                    id: _indicatorBlinkingTimer

                    interval: 750
                    repeat: true
                    running: _textEdit.activeFocus

                    onRunningChanged: {
                        if(!running) {
                            _indicator.visible = false
                        }
                    }

                    onTriggered: {
                        _indicator.visible = !_indicator.visible
                    }
                }
            }
        }
    }
}
