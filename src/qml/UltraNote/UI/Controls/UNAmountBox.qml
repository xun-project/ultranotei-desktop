import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.13
import QtQuick.Shapes 1.13

import UltraNote.UI 1.0

TextField {
    id: _AmountEditBox
    property real value: 0
    property string resetDecimals: "0.000000"
    property real maxLimitNumber: 1000000000000
    property string maxLimitString: "1000000.000000"
    property real minLimitNumber: 1000000
    property string minLimitString: "1.000000"
    text: resetDecimals
    height: 40
    implicitHeight: height
    implicitWidth: if(text.length > 12){text.length * 12}else{120}
    horizontalAlignment: Text.AlignHCenter
    Material.theme: Material.Dark
    Material.accent: Theme.spinBoxActiveColor
    Material.foreground: Theme.spinBoxTextColor
    font.pixelSize: Theme.spinBoxFontSize
    font.family: UNFontsFactory.workSansMedium.name

    validator: DoubleValidator {
        bottom: 0
        top:  100000000.0
    }
    onTextChanged: {
        if(text){
            if(text.indexOf(".") !== -1  &&  (text.indexOf(".") + 7) < text.length )
                _AmountEditBox.text = text.substring(0, text.indexOf(".") + 7)

            value = Number.fromLocaleString(_AmountEditBox.text) * _globalProperties.actStepSize

            if(value > maxLimitNumber){
                _AmountEditBox.text = maxLimitString
            }
            else if(value < minLimitNumber){
                _AmountEditBox.text = minLimitString
            }
        }
    }
    function updateFee(newValue , locale){
        value = newValue
        text = _globalProperties.convertToAmount(newValue, locale)
        if(text.indexOf(".") != -1){
            var textVal = text.split(".")[1]

            var missingDecimals = 6 - textVal.length

            if(missingDecimals > 0)
                for (var i = 0; i < missingDecimals; i++)
                    text += "0"
        }
    }
}
