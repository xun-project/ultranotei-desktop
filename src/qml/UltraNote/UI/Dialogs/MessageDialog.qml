import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.13
import QtQuick.Layouts 1.13

import UltraNote.UI 1.0
import UltraNote.UI.Controls 1.0

UNDialog {
    id: control

    buttons: ListModel{}

    implicitWidth: 400

    visible: "" !== _controlLabel.text
    title: _messageDialogProperties.title
    modal: true
    closePolicy: Popup.NoAutoClose

    onAccepted: {
        _messageDialogProperties.title = ""
        _messageDialogProperties.text = ""
        _messageDialogProperties.okCancel = false
        if (null !== _messageDialogProperties.acceptCallback) {
            _messageDialogProperties.acceptCallback()
            _messageDialogProperties.acceptCallback = null
        }
    }

    onRejected: {
        _messageDialogProperties.title = ""
        _messageDialogProperties.text = ""
        _messageDialogProperties.okCancel = false
        _messageDialogProperties.acceptCallback = null
    }

    Item {
        id: _contentItem

        anchors.left: parent.left
        anchors.right: parent.right

        height: _contentData.height
        implicitHeight: height

        clip: true

        ColumnLayout {
            id: _contentData

            anchors.left: parent.left
            anchors.right: parent.right

            spacing: 0

            UNLabel {
                id: _controlLabel

                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter

                type: UNLabel.Type.TypeNormal

                lineHeight: 17
                lineHeightMode: Label.FixedHeight
                color: Theme.dialogTextColor
                elide: Label.ElideNone
                wrapMode: Label.WordWrap
                maximumLineCount: 10
                horizontalAlignment: Label.AlignLeft
                verticalAlignment: Label.AlignVCenter

                text: _messageDialogProperties.text
            }
        }
    }
}
