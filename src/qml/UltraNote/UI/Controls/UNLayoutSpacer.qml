import QtQuick 2.13
import QtQuick.Layouts 1.13

Item {
    id: _itm

    property var fixedWidth: undefined
    property var fixedHeight: undefined

    Layout.fillHeight: _itm.fixedHeight === undefined
    Layout.fillWidth: _itm.fixedWidth === undefined

    Component.onCompleted: {
        if(_itm.fixedHeight !== undefined) {
            Layout.preferredHeight =_itm.fixedHeight
            Layout.minimumHeight =_itm.fixedHeight
            Layout.maximumHeight = _itm.fixedHeight
        }

        if(_itm.fixedWidth !== undefined) {
            Layout.preferredWidth = _itm.fixedWidth
            Layout.minimumWidth = _itm.fixedWidth
            Layout.maximumWidth = _itm.fixedWidth
        }
    }
}
