import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.13

import QrImage 1.0
import UltraNote.UI 1.0
import UltraNote.UI.Controls 1.0

UNPage {
    id: _page

    objectName: "receive_page"

    title: qsTr("Receive")

    function getQrBorderWidth() {
        //fixed(english only): 250
        return Math.max(_publicAddressHeaderText.width,
                        _privateSpendKeyHeaderText.width,
                        _privateViewKeyHeaderText.width) + 90;
    }

    contentItem: Item {
        anchors.fill: parent

        /*transform: [
            Scale {
                id: scale;
                xScale: yScale;
                yScale: _page.height / _pageContent.childrenRect.height
            },
            Translate {
                x: (_page.width - _pageContent.childrenRect.width * scale.xScale) / 2;
                y: (_page.height - _pageContent.childrenRect.height * scale.yScale) / 2;
            }
        ]*/

        Flickable {
            anchors.fill: parent
            anchors.margins: 20

            //clip: true

            boundsBehavior: Flickable.StopAtBounds
            contentHeight: _pageContent.height

            Column {
                id: _pageContent

                anchors.left: parent.left
                anchors.right: parent.right

                height: childrenRect.height

                spacing: 0

                Item{
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 24
                }

                Rectangle {
                    id: _publicAddressItem

                    property string addressText: walletAdapter.publicAddress

                    anchors.horizontalCenter: parent.horizontalCenter

                    width: getQrBorderWidth()
                    height: 307

                    onAddressTextChanged: _publicAddressQrImage.sourceText = addressText

                    color: Theme.barcodeBackgroundColor
                    border.color : Theme.barcodeBackgroundBorderColor

                    radius: 15

                    Column {
                        anchors.fill: parent

                        anchors.margins: 24

                        spacing: 24

                        Item {
                            id:_publicAddressHeaderItem

                            anchors.left: parent.left
                            anchors.right: parent.right

                            height: 24

                            UNLabel {
                                id:_publicAddressHeaderText
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter

                                height: implicitHeight

                                type: UNLabel.Type.TypeExtraBold
                                size: 15
                                font.letterSpacing: 1.15
                                elide: Label.ElideNone
                                wrapMode: Label.NoWrap
                                color: Theme.barcodeTitleColor
                                horizontalAlignment: Label.AlignLeft
                                verticalAlignment: Label.AlignVCenter

                                text: qsTr("Public Address key")
                            }

                            UNIcon {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter

                                size: 24
                                source: "qrc:/icons/resources/icons/clipboard_copy_icon.svg"
                                toolTip: qsTr("Copy to Clipboard")
                                color: Theme.barcodeIconColor
                                clickable: true

                                onClicked: {
                                    clipboard.setText(_publicAddressItem.addressText)
                                }
                            }
                        }

                        QrImage {
                            id: _publicAddressQrImage

                            anchors.horizontalCenter: parent.horizontalCenter

                            dimension : 215
                            height: 215
                            width: height

                            visible: "" !== _publicAddressQrImage.sourceText
                        }
                    }
                }

                Item{
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 24
                }

                Rectangle {
                    id: _privateSpendKeyItem

                    property string addressText: walletAdapter.privateSpendKey
                    property bool addressVisible: false

                    anchors.horizontalCenter: parent.horizontalCenter

                    width:  getQrBorderWidth()
                    height: 307

                    onAddressTextChanged: _privateSpendKeyQrImage.sourceText = _privateSpendKeyItem.addressText

                    color: Theme.barcodeBackgroundColor
                    border.color : Theme.barcodeBackgroundBorderColor

                    radius: 15

                    Column {
                        anchors.fill: parent

                        anchors.margins: 24

                        spacing: 24

                        Item {
                            anchors.left: parent.left
                            anchors.right: parent.right

                            height: 24

                            UNLabel {
                                id:_privateSpendKeyHeaderText
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter

                                height: implicitHeight

                                type: UNLabel.Type.TypeExtraBold
                                size: 15
                                font.letterSpacing: 1.15
                                elide: Label.ElideNone
                                wrapMode: Label.NoWrap
                                color: Theme.barcodeTitleColor
                                horizontalAlignment: Label.AlignLeft
                                verticalAlignment: Label.AlignVCenter

                                text: qsTr("Private Spend key")
                            }

                            UNIcon {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter

                                size:24
                                source: "qrc:/icons/resources/icons/clipboard_copy_icon.svg"
                                toolTip: qsTr("Copy to Clipboard")
                                color: Theme.barcodeIconColor
                                clickable: true

                                onClicked: {
                                    clipboard.setText(_privateSpendKeyItem.addressText)
                                }
                            }
                        }

                        Item {
                            anchors.horizontalCenter: parent.horizontalCenter

                            height: 215
                            width: height

                            QrImage {
                                id: _privateSpendKeyQrImage
                                anchors.fill: parent

                                dimension : 215
                                height: 215
                                width: height

                                visible: "" !== _privateSpendKeyQrImage.sourceText
                            }

                            Rectangle {
                                id: _privateSpendKeyQrImageHover

                                anchors.fill: parent
                                color: "white"
                                opacity: !_privateSpendKeyItem.addressVisible || (_privateSpendKeyItem.addressVisible && _privateSpendKeyItemMouseArea.containsMouse) ? 1.0 : 0.0

                                Behavior on opacity {
                                    OpacityAnimator {
                                        duration: 200
                                    }
                                }

                                Column {
                                    anchors.centerIn: parent

                                    spacing: 16

                                    UNLabel {
                                        anchors.horizontalCenter: parent.horizontalCenter

                                        height: implicitHeight

                                        type: UNLabel.Type.TypeExtraBold
                                        size: 15
                                        font.letterSpacing: 1.15
                                        elide: Label.ElideNone
                                        wrapMode: Label.NoWrap
                                        color: Theme.privateBarcodeOverlayTextColor
                                        horizontalAlignment: Label.AlignLeft
                                        verticalAlignment: Label.AlignVCenter

                                        text: _privateSpendKeyItem.addressVisible ? qsTr("Click to Hide") : qsTr("Click to Show")
                                    }

                                    UNIcon {
                                        anchors.horizontalCenter: parent.horizontalCenter

                                        size: 38

                                        source: _privateSpendKeyItem.addressVisible ? "qrc:/icons/resources/icons/qrcode_hidden_icon.svg" : "qrc:/icons/resources/icons/qrcode_visible_icon.svg"

                                        color: Theme.privateBarcodeOverlayIconColor
                                        clickable: false
                                    }
                                }
                            }

                            MouseArea {
                                id: _privateSpendKeyItemMouseArea

                                anchors.fill: parent

                                hoverEnabled: true

                                onClicked: {
                                    _privateSpendKeyItem.addressVisible = !_privateSpendKeyItem.addressVisible
                                }
                            }
                        }
                    }
                }

                Item{
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 24
                }

                Rectangle {
                    id: _privateViewKeyItem

                    property string addressText: walletAdapter.privateViewKey
                    property bool addressVisible: false

                    anchors.horizontalCenter: parent.horizontalCenter

                    width: getQrBorderWidth()
                    height: 307

                    onAddressTextChanged: _privateViewKeyQrImage.sourceText = _privateViewKeyItem.addressText

                    color: Theme.barcodeBackgroundColor
                    border.color : Theme.barcodeBackgroundBorderColor

                    radius: 15

                    Column {
                        anchors.fill: parent

                        anchors.margins: 24

                        spacing: 24

                        Item {
                            anchors.left: parent.left
                            anchors.right: parent.right

                            height: 24

                            UNLabel {
                                id:_privateViewKeyHeaderText
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter

                                height: implicitHeight

                                type: UNLabel.Type.TypeExtraBold
                                size: 15
                                font.letterSpacing: 1.15
                                elide: Label.ElideNone
                                wrapMode: Label.NoWrap
                                color: Theme.barcodeTitleColor
                                horizontalAlignment: Label.AlignLeft
                                verticalAlignment: Label.AlignVCenter

                                text: qsTr("Private View key")
                            }

                            UNIcon {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter

                                size:24
                                source: "qrc:/icons/resources/icons/clipboard_copy_icon.svg"
                                toolTip: qsTr("Copy to Clipboard")
                                color: Theme.barcodeIconColor
                                clickable: true

                                onClicked: {
                                    clipboard.setText(_privateViewKeyItem.addressText)
                                }
                            }
                        }

                        Item {
                            anchors.horizontalCenter: parent.horizontalCenter

                            height: 215
                            width: height

                            QrImage {
                                id: _privateViewKeyQrImage

                                anchors.fill: parent
                                dimension : 215
                                height: 215
                                width: height

                                visible: "" !== _privateViewKeyQrImage.sourceText
                            }

                            Rectangle {
                                id: _privateViewKeyQrImageHover

                                anchors.fill: parent
                                color: "white"
                                opacity: !_privateViewKeyItem.addressVisible || (_privateViewKeyItem.addressVisible && _privateViewKeyItemMouseArea.containsMouse) ? 1.0 : 0.0

                                Behavior on opacity {
                                    OpacityAnimator {
                                        duration: 200
                                    }
                                }

                                Column {
                                    anchors.centerIn: parent

                                    spacing: 16

                                    UNLabel {
                                        anchors.horizontalCenter: parent.horizontalCenter

                                        height: implicitHeight

                                        type: UNLabel.Type.TypeExtraBold
                                        size: 15
                                        font.letterSpacing: 1.15
                                        elide: Label.ElideNone
                                        wrapMode: Label.NoWrap
                                        color: Theme.privateBarcodeOverlayTextColor
                                        horizontalAlignment: Label.AlignLeft
                                        verticalAlignment: Label.AlignVCenter

                                        text: _privateViewKeyItem.addressVisible ? qsTr("Click to Hide") : qsTr("Click to Show")
                                    }

                                    UNIcon {
                                        anchors.horizontalCenter: parent.horizontalCenter

                                        size: 38

                                        source: _privateViewKeyItem.addressVisible ? "qrc:/icons/resources/icons/qrcode_hidden_icon.svg" : "qrc:/icons/resources/icons/qrcode_visible_icon.svg"

                                        color: Theme.privateBarcodeOverlayIconColor
                                        clickable: false
                                    }
                                }
                            }

                            MouseArea {
                                id: _privateViewKeyItemMouseArea

                                anchors.fill: parent

                                hoverEnabled: true

                                onClicked: {
                                    _privateViewKeyItem.addressVisible = !_privateViewKeyItem.addressVisible
                                }
                            }
                        }
                    }
                }

            }
        }
    }
}
