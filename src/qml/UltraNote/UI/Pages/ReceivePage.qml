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

    contentItem: Item {
        anchors.fill: parent

        transform: [
            Scale {
                id: scale;
                xScale: yScale;
                yScale: _page.height / _pageContent.childrenRect.height
            },
            Translate {
                x: (_page.width - _pageContent.childrenRect.width * scale.xScale) / 2;
                y: (_page.height - _pageContent.childrenRect.height * scale.yScale) / 2;
            }
        ]

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

                width: 352
                height: 416

                onAddressTextChanged: _publicAddressQrImage.sourceText = addressText

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
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter

                            height: implicitHeight

                            type: UNLabel.Type.TypeExtraBold
                            size: 18
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

                        height: 300
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
                id: _privateAddressItem

                property string addressText: walletAdapter.privateKey
                property bool addressVisible: false

                anchors.horizontalCenter: parent.horizontalCenter

                width: 352
                height: 416

                onAddressTextChanged: _privateAddressQrImage.sourceText = _privateAddressItem.addressText

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
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter

                            height: implicitHeight

                            type: UNLabel.Type.TypeExtraBold
                            size: 18
                            font.letterSpacing: 1.15
                            elide: Label.ElideNone
                            wrapMode: Label.NoWrap
                            color: Theme.barcodeTitleColor
                            horizontalAlignment: Label.AlignLeft
                            verticalAlignment: Label.AlignVCenter

                            text: qsTr("Private Address key")
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
                                clipboard.setText(_privateAddressItem.addressText)
                            }
                        }
                    }

                    Item {
                        anchors.horizontalCenter: parent.horizontalCenter

                        height: 300
                        width: height

                        QrImage {
                            id: _privateAddressQrImage

                            anchors.fill: parent

                            visible: "" !== _privateAddressQrImage.sourceText
                        }

                        Rectangle {
                            id: _privateAddressQrImageHover

                            anchors.fill: parent
                            color: "white"
                            opacity: !_privateAddressItem.addressVisible || (_privateAddressItem.addressVisible && _privateAddressItemMouseArea.containsMouse) ? 1.0 : 0.0

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
                                    size: 18
                                    font.letterSpacing: 1.15
                                    elide: Label.ElideNone
                                    wrapMode: Label.NoWrap
                                    color: Theme.privateBarcodeOverlayTextColor
                                    horizontalAlignment: Label.AlignLeft
                                    verticalAlignment: Label.AlignVCenter

                                    text: _privateAddressItem.addressVisible ? qsTr("Click to Hide") : qsTr("Click to Show")
                                }

                                UNIcon {
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    size: 48

                                    source: _privateAddressItem.addressVisible ? "qrc:/icons/resources/icons/qrcode_hidden_icon.svg" : "qrc:/icons/resources/icons/qrcode_visible_icon.svg"

                                    color: Theme.privateBarcodeOverlayIconColor
                                    clickable: false
                                }
                            }
                        }

                        MouseArea {
                            id: _privateAddressItemMouseArea

                            anchors.fill: parent

                            hoverEnabled: true

                            onClicked: {
                                _privateAddressItem.addressVisible = !_privateAddressItem.addressVisible
                            }
                        }
                    }
                }
            }

            Item{
                anchors.left: parent.left
                anchors.right: parent.right
                height: 96
            }
        }
    }
}

