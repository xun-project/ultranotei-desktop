import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.13
import QtQuick.Shapes 1.13

import UltraNote.UI 1.0

Slider {
    id: _itm

    Material.accent: Theme.sliderActiveColor
    Material.foreground: Theme.sliderBackgroundColor

    QtObject {
        id: _privateProperties

        readonly property int defaultHandleSize: 12
    }

    handle {
        width: _privateProperties.defaultHandleSize
        height: _privateProperties.defaultHandleSize
    }

    //                        background: Rectangle {
    //                            id: _sliderBackground

    //                            readonly property real posStep: width / (_anonymitySlider.to + 1)

    //                            x: _anonymitySlider.leftPadding
    //                            y: _anonymitySlider.topPadding + _anonymitySlider.availableHeight / 2 - height / 2

    //                            implicitWidth: 200
    //                            implicitHeight: 4

    //                            width: _anonymitySlider.availableWidth
    //                            height: implicitHeight
    //                            radius: 2
    //                            color: "#e4e4e4"

    //                            Repeater {
    //                                width: parent.width
    //                                model: _anonymitySlider.to + 1

    //                                Rectangle {
    //                                    x: index * _sliderBackground.posStep + _sliderBackground.posStep / 2
    //                                    y: -(height - _sliderBackground.height) / 2
    //                                    height: 2 * _sliderBackground.height
    //                                    width: 1
    //                                    color: _sliderBackground.color
    //                                }
    //                            }
    //                        }
}
