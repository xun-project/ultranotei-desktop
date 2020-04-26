import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.13
import QtQuick.Layouts 1.13

import UltraNote.UI 1.0
import UltraNote.UI.Controls 1.0

UNPage {
    id: _page

    objectName: "send_page"

    title: qsTr("Send")

    readonly property real spinWidth: 250
    property string address: ""
    property bool addressBookIsOpen: false

    Connections {
        target: _addressBookDialog
        onVisibleChanged:{
            //_cryptoCommentTextField.text = "Pay for InvoiceID : "
            if(-1 !== walletAdapter.addressBookTableModel.selectedRow && addressBookIsOpen){
                address = walletAdapter.addressBookTableModel.selectedAddress
                walletAdapter.addressBookTableModel.selectedRow = -1
            }
            addressBookIsOpen = !addressBookIsOpen
        }
    }

    Component.onDestruction:{
        _globalProperties.payToAddress = false
    }

    Component.onCompleted: {
        if(_globalProperties.payToAddress){
            address = _globalProperties.sendToAddress
            _paymentIDTextField.text = walletAdapter.messagesTableModel.msgPaymentId
            _amountEditBox.text = walletAdapter.messagesTableModel.msgInvoiceAmount
            _cryptoCommentTextField.text = "Pay for InvoiceID : "+ walletAdapter.messagesTableModel.msgInvoiceId
        }
    }

    contentItem: Item {
        anchors.fill: parent

        Flickable {
            anchors.fill: parent
            anchors.margins: 16

            boundsBehavior: Flickable.StopAtBounds
            contentHeight: _pageContent.height

            Column {
                id: _pageContent

                property int labelTextWidth: Math.max(
                                                 _payToLabelText.implicitWidth,
                                                 _paymentIDLabelText.implicitWidth,
                                                 _labelLabelText.implicitWidth,
                                                 _cryptoCommentLabelText.implicitWidth,
                                                 _amountLabelText.implicitWidth,
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
                        id: _payToLabelText

                        Layout.fillHeight: true
                        Layout.preferredWidth: _pageContent.labelTextWidth
                        Layout.maximumWidth:  _pageContent.labelTextWidth
                        Layout.minimumWidth:  _pageContent.labelTextWidth

                        type: UNLabel.Type.TypePageSubcategoryTitle

                        color: Theme.textColor
                        text: qsTr("Pay to")
                    }

                    UNTextField {
                        id: _payToTextField

                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter

                        text: _page.address
                        onTextChanged: _page.address = text
                    }

                    UNIcon {
                        Layout.preferredWidth: implicitWidth
                        Layout.maximumWidth: implicitWidth
                        Layout.minimumWidth: implicitWidth
                        Layout.alignment: Qt.AlignVCenter

                        color: Theme.sendPageIconColor
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

                        color: Theme.sendPageIconColor
                        clickable: true
                        source: "qrc:/icons/resources/icons/clipboard_copy_icon.svg"
                        toolTip: qsTr("Paste from Clipboard")

                        onClicked: {
                            _payToTextField.text = clipboard.text()
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
                        Layout.preferredWidth: _pageContent.labelTextWidth
                        Layout.maximumWidth:  _pageContent.labelTextWidth
                        Layout.minimumWidth:  _pageContent.labelTextWidth

                        type: UNLabel.Type.TypePageSubcategoryTitle

                        color: Theme.textColor
                        text: qsTr("Payment ID")
                    }

                    UNTextField {
                        id: _paymentIDTextField

                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
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
                        Layout.preferredWidth: _pageContent.labelTextWidth
                        Layout.maximumWidth:  _pageContent.labelTextWidth
                        Layout.minimumWidth:  _pageContent.labelTextWidth

                        type: UNLabel.Type.TypePageSubcategoryTitle

                        color: Theme.textColor
                        text: qsTr("Label")
                    }

                    UNTextField {
                        id: _labelTextField

                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter

                        text: walletAdapter.addressBookTableModel.selectedLabel
                        placeholderText: qsTr("Enter a label for this address to add it to your address book")
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
                        id: _cryptoCommentLabelText

                        Layout.fillHeight: true
                        Layout.preferredWidth: _pageContent.labelTextWidth
                        Layout.maximumWidth:  _pageContent.labelTextWidth
                        Layout.minimumWidth:  _pageContent.labelTextWidth

                        type: UNLabel.Type.TypePageSubcategoryTitle

                        color: Theme.textColor
                        text: qsTr("Crypto comment")
                    }

                    UNTextField {
                        id: _cryptoCommentTextField

                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        onTextChanged: {
                            _feeEditBox.updateFee(text.length * walletAdapter.getCommentCharPrice() + currencyAdapter.getMinimumFee())
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
                        Layout.preferredWidth: _pageContent.labelTextWidth
                        Layout.maximumWidth:  _pageContent.labelTextWidth
                        Layout.minimumWidth:  _pageContent.labelTextWidth

                        type: UNLabel.Type.TypePageSubcategoryTitle

                        color: Theme.textColor
                        text: qsTr("Amount")
                    }

                    UNLayoutSpacer {}

                    UNAmountBox{
                        id:_amountEditBox
                    }

                    Text {
                        id: suffix
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
                        id: _feeLabelText

                        Layout.fillHeight: true
                        Layout.preferredWidth: _pageContent.labelTextWidth
                        Layout.maximumWidth:  _pageContent.labelTextWidth
                        Layout.minimumWidth:  _pageContent.labelTextWidth

                        type: UNLabel.Type.TypePageSubcategoryTitle

                        color: Theme.textColor
                        text: qsTr("Fee")
                    }

                    UNLayoutSpacer {}

                    UNAmountBox{
                        id:_feeEditBox
                        resetDecimals: "0.001000"
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
                        Layout.preferredWidth: _pageContent.labelTextWidth
                        Layout.maximumWidth:  _pageContent.labelTextWidth
                        Layout.minimumWidth:  _pageContent.labelTextWidth

                        type: UNLabel.Type.TypePageSubcategoryTitle

                        color: Theme.textColor
                        text: qsTr("Anonymity level")
                    }

                    UNLayoutSpacer {}

                    UNSlider {
                        id: _anonymitySlider

                        Layout.preferredWidth: _feeEditBox.width
                        Layout.maximumWidth: _feeEditBox.width
                        Layout.minimumWidth: _feeEditBox.width
                        Layout.alignment: Qt.AlignVCenter

                        readonly property int defaultAnonLevel: 2

                        from: 0
                        to: 10
                        stepSize: 1
                        value: _anonymitySlider.defaultAnonLevel
                        snapMode: Slider.SnapAlways
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
                        text: qsTr("Clear All")

                        onClicked: {
                            walletAdapter.addressBookTableModel.selectedRow = -1
                            //_payToTextField.text = ""
                            //_labelTextField.text = ""
                            _cryptoCommentTextField.text = ""
                            _amountEditBox.text = _amountEditBox.resetDecimals
                            _paymentIDTextField.text = ""
                            _anonymitySlider.value = _anonymitySlider.defaultAnonLevel
                            _feeEditBox.updateFee(currencyAdapter.getMinimumFee())

                        }
                    }
                    UNButton {
                        text: qsTr("Send")
                        onClicked: {
                            if (!currencyAdapter.validateAddress(_payToTextField.text)) {
                                _messageDialogProperties.showMessage(qsTr("Error"), qsTr("Invalid recipient address"))
                                return
                            }
                            if (0 === _amountEditBox.value) {
                                _messageDialogProperties.showMessage(qsTr("Error"), qsTr("Incorrect amount value"))
                                return
                            }
                            if (!currencyAdapter.validatePaymentId(_paymentIDTextField.text)) {
                                _messageDialogProperties.showMessage(qsTr("Error"), qsTr("Invalid payment ID"))
                                return
                            }
                            if (!walletAdapter.isOpen()) {
                                _messageDialogProperties.showMessage(qsTr("Error"), qsTr("Wallet is closed"))
                                return
                            }
                            walletAdapter.send(_payToTextField.text, _paymentIDTextField.text,
                                               _labelTextField.text, _cryptoCommentTextField.text,
                                               _amountEditBox.value, _feeEditBox.value,
                                               _anonymitySlider.value)
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
}
