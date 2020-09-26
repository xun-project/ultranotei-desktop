import QtQuick 2.13
import QtQuick.Controls 2.13

import UltraNote.UI 1.0
import UltraNote.UI.Controls 1.0

Row {
    id: _itm

    property alias name: _name.text
    property alias value: _value.text
    property alias unit: _valueUnit.text

    height: _name.height
    width: parent.width

    spacing: 2

    Label {
        id: _name

        width: 0.45*parent.width

        color: Theme.balanceReportTextColor
        font.pointSize: Theme.textPointSize
        clip: true
        elide: Text.ElideRight
    }

    UNToolTipLabel {
        id: _value

        font {
            pointSize: Theme.textPointSize
            bold: true
        }
        width: parent.width - _name.width - _valueUnit.width
        color: Theme.balanceReportTextColor
        clip: true
        elide: Text.ElideRight
    }

    Label {
        id: _valueUnit

        color: Theme.balanceReportTextColor
        font.pointSize: Theme.textPointSize
        clip: true
        elide: Text.ElideRight
    }
}
