import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.13

import UltraNote.UI 1.0

Row {
    id: control
    property alias value: controlSlider.value
    property int defaultLevel: 2
    property alias from: controlSlider.from
    property alias to: controlSlider.to
    property alias stepSize: controlSlider.stepSize
    spacing: 5

    height: controlSlider.height

    Slider {
        id: controlSlider
        from: 0
        to: 10
        stepSize: 1
        value: control.defaultLevel
        snapMode: Slider.SnapAlways
        handle {
            width: sliderBackground.posStep
            height: sliderBackground.posStep
        }
        background: Rectangle {
            id: sliderBackground
            readonly property real posStep: width / (controlSlider.to + 1)
            x: controlSlider.leftPadding
            y: controlSlider.topPadding + controlSlider.availableHeight / 2 - height / 2
            implicitWidth: 200
            implicitHeight: 4
            width: controlSlider.availableWidth
            height: implicitHeight
            radius: 2
            color: "#e4e4e4"
            Repeater {
                width: parent.width
                model: controlSlider.to + 1
                Rectangle {
                    x: index * sliderBackground.posStep + sliderBackground.posStep / 2
                    y: -(height - sliderBackground.height) / 2
                    height: 2 * sliderBackground.height
                    width: 1
                    color: sliderBackground.color
                }
            }
        }
    }

    UNTextField {
        height: controlSlider.height
        width: height

        text: controlSlider.value
        validator: IntValidator { bottom: controlSlider.from; top: controlSlider.to }
        onTextChanged: controlSlider.value = parseInt(text, 10)
        font.pointSize: Theme.textPointSize
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
    }
}
