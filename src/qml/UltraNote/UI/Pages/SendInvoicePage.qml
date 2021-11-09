import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.13
import QtQuick.Layouts 1.13

import QrImage 1.0
import UltraNote.UI 1.0
import UltraNote.UI.Controls 1.0

UNPage {
    id: _page

    objectName: "send_invoice_page"

    title: qsTr("Send Invoice")

    contentItem: Item {
        anchors.fill: parent

        Flickable {
            anchors.fill: parent
            anchors.margins: 20

            clip: true

            boundsBehavior: Flickable.StopAtBounds
            contentHeight: _pageContent.height

            Column {
                id: _pageContent

                property int labelTextWidthTop: Math.max(
                                                    _addressLabelText.implicitWidth,
                                                    _labelLabelText.implicitWidth,
                                                    _paymentIDLabelText.implicitWidth,
                                                    _amountLabelText.implicitWidth,
                                                    _invoiceIDLabelText.implicitWidth
                                                    )

                property int labelTextWidthBottom: Math.max(
                                                       _replyTo.implicitWidth,
                                                       _selfDestructTimeCheckbox.implicitWidth,
                                                       _feeLabelText.implicitWidth,
                                                       _anonymityLabelText.implicitWidth
                                                       )

                anchors.left: parent.left
                anchors.right: parent.right

                height: childrenRect.height

                spacing: 0

                RowLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right

                    height: 40

                    spacing: 16

                    UNLabel {
                        id: _addressLabelText

                        Layout.fillHeight: true
                        Layout.preferredWidth: _pageContent.labelTextWidthTop
                        Layout.maximumWidth:  _pageContent.labelTextWidthTop
                        Layout.minimumWidth:  _pageContent.labelTextWidthTop

                        type: UNLabel.Type.TypePageSubcategoryTitle

                        color: Theme.textColor
                        text: qsTr("Address")
                    }

                    UNTextField {
                        id: _addressTextField

                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter

                        text: walletAdapter.addressBookTableModel.selectedAddress

                        onTextChanged: {
                            walletAdapter.invoiceService.address = text
                            walletAdapter.invoiceService.recalculateFeeValue()
                        }
                    }

                    UNIcon {
                        id: _addressBookToolButton

                        Layout.preferredWidth: implicitWidth
                        Layout.maximumWidth: implicitWidth
                        Layout.minimumWidth: implicitWidth
                        Layout.alignment: Qt.AlignVCenter

                        color: Theme.sendInvoicePageIconColor
                        clickable: true
                        source: "qrc:/icons/resources/icons/address_book_icon.svg"
                        toolTip: qsTr("Address Book")

                        onClicked: {
                            _addressBookDialog.open()
                        }
                    }

                    UNIcon {
                        Layout.preferredWidth: implicitWidth
                        Layout.maximumWidth: implicitWidth
                        Layout.minimumWidth: implicitWidth
                        Layout.alignment: Qt.AlignVCenter

                        color: Theme.sendInvoicePageIconColor
                        clickable: true
                        source: "qrc:/icons/resources/icons/clipboard_copy_icon.svg"
                        toolTip: qsTr("Paste from Clipboard")

                        onClicked: {
                            walletAdapter.invoiceService.pasteClicked()
                        }
                    }
                }

                Item {
                    anchors.left: parent.left
                    anchors.right: parent.right

                    height: 16
                }

                RowLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right

                    height: 40

                    spacing: 16

                    UNLabel {
                        id: _labelLabelText

                        Layout.fillHeight: true
                        Layout.preferredWidth: _pageContent.labelTextWidthTop
                        Layout.maximumWidth:  _pageContent.labelTextWidthTop
                        Layout.minimumWidth:  _pageContent.labelTextWidthTop

                        type: UNLabel.Type.TypePageSubcategoryTitle

                        color: Theme.textColor
                        text: qsTr("Label")
                    }

                    UNTextField {
                        id: _labelTextField

                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter

                        text: walletAdapter.invoiceService.label

                        onTextChanged: {
                            walletAdapter.invoiceService.label = text
                            walletAdapter.invoiceService.recalculateFeeValue()
                        }
                    }
                }

                Item {
                    anchors.left: parent.left
                    anchors.right: parent.right

                    height: 16
                }

                RowLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right

                    height: 40

                    spacing: 16

                    UNLabel {
                        id: _paymentIDLabelText

                        Layout.fillHeight: true
                        Layout.preferredWidth: _pageContent.labelTextWidthTop
                        Layout.maximumWidth:  _pageContent.labelTextWidthTop
                        Layout.minimumWidth:  _pageContent.labelTextWidthTop

                        type: UNLabel.Type.TypePageSubcategoryTitle

                        color: Theme.textColor
                        text: qsTr("Payment ID")
                    }

                    UNTextField {
                        id: _paymentIDTextField

                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter

                        onTextChanged: {
                            walletAdapter.invoiceService.paymentID = text
                            walletAdapter.invoiceService.recalculateFeeValue()
                        }
                    }
                }

                Item {
                    anchors.left: parent.left
                    anchors.right: parent.right

                    height: 16
                }

                RowLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right

                    height: 40

                    spacing: 16

                    UNLabel {
                        id: _amountLabelText

                        Layout.fillHeight: true
                        Layout.preferredWidth: _pageContent.labelTextWidthTop
                        Layout.maximumWidth:  _pageContent.labelTextWidthTop
                        Layout.minimumWidth:  _pageContent.labelTextWidthTop

                        type: UNLabel.Type.TypePageSubcategoryTitle

                        color: Theme.textColor
                        text: qsTr("Amount")
                    }

                    UNLayoutSpacer {}

                    UNSpinBox {
                        id: _amountSpinBox

                        Layout.preferredWidth: implicitWidth
                        Layout.maximumWidth: implicitWidth
                        Layout.minimumWidth: implicitWidth
                        Layout.alignment: Qt.AlignVCenter

                        property real realValue: value / props.actStepSize

                        QtObject {
                            id: props

                            readonly property int decimals: currencyAdapter.getNumberOfDecimalPlaces()
                            readonly property int actStepSize: Math.pow(10, props.decimals)
                        }

                        value: walletAdapter.invoiceService.amount
                        from: 0
                        stepSize: 1
                        to: 2147483647
                        editable: true
                        validator: DoubleValidator {
                            bottom: Math.min(_amountSpinBox.from, _amountSpinBox.to)
                            top:  Math.max(_amountSpinBox.from, _amountSpinBox.to)
                        }

                        onValueChanged: {
                            walletAdapter.invoiceService.amount = value
                            walletAdapter.invoiceService.recalculateFeeValue()
                        }
                    }

                    UNLayoutSpacer {}

                    UNLayoutSpacer {
                        fixedWidth: 40
                    }
                }

                Item {
                    anchors.left: parent.left
                    anchors.right: parent.right

                    height: 16
                }

                RowLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right

                    height: 40

                    spacing: 16

                    UNLabel {
                        id: _invoiceIDLabelText

                        Layout.fillHeight: true
                        Layout.preferredWidth: _pageContent.labelTextWidthTop
                        Layout.maximumWidth:  _pageContent.labelTextWidthTop
                        Layout.minimumWidth:  _pageContent.labelTextWidthTop

                        type: UNLabel.Type.TypePageSubcategoryTitle

                        color: Theme.textColor
                        text: qsTr("Invoice ID")
                    }

                    UNTextField {
                        id: _invoiceIDTextField

                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter

                        text: walletAdapter.invoiceService.invoiceID
                        onTextChanged: {
                            walletAdapter.invoiceService.invoiceIdEdited(text)
                        }
                    }
                }

                Item {
                    anchors.left: parent.left
                    anchors.right: parent.right

                    height: 48
                }

                Rectangle {
                    id: _publicAddressItem

                    anchors.horizontalCenter: parent.horizontalCenter

                    width: 270
                    height: 330

                    visible: "" !== _publicAddressQrImage.sourceText

                    color: Theme.barcodeBackgroundColor
                    border.color: Theme.barcodeBackgroundBorderColor

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
                                size: 14
                                font.letterSpacing: 1.15
                                elide: Label.ElideNone
                                wrapMode: Label.NoWrap
                                color: Theme.barcodeTitleColor
                                horizontalAlignment: Label.AlignLeft
                                verticalAlignment: Label.AlignVCenter

                                text: qsTr("Payload")
                            }
                        }

                        QrImage {
                            id: _publicAddressQrImage

                            anchors.horizontalCenter: parent.horizontalCenter
                            dimension : 230
                            height: 230
                            width: height

                            sourceText: walletAdapter.invoiceService.qrPayload
                        }
                    }
                }

                Item {
                    anchors.left: parent.left
                    anchors.right: parent.right

                    height: 48
                }

                ColumnLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right

                    height: childrenRect.height

                    spacing: 16

                    UNLabel {
                        id: _encryptedMessageLabelText

                        Layout.fillWidth: true
                        Layout.preferredHeight: implicitHeight
                        Layout.maximumHeight:  implicitHeight
                        Layout.minimumHeight:  implicitHeight

                        type: UNLabel.Type.TypePageSubcategoryTitle

                        color: Theme.textColor
                        text: qsTr("Encrypted Message")
                    }

                    UNTextArea {
                        id: _encryptedMessageTextArea

                        Layout.fillWidth: true
                        Layout.preferredHeight: 150
                        Layout.maximumHeight: 150
                        Layout.minimumHeight: 150
                        Layout.alignment: Qt.AlignVCenter

                        textAppearance: TextEdit.PlainText
                        onTextChanged: {
                            walletAdapter.invoiceService.invoiceMessageText = text

                        }
                    }
                }

                Item {
                    anchors.left: parent.left
                    anchors.right: parent.right

                    height: 16
                }

                ColumnLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right

                    height: childrenRect.height

                    spacing: 16

                    UNLabel {
                        id: _attachmentsLabelText

                        Layout.fillWidth: true
                        Layout.preferredHeight: implicitHeight
                        Layout.maximumHeight:  implicitHeight
                        Layout.minimumHeight:  implicitHeight

                        type: UNLabel.Type.TypePageSubcategoryTitle

                        color: Theme.textColor
                        text: qsTr("Attachments")
                    }

                    Canvas {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 150
                        Layout.maximumHeight: 150
                        Layout.minimumHeight: 150
                        Layout.alignment: Qt.AlignVCenter

                        property double backgroundOpacity: 0.12
                        property int cornerRadius: 0

                        onPaint: {
                            var ctx = getContext("2d")

                            ctx.clearRect(0,0, width, height)
                            ctx.fillStyle = Theme.primaryLightColor
                            ctx.globalAlpha = backgroundOpacity
                            ctx.beginPath();
                            ctx.moveTo(0, height);
                            ctx.lineTo(0, cornerRadius)
                            ctx.quadraticCurveTo(0, 0, cornerRadius, 0)
                            ctx.lineTo(width - cornerRadius, 0)
                            ctx.quadraticCurveTo(width, 0, width, cornerRadius)
                            ctx.lineTo(width, height)
                            ctx.lineTo(0, height)
                            ctx.closePath()
                            ctx.fill();
                        }

                        DropArea {
                            anchors.fill: parent
                            property var dropUrls: []
                            onEntered: {
                                dropUrls = []
                                drag.urls.forEach(function(url){
                                    dropUrls.push([url])
                                })
                            }

                            onDropped: {
                                dropUrls.forEach(function(url){
                                    walletAdapter.invoiceService.addAttachmentClicked(url)
                                })
                            }
                        }

                        ListView {
                            id: _attachmentsList

                            anchors.fill: parent
                            anchors.margins: 20

                            model: walletAdapter.invoiceService.attachmentsModel

                            delegate: RowLayout {
                                anchors.left: parent.left
                                anchors.right: parent.right

                                height: 40

                                spacing: 16

                                UNTextField {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter

                                    text: display
                                }

                                UNIcon {
                                    Layout.preferredWidth: implicitWidth
                                    Layout.maximumWidth: implicitWidth
                                    Layout.minimumWidth: implicitWidth
                                    Layout.alignment: Qt.AlignVCenter

                                    color: Theme.primaryLightColor

                                    clickable: true
                                    source: "qrc:/icons/resources/icons/remove_item_icon.svg"
                                    toolTip: qsTr("Remove Attachment")

                                    onClicked: {
                                        walletAdapter.invoiceService.removeAttachment(index)
                                    }
                                }
                            }
                        }
                    }
                }

                Item {
                    anchors.left: parent.left
                    anchors.right: parent.right

                    height: 16
                }

                UNCheckBox{
                    id: _replyTo

                    Layout.preferredWidth: _pageContent.labelTextWidthBottom
                    Layout.maximumWidth:  _pageContent.labelTextWidthBottom
                    Layout.minimumWidth:  _pageContent.labelTextWidthBottom
                    Layout.preferredHeight: implicitHeight
                    Layout.maximumHeight:  implicitHeight
                    Layout.minimumHeight:  implicitHeight

                    enabled: walletAdapter.invoiceService.replyToEnabled
                    checked: walletAdapter.invoiceService.replyToChecked

                    text: qsTr("Add \"Reply to\"")

                    onCheckedChanged: {
                        walletAdapter.invoiceService.replyToChecked = checked
                        walletAdapter.invoiceService.recalculateFeeValue()
                    }
                }

                Item {
                    anchors.left: parent.left
                    anchors.right: parent.right

                    height: 16
                }

                RowLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right

                    height: 40

                    spacing: 16

                    UNCheckBox {
                        id: _selfDestructTimeCheckbox

                        Layout.preferredWidth: _pageContent.labelTextWidthBottom
                        Layout.maximumWidth:  _pageContent.labelTextWidthBottom
                        Layout.minimumWidth:  _pageContent.labelTextWidthBottom
                        Layout.alignment: Qt.AlignVCenter

                        checked: walletAdapter.invoiceService.ttlEnabled

                        text: qsTr("Set self destruct time")

                        onCheckedChanged: {
                            walletAdapter.invoiceService.ttlEnabled = checked
                            walletAdapter.invoiceService.recalculateFeeValue()
                        }
                    }

                    UNLayoutSpacer {}

                    UNSlider {
                        id: _selfDestructTimeSlider
                        Layout.alignment: Qt.AlignVCenter

                        visible: _selfDestructTimeCheckbox.checked

                        from: walletAdapter.invoiceService.ttlMinimalValue
                        to: walletAdapter.invoiceService.ttlMaximumValue
                        stepSize: 1
                        value: walletAdapter.invoiceService.ttlValue
                        snapMode: Slider.SnapAlways

                        onValueChanged: {
                            walletAdapter.invoiceService.ttlValue = value
                            walletAdapter.invoiceService.ttlValueChanged(value)
                        }
                    }

                    UNLayoutSpacer {}

                    UNLabel {
                        Layout.preferredWidth: 40
                        Layout.maximumWidth: 40
                        Layout.minimumWidth: 40
                        Layout.alignment: Qt.AlignVCenter

                        visible: _selfDestructTimeCheckbox.checked

                        type: UNLabel.Type.TypeMedium
                        color: Theme.textColor
                        horizontalAlignment: Label.AlignRight
                        text: walletAdapter.invoiceService.ttlDecoratedValue
                    }
                }

                Item {
                    anchors.left: parent.left
                    anchors.right: parent.right

                    height: 16
                }

                RowLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right

                    height: 40

                    spacing: 16

                    UNLabel {
                        id: _feeLabelText

                        Layout.fillHeight: true
                        Layout.preferredWidth: _pageContent.labelTextWidthBottom
                        Layout.maximumWidth:  _pageContent.labelTextWidthBottom
                        Layout.minimumWidth:  _pageContent.labelTextWidthBottom

                        type: UNLabel.Type.TypePageSubcategoryTitle

                        color: Theme.textColor
                        text: qsTr("Fee")
                    }

                    UNLayoutSpacer {}

                    UNAmountBox{
                        id:_feeEditBox
                        //resetDecimals: "0.101000"
                        resetDecimals: "0.001000"
                        minLimitString: "0.001000"
                        minLimitNumber: currencyAdapter.getMinimumFee()
                        value : currencyAdapter.getMinimumFee()
                    }

                    Text {
                        id: _suffix
                        verticalAlignment: Text.AlignVCenter
                        text: _globalProperties.currency
                        color: Theme.spinBoxTextColor
                        font.pixelSize: Theme.spinBoxFontSize
                        font.family: UNFontsFactory.workSansMedium.name
                        anchors {rightMargin: 50}
                    }

                    UNLayoutSpacer {}

                    UNLayoutSpacer {
                        fixedWidth: 40
                    }
                }

                Item {
                    anchors.left: parent.left
                    anchors.right: parent.right

                    height: 16
                }

                RowLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right

                    height: 40

                    spacing: 16

                    UNLabel {
                        id: _anonymityLabelText

                        Layout.fillHeight: true
                        Layout.preferredWidth: _pageContent.labelTextWidthBottom
                        Layout.maximumWidth:  _pageContent.labelTextWidthBottom
                        Layout.minimumWidth:  _pageContent.labelTextWidthBottom

                        type: UNLabel.Type.TypePageSubcategoryTitle

                        color: Theme.textColor
                        text: qsTr("Anonymity level")
                    }

                    UNLayoutSpacer {}

                    UNSlider {
                        id: _anonymitySlider
                        Layout.alignment: Qt.AlignVCenter

                        from: 0
                        to: 10
                        stepSize: 1
                        value: walletAdapter.invoiceService.mixinValue
                        snapMode: Slider.SnapAlways
                        onValueChanged: {
                            walletAdapter.invoiceService.mixinValue = value
                            walletAdapter.invoiceService.recalculateFeeValue()
                        }
                    }

                    UNLayoutSpacer {}

                    UNTextField {
                        Layout.preferredWidth: 40
                        Layout.maximumWidth: 40
                        Layout.minimumWidth: 40
                        Layout.alignment: Qt.AlignVCenter

                        text: _anonymitySlider.value
                        validator: IntValidator { bottom: _anonymitySlider.from; top: _anonymitySlider.to }
                        horizontalAlignment: Text.AlignHCenter
                        onTextChanged: _anonymitySlider.value = parseInt(text, 10)
                    }
                }

                Item {
                    anchors.left: parent.left
                    anchors.right: parent.right

                    height: 32
                }

                RowLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right

                    height: 40

                    spacing: 16

                    UNLayoutSpacer {}

                    UNButton {
                        text: qsTr("Add attachment")
                        onClicked: {
                            _walletDialog.selectFolder = false
                            _walletDialog.selectExisting = true
                            _walletDialog.title = qsTr("Select attachment...")
                            _walletDialog.defaultSuffix = ""
                            _walletDialog.nameFilters = ["All Files (*.*)"]
                            _walletDialog.acceptedCallback = walletAdapter.invoiceService.addAttachmentClicked
                            _walletDialog.open()
                        }
                    }
                    UNButton {
                        text: qsTr("Send")
                        onClicked: {
                            walletAdapter.invoiceService.sendClicked()
                        }
                    }
                }

                Item {
                    anchors.left: parent.left
                    anchors.right: parent.right

                    height: 32
                }
            }
        }
    }
	Connections {
        target: walletAdapter.invoiceService
		onFeeValueChanged:{
			_feeEditBox.updateFee(walletAdapter.invoiceService.feeValue)
		}
    }
}
