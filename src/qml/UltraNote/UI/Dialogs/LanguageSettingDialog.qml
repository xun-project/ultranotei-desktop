import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.13
import QtQuick.Layouts 1.13

import UltraNote.UI 1.0
import UltraNote.UI.Controls 1.0

UNDialogInfinity {
    id: _dialog

    headerAlignmentCenter: true

    implicitWidth: 300
    closePolicy: Popup.NoAutoClose
    title: qsTr("CHANGE LANGUAGE")
    modal: true

    Action {
        id: focus
        shortcut: StandardKey.Copy
        onTriggered: if(_mnemonicSeedText.focus) clipboard.setText(_mnemonicSeedText.selectedText)
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
                id: _mnemonicSeedLabel

                Layout.fillWidth: true
                Layout.preferredHeight: implicitHeight
                Layout.maximumHeight: implicitHeight
                Layout.minimumHeight: implicitHeight

                type: UNLabel.Type.TypeBold
                size:16

                lineHeight: 17
                lineHeightMode: Label.FixedHeight
                color: Theme.dialogInfinityTitleTextColor

                elide: Label.ElideNone
                wrapMode: Label.WordWrap

                horizontalAlignment: Label.AlignLeft
                verticalAlignment: Label.AlignVCenter
                text: qsTr("Select your prefered language")
            }

            UNLayoutSpacer {
                fixedHeight: 15
            }

            RowLayout{
                id:_parentRow
                ColumnLayout{
                    height: _parentRow.height
                    spacing: 26
                    UNIcon {
                        id:_EnglishIcon
                        size: 24
                        source: "qrc:/images/images/en.png"
                        toolTip: qsTr("English")
                    }

                    UNIcon {
                        id: _RussianIcon
                        size: 24
                        source: "qrc:/images/images/ru.png"
                        toolTip: qsTr("Russian")
                    }

                    UNIcon {
                        id:_TurkishIcon
                        size: 24
                        source: "qrc:/images/images/tr.png"
                        toolTip: qsTr("Turkish")
                    }

                    UNIcon {
                        id:_ChineseIcon
                        size: 24
                        source: "qrc:/images/images/cn.png"
                        toolTip: qsTr("Chinese")
                    }
                }
                ColumnLayout{
                    UNRadioButton {
                        id:_EnglishButton
                        height: 40

                        textColor: Theme.radioButtonInfinityTextColor
                        frameColor: Theme.radioButtonInfinityFrameColor
                        activeColor: Theme.radioButtonInfinityActiveColor

                        checked: "_en.qm" === walletAdapter.selectedLangauge
                        text: qsTr("English")

                        onClicked: walletAdapter.selectedLangauge = "_en.qm"
                    }
                    UNRadioButton {
                        id:_RussianButton

                        height: 40

                        textColor: Theme.radioButtonInfinityTextColor
                        frameColor: Theme.radioButtonInfinityFrameColor
                        activeColor: Theme.radioButtonInfinityActiveColor

                        checked: "_ru.qm" === walletAdapter.selectedLangauge
                        text: qsTr("Russian")

                        onClicked: walletAdapter.selectedLangauge = "_ru.qm"
                    }
                    UNRadioButton {
                        id:_TurkishButton

                        height: 40

                        textColor: Theme.radioButtonInfinityTextColor
                        frameColor: Theme.radioButtonInfinityFrameColor
                        activeColor: Theme.radioButtonInfinityActiveColor

                        checked: "_tr.qm" === walletAdapter.selectedLangauge
                        text: qsTr("Turkish")

                        onClicked: walletAdapter.selectedLangauge = "_tr.qm"
                    }
                    UNRadioButton {
                        id:_ChineseButton

                        height: 40

                        textColor: Theme.radioButtonInfinityTextColor
                        frameColor: Theme.radioButtonInfinityFrameColor
                        activeColor: Theme.radioButtonInfinityActiveColor

                        checked: "_cn.qm" === walletAdapter.selectedLangauge
                        text: qsTr("Chinese")

                        onClicked: walletAdapter.selectedLangauge = "_cn.qm"
                    }
                }
            }

            UNLayoutSpacer {
                fixedHeight: 15
            }

            UNButton {
                Layout.fillWidth: true
                text: qsTr("SAVE")
                onClicked: {
                    walletAdapter.loadLanguage()
                    _dialog.close()
                    _RestartWalletDialog.open()
                }
            }

            UNLayoutSpacer {
                fixedHeight: 20
            }

            UNButton {
                Layout.fillWidth: true
                text: qsTr("CANCEL")
                activeBorderColor: Theme.buttonDisabledBorderColor
                onClicked: _dialog.close()
            }
        }
    }
}
