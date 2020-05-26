import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.13
import QtQuick.Layouts 1.13
import QtQuick.Dialogs 1.2 as OldDialogs

import UltraNote.UI 1.0
import UltraNote.UI.Controls 1.0

UNDialogInfinity {
    id: _dialog

    function showImportKeyDlg() {
        _ImportTrackingWalletDialog.open()
    }

    function acceptTrackingKey() {
        if ("" === _TrackingkeyTextField.text) {
            _messageDialogProperties.acceptCallback = _dialog.showImportKeyDlg
            _messageDialogProperties.showMessage(qsTr("Error"), qsTr("Tracking Key cannot be empty"))
            return
        }
        if ("" === _walletPathField.text) {
            _messageDialogProperties.acceptCallback = _dialog.showImportKeyDlg
            _messageDialogProperties.showMessage(qsTr("Error"), qsTr("Wallet path cannot be empty"))
            return
        }

        walletAdapter.importTrackingkey(_TrackingkeyTextField.text
                                        ,_walletPathField.text)

        _TrackingkeyTextField.text = ""
        _walletPathField.text = ""

        _ImportTrackingWalletDialog.close()
        _ImportWalletDialog.close()
    }

    headerAlignmentCenter: true

    implicitWidth: 430
    closePolicy: Popup.NoAutoClose
    title: qsTr("IMPORT TRACKING WALLET")
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
            UNLabel {
                id: _noteLabel

                Layout.fillWidth: true
                Layout.preferredHeight: implicitHeight
                Layout.maximumHeight: implicitHeight
                Layout.minimumHeight: implicitHeight

                type: UNLabel.Type.TypeNormal

                lineHeight: 17
                lineHeightMode: Label.FixedHeight
                color: Theme.dialogInfinityTextColor
                elide: Label.ElideNone
                wrapMode: Label.WordWrap
                maximumLineCount: 10
                horizontalAlignment: Label.AlignHCenter
                verticalAlignment: Label.AlignVCenter

                text: qsTr("Import a tracking wallet (view-only)")
            }

            UNLayoutSpacer {
                fixedHeight: 30
            }

            UNLabel {
                id: _TrackingKeyLabel

                Layout.fillWidth: true
                Layout.preferredHeight: implicitHeight
                Layout.maximumHeight: implicitHeight
                Layout.minimumHeight: implicitHeight

                type: UNLabel.Type.TypeNormal

                lineHeight: 17
                lineHeightMode: Label.FixedHeight
                color: Theme.dialogInfinityTextColor

                elide: Label.ElideNone
                wrapMode: Label.WordWrap

                horizontalAlignment: Label.AlignLeft
                verticalAlignment: Label.AlignVCenter
                text: "Tracking Key"
            }
            UNLayoutSpacer {
                fixedHeight: 5
            }
            UNTextField {
                id: _TrackingkeyTextField
                height:35
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                focus: _dialog.visible
            }
            UNLayoutSpacer {
                fixedHeight: 15
            }
            UNLabel {
                id: _WalletPathLabel

                Layout.fillWidth: true
                Layout.preferredHeight: implicitHeight
                Layout.maximumHeight: implicitHeight
                Layout.minimumHeight: implicitHeight

                type: UNLabel.Type.TypeNormal

                lineHeight: 17
                lineHeightMode: Label.FixedHeight
                color: Theme.dialogInfinityTextColor

                elide: Label.ElideNone
                wrapMode: Label.WordWrap

                horizontalAlignment: Label.AlignLeft
                verticalAlignment: Label.AlignVCenter
                text: "Wallet Path"
            }
            UNLayoutSpacer {
                fixedHeight: 5
            }

            RowLayout {
                spacing: 5
                UNTextField {
                    id: _walletPathField
                    height:35
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                }

                UNButton {
                    id: _browseButton
                    Layout.alignment: Qt.AlignVCenter

                    height:35
                    width:50
                    text: qsTr("...")
                    activeBorderColor: "#444444"
                    onClicked: _walletPathFileDialog.open()
                }
            }

            UNLayoutSpacer {
                fixedHeight: 30
            }

            UNButton {
                Layout.fillWidth: true
                text: qsTr("IMPORT")
                onClicked: _dialog.acceptTrackingKey()
            }

            UNLayoutSpacer {
                fixedHeight: 15
            }

            UNButton {
                Layout.fillWidth: true
                text: qsTr("CANCEL")
                activeBorderColor: "#444444"
                onClicked: {
                    _ImportWalletDialog.close()
                    _dialog.close()
                }
            }
        }
    }
    OldDialogs.FileDialog {
        id: _walletPathFileDialog

        visible: false

        selectExisting: false
        folder: shortcuts.home
        title: qsTr("Wallet file")
        defaultSuffix: "wallet"
        nameFilters: ["Wallet Files (*.wallet)"]

        onAccepted: {
            _walletPathField.text = walletAdapter.toLocalFile(_walletPathFileDialog.fileUrl)
        }
    }
}
