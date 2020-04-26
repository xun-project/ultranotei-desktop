import QtQuick 2.13
import QtQuick.Controls 2.13

import UltraNote.UI 1.0
import UltraNote.UI.Controls 1.0

Item {
    id: _itm

    property alias title: reportTitle.text
    property var names: []
    property var values: []

    height: 150
    implicitHeight: height

    UNLabel {
        id: reportTitle

        type: UNLabel.Type.TypeExtraBold
        size: 18
        color: Theme.balanceReportTextColor
    }

    Column {
        id: reportCol

        anchors.top: reportTitle.bottom
        anchors.topMargin: reportCol.spacing

        width: parent.width
        height: 4 * (row0.height + reportCol.spacing) + 1

        spacing: 10


        UNBalanceReportRow {
            id: row0
            name: _itm.names[0]
            value: _globalProperties.convertToAmount(_itm.values[0], Qt.locale())
            unit: _globalProperties.currency
        }

        UNBalanceReportRow {
            name: _itm.names[1]
            value: _globalProperties.convertToAmount(_itm.values[1], Qt.locale())
            unit: _globalProperties.currency
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.balanceReportTextColor
        }

        UNBalanceReportRow {
            name: _itm.names[2]
            value: _globalProperties.convertToAmount(_itm.values[2], Qt.locale())
            unit: _globalProperties.currency
        }

        UNBalanceReportRow {
            name: ""
            value: _globalProperties.convertToAmount(_itm.values[2] * walletAdapter.fiatConverter.coinPrice, Qt.locale())
            unit: walletAdapter.fiatConverter.fiatId.toUpperCase()
        }
    }
}
