import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.13
import QtQuick.Controls.Material.impl 2.13

import UltraNote.UI 1.0
import UltraNote.UI.Controls 1.0

Button {
    id: _itm

    property int radius: 4
    property color activeColor: Theme.buttonActiveColor
    property color baseColor: Theme.buttonBaseColor
    property color disabledColor: Theme.buttonDisabledColor
    property color textColor: Theme.buttonTextColor
    property color disabledTextColor: Theme.buttonDisabledTextColor
    property color activeBorderColor: Theme.buttonActiveBorderColor
    property color disabledBorderColor: Theme.buttonDisabledBorderColor
    property int lableTextSize

    width: Math.max(_privateProperties.defaultWidth, _text.implicitWidth + 2 * 16 )
    height: _privateProperties.defaultHeight

    implicitWidth: width
    implicitHeight: height

    QtObject {
        id: _privateProperties

        readonly property int defaultWidth: 120
        readonly property int defaultHeight: 40
    }

    autoExclusive: false
    text: ""


    background: UNElevatedPanel {
        id: _background

        anchors.fill: parent

        visible: !_itm.flat

        radius: _itm.radius
        color: !_itm.enabled ? _itm.disabledColor : _itm.down || (_itm.checked && _itm.checkable) ? _itm.activeColor : _itm.baseColor
        borderColor: _itm.enabled ? _itm.activeBorderColor : _itm.disabledBorderColor
        elevation: !_itm.enabled ? 1 : _itm.down ? 8 : 2
        opacity: !_itm.enabled ? 0.88 : 1.0
    }

    contentItem: UNLabel {
        id: _text

        anchors.centerIn: parent

        color: _itm.enabled ? _itm.textColor : _itm.disabledTextColor
        text: _itm.text
        type: UNLabel.Type.TypePushButton
        font.letterSpacing: 0.65
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font.capitalization: Font.AllUppercase
        size: lableTextSize

        Behavior on text {
            NumberAnimation {
                target: _text
                property: "opacity"
                duration: 125
                from: 0.0
                to: 1.0
            }
        }
    }
}
