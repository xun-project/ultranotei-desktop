import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.13
import QtQuick.Layouts 1.13

import UltraNote.UI 1.0
import UltraNote.UI.Controls 1.0

UNDialog {
    id: _dialog

    function acceptAction() {
        if ('' === _labelField.text || '' === _addressField.text) {
            return
        }
        walletAdapter.addressBookTableModel.addAddress(_labelField.text, _addressField.text)
        clearFields()
        _dialog.close()
    }

    function rejectAction(){
        clearFields()
        _dialog.close()
        //_newRemoteNodeDialog.close()
    }
    function clearFields(){
        _labelField.text = ""
        _addressField.text = ""
    }

    buttons: ListModel {
        ListElement { type: UNDialog.ButtonType.TypeNormal; role: DialogButtonBox.AcceptRole; text: qsTr("Accept")}
        ListElement { type: UNDialog.ButtonType.TypeNormal; role: DialogButtonBox.RejectRole; text: qsTr("Cancel")}
    }

    implicitWidth: 400
    closePolicy: Popup.CloseOnEscape
    onAccepted: _dialog.acceptAction()
    onRejected: _dialog.rejectAction()
    title: qsTr("Set address")
    modal: true

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

            focus: true

            Keys.onReturnPressed: _dialog.acceptAction()

            property int labelWidth: Math.max(_labelLabel.implicitWidth, _addressLabel.implicitWidth)

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: implicitHeight
                Layout.maximumHeight: implicitHeight
                Layout.minimumHeight: implicitHeight

                spacing: 24

                UNLabel {
                    id: _labelLabel

                    Layout.preferredWidth: _contentData.labelWidth
                    Layout.maximumWidth: _contentData.labelWidth
                    Layout.minimumWidth: _contentData.labelWidth
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

                    text: qsTr("Label:")
                }

                UNTextField {
                    id: _labelField
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            UNLayoutSpacer {
                fixedHeight: 8
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: implicitHeight
                Layout.maximumHeight: implicitHeight
                Layout.minimumHeight: implicitHeight

                spacing: 24

                UNLabel {
                    id: _addressLabel
                    Layout.preferredWidth: _contentData.labelWidth
                    Layout.maximumWidth: _contentData.labelWidth
                    Layout.minimumWidth: _contentData.labelWidth
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

                    text: qsTr("Address:")
                }

                UNTextField {
                    id: _addressField
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }
    }
}
