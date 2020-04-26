import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.13
import QtQuick.Shapes 1.13

import UltraNote.UI 1.0

SpinBox {
    id: _itm

    height: 40

    implicitHeight: height

    Material.theme: Material.Dark
    Material.accent: Theme.spinBoxActiveColor
    Material.foreground: Theme.spinBoxTextColor

    font.pixelSize: Theme.spinBoxFontSize
    font.family: UNFontsFactory.workSansMedium.name
}
