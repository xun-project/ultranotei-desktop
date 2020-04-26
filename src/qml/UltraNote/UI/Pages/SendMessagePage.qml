import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Controls 1.4  as QQC1
import QtQuick.Controls.Material 2.13
import QtQuick.Layouts 1.13
import QtQuick.Controls.Styles 1.4

import Qt.labs.platform 1.0
import DocumentHandler 1.0

import UltraNote.UI 1.0
import UltraNote.UI.Controls 1.0
import UltraNote.UI.Dialogs 1.0

UNPage {
    id: _page

    objectName: "send_message_page"

    title: qsTr("Send Message")

    readonly property real spinWidth: 250
    readonly property real listItemHeight: 40
    property string address: ""
    property bool addressBookIsOpen: false

    Connections {
        target: _addressBookDialog
        onVisibleChanged:{
            if(-1 !== walletAdapter.addressBookTableModel.selectedRow && addressBookIsOpen){
                address = walletAdapter.addressBookTableModel.selectedAddress
                _recepientsListView.model.setAddress(0, address)
                walletAdapter.addressBookTableModel.selectedRow = -1
            }
            addressBookIsOpen = !addressBookIsOpen
        }
    }

    Component.onDestruction:{
        _globalProperties.addressIsExposed = false
    }

    Component.onCompleted: {
        if(_globalProperties.addressIsExposed){
            address = _globalProperties.sendToAddress
            _recepientsListView.model.setAddress(0, address)
        }
    }

    FileDialog {
        id: openDialog
        fileMode: FileDialog.OpenFile
        selectedNameFilter.index: 1
        nameFilters: ["Text files (*.txt)", "HTML files (*.html *.htm)"]
        folder: StandardPaths.writableLocation(StandardPaths.DocumentsLocation)
        onAccepted: document.load(file)
    }

    FileDialog {
        id: saveDialog
        fileMode: FileDialog.SaveFile
        defaultSuffix: document.fileType
        nameFilters: openDialog.nameFilters
        selectedNameFilter.index: document.fileType === "txt" ? 0 : 1
        folder: StandardPaths.writableLocation(StandardPaths.DocumentsLocation)
        onAccepted: document.saveAs(file)
    }

    FontDialog {
        id: fontDialog
        onAccepted: {
            document.fontFamily = font.family;
            document.fontSize = font.pointSize;
        }
    }

    ColorDialog {
        id: colorDialog
        currentColor: "black"
    }

    MessageDialog {
        id: errorDialog
    }

    contentItem: Item {
        anchors.fill: parent



        Flickable {
            anchors.fill: parent
            anchors.margins: 20

            boundsBehavior: Flickable.StopAtBounds
            contentHeight: _pageContent.height

            Column {
                id: _pageContent

                anchors.left: parent.left
                anchors.right: parent.right

                height: childrenRect.height

                spacing: 0

                property int labelTextWidth: Math.max(
                                                 _replyTo.implicitWidth,
                                                 _selfDestructTimeCheckbox.implicitWidth,
                                                 _feeLabelText.implicitWidth,
                                                 _anonymityLabelText.implicitWidth
                                                 )

                ColumnLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right

                    height: childrenRect.height

                    spacing: 16

                    UNLabel {
                        id: _recepientsLabel

                        Layout.fillWidth: true
                        Layout.preferredHeight: implicitHeight
                        Layout.maximumHeight:  implicitHeight
                        Layout.minimumHeight:  implicitHeight

                        type: UNLabel.Type.TypePageSubcategoryTitle

                        color: Theme.textColor
                        text: qsTr("Send To")
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 150
                        Layout.maximumHeight: 150
                        Layout.minimumHeight: 150
                        Layout.alignment: Qt.AlignVCenter

                        ListView {
                            id: _recepientsListView

                            anchors.fill: parent

                            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                            model: walletAdapter.sendMessageModel.recipientsModel

                            clip: true
                            spacing: 16

                            delegate:  RowLayout {
                                id: _recepientListViewDelegate

                                anchors.left: parent.left
                                anchors.right: parent.right

                                height: 40

                                spacing: 16

                                UNTextField {
                                    id: sendToTextField
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    text: _page.address
                                    onTextChanged: _page.address = text
                                    onEditingFinished: _recepientsListView.model.setAddress(index, sendToTextField.text)
                                }

                                UNIcon {
                                    Layout.preferredWidth: implicitWidth
                                    Layout.maximumWidth: implicitWidth
                                    Layout.minimumWidth: implicitWidth
                                    Layout.alignment: Qt.AlignVCenter

                                    color: Theme.sendMessagePageIconColor

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

                                    color: Theme.sendMessagePageIconColor
                                    clickable: true
                                    source: "qrc:/icons/resources/icons/clipboard_copy_icon.svg"
                                    toolTip: qsTr("Paste from Clipboard")

                                    onClicked: {
                                        _recepientsListView.model.setAddress(index, clipboard.text())
                                    }
                                }

                                UNIcon {
                                    Layout.preferredWidth: implicitWidth
                                    Layout.maximumWidth: implicitWidth
                                    Layout.minimumWidth: implicitWidth
                                    Layout.alignment: Qt.AlignVCenter

                                    color: Theme.sendMessagePageIconColor
                                    visible: _recepientsListView.model.rows > 1

                                    clickable: true
                                    source: "qrc:/icons/resources/icons/remove_item_icon.svg"
                                    toolTip: qsTr("Remove Recipient")

                                    onClicked: {
                                        _recepientsListView.model.removeUser(index)
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
                        onTextChanged: {
                            walletAdapter.sendMessageModel.message = text
                            walletAdapter.sendMessageModel.recalculateFeeValue()
                        }
                    }
                    QQC1.ToolBar {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 50
                        style: ToolBarStyle {
                            background: Rectangle {
                                color: Theme.textFieldPlaceholderTextColor
                            }
                        }
                        Row {
                            id: flow
                            width: parent.width
                            height: parent.height
                            Row {
                                id: fileRow
                                ToolButton {
                                    id: openButton

                                    text: "<font color=\"#2A2931\">\uF115</font>" // icon-folder-open-empty
                                    font.family: "fontello"
                                    onClicked: openDialog.open()
                                }
                                ToolSeparator {
                                    contentItem.visible: fileRow.y === editRow.y
                                }
                            }
                            Row {
                                id: editRow
                                ToolButton {
                                    id: copyButton
                                    text: "<font color=\"#2A2931\">\uF0C5</font>" // icon-docs
                                    font.family: "fontello"
                                    focusPolicy: Qt.TabFocus
                                    enabled: _encryptedMessageTextArea._textArea.selectedText
                                    onClicked:_encryptedMessageTextArea._textArea.copy()
                                }
                                ToolButton {
                                    id: cutButton
                                    text: "<font color=\"#2A2931\">\uE802</font>" // icon-scissors
                                    font.family: "fontello"
                                    focusPolicy: Qt.TabFocus
                                    enabled: _encryptedMessageTextArea._textArea.selectedText
                                    onClicked: _encryptedMessageTextArea._textArea.cut()
                                }
                                ToolButton {
                                    id: pasteButton
                                    text: "<font color=\"#2A2931\">\uF0EA</font>" // icon-paste
                                    font.family: "fontello"
                                    focusPolicy: Qt.TabFocus
                                    enabled: _encryptedMessageTextArea._textArea.canPaste
                                    onClicked: _encryptedMessageTextArea._textArea.paste()
                                }
                                ToolSeparator {
                                    contentItem.visible: editRow.y === formatRow.y
                                }
                            }
                            Row {
                                id: formatRow
                                ToolButton {
                                    id: boldButton
                                    text: "<font color=\"#2A2931\">\uE800</font>" // icon-bold
                                    font.family: "fontello"
                                    focusPolicy: Qt.TabFocus
                                    checkable: true
                                    checked: document.bold
                                    onClicked: document.bold = !document.bold
                                }
                                ToolButton {
                                    id: italicButton
                                    text: "<font color=\"#2A2931\">\uE801</font>" // icon-italic
                                    font.family: "fontello"
                                    focusPolicy: Qt.TabFocus
                                    checkable: true
                                    checked: document.italic
                                    onClicked: document.italic = !document.italic
                                }
                                ToolButton {
                                    id: underlineButton
                                    text: "<font color=\"#2A2931\">\uF0CD</font>" // icon-underline
                                    font.family: "fontello"
                                    focusPolicy: Qt.TabFocus
                                    checkable: true
                                    checked: document.underline
                                    onClicked: document.underline = !document.underline
                                }
                                ToolButton {
                                    id: fontFamilyToolButton
                                    text: qsTr("<font color=\"#2A2931\">\uE808</font>") // icon-font
                                    font.family: "fontello"
                                    font.bold: document.bold
                                    font.italic: document.italic
                                    font.underline: document.underline
                                    onClicked: {
                                        fontDialog.currentFont.family = document.fontFamily;
                                        fontDialog.currentFont.pointSize = document.fontSize;
                                        fontDialog.open();
                                    }
                                }
                                ToolButton {
                                    id: textColorButton
                                    text: "<font color=\"#2A2931\">\uF1FC</font>" // icon-brush
                                    font.family: "fontello"
                                    focusPolicy: Qt.TabFocus
                                    onClicked: colorDialog.open()

                                    Rectangle {
                                        width: 20
                                        height: 2
                                        color: document.textColor
                                        parent: textColorButton.contentItem
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        anchors.baseline: parent.baseline
                                        anchors.baselineOffset: 6

                                        TextMetrics {
                                            id: aFontMetrics
                                            font: textColorButton.font
                                            text: textColorButton.text
                                        }
                                    }
                                }
                                ToolSeparator {
                                    contentItem.visible: formatRow.y === alignRow.y
                                }
                            }
                            Row {
                                id: alignRow
                                ToolButton {
                                    id: alignLeftButton
                                    text: document.alignment === Qt.AlignLeft ?"<font color=\"#2c9af4\">\uE803</font>" :"<font color=\"#2A2931\">\uE803</font>" // icon-align-left
                                    font.family: "fontello"
                                    focusPolicy: Qt.TabFocus
                                    checkable: true
                                    onClicked: document.alignment = Qt.AlignLeft
                                }
                                ToolButton {
                                    id: alignCenterButton
                                    text: document.alignment === Qt.AlignHCenter ? "<font color=\"#2c9af4\">\uE804</font>" :"<font color=\"#2A2931\">\uE804</font>" // icon-align-center
                                    font.family: "fontello"
                                    focusPolicy: Qt.TabFocus
                                    checkable: true
                                    onClicked: document.alignment = Qt.AlignHCenter
                                }
                                ToolButton {
                                    id: alignRightButton
                                    text: document.alignment === Qt.AlignRight ?"<font color=\"#2c9af4\">\uE805</font>" : "<font color=\"#2A2931\">\uE805</font>" // icon-align-right
                                    font.family: "fontello"
                                    focusPolicy: Qt.TabFocus
                                    checkable: true
                                    onClicked: document.alignment = Qt.AlignRight
                                }
                                ToolButton {
                                    id: alignJustifyButton
                                    text: document.alignment === Qt.AlignJustify? "<font color=\"#2c9af4\">\uE806</font>" : "<font color=\"#2A2931\">\uE806</font>" // icon-align-justify
                                    font.family: "fontello"
                                    focusPolicy: Qt.TabFocus
                                    checkable: true
                                    onClicked : document.alignment = Qt.AlignJustify
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

                        ListView {
                            id: _attachmentsList

                            anchors.fill: parent
                            anchors.margins: 20

                            model: walletAdapter.sendMessageModel.attachmentsModel

                            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                            spacing: 16
                            clip: true

                            delegate: RowLayout {
                                anchors.left: parent.left
                                anchors.right: parent.right

                                height: 40

                                spacing: 16

                                UNTextField {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter

                                    text: fileName
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
                                        walletAdapter.sendMessageModel.attachmentsModel.removeFile(index)
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

                    Layout.preferredWidth: _pageContent.labelTextWidth
                    Layout.maximumWidth:  _pageContent.labelTextWidth
                    Layout.minimumWidth:  _pageContent.labelTextWidth
                    Layout.preferredHeight: implicitHeight
                    Layout.maximumHeight:  implicitHeight
                    Layout.minimumHeight:  implicitHeight

                    text: qsTr("Add \"Reply to\"")

                    checked: walletAdapter.sendMessageModel.addReplyTo
                    onCheckedChanged: {
                        walletAdapter.sendMessageModel.addReplyTo = checked
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

                        Layout.preferredWidth: _pageContent.labelTextWidth
                        Layout.maximumWidth:  _pageContent.labelTextWidth
                        Layout.minimumWidth:  _pageContent.labelTextWidth
                        Layout.alignment: Qt.AlignVCenter

                        text: qsTr("Set self destruct time")

                        checked: walletAdapter.sendMessageModel.isSelfDestruct
                        onCheckedChanged: walletAdapter.sendMessageModel.isSelfDestruct = checked
                    }

                    UNLayoutSpacer {}

                    UNSlider {
                        id: _selfDestructTimeSlider

                        Layout.preferredWidth: _feeSpinBox.width
                        Layout.maximumWidth: _feeSpinBox.width
                        Layout.minimumWidth: _feeSpinBox.width
                        Layout.alignment: Qt.AlignVCenter

                        visible: _selfDestructTimeCheckbox.checked

                        value: walletAdapter.sendMessageModel.selfDestructTimeMin
                        from: walletAdapter.sendMessageModel.selfDestructTimeMinFrom
                        to: walletAdapter.sendMessageModel.selfDestructTimeMinTo
                        stepSize: 5
                        onValueChanged: walletAdapter.sendMessageModel.selfDestructTimeMin = value
                        snapMode: Slider.SnapAlways
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
                        text: _selfDestructTimeSlider.value
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

                    UNSpinBox {
                        id: _feeSpinBox

                        Layout.preferredWidth: implicitWidth
                        Layout.maximumWidth: implicitWidth
                        Layout.minimumWidth: implicitWidth
                        Layout.alignment: Qt.AlignVCenter

                        value: walletAdapter.sendMessageModel.messageFee
                        from: walletAdapter.sendMessageModel.minMessageFee
                        stepSize: Math.pow(10, 4)
                        to: 2147483647
                        editable: true
                        validator: DoubleValidator {
                            bottom: Math.min(_feeSpinBox.from, _feeSpinBox.to)
                            top:  Math.max(_feeSpinBox.from, _feeSpinBox.to)
                        }
                        textFromValue: function(value, locale) {
                            return _globalProperties.convertToAmount(value, locale) + " " + _globalProperties.currency
                        }
                        valueFromText: function(text, locale) {
                            var textVal = text.split(" ")[0]
                            return Number.fromLocaleString(locale, textVal) * _globalProperties.actStepSize
                        }
                        onValueChanged: walletAdapter.sendMessageModel.messageFee = value
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

                        Layout.preferredWidth: _feeSpinBox.width
                        Layout.maximumWidth: _feeSpinBox.width
                        Layout.minimumWidth: _feeSpinBox.width
                        Layout.alignment: Qt.AlignVCenter

                        readonly property int defaultAnonLevel: 2

                        from: 0
                        to: 10
                        stepSize: 1
                        value: walletAdapter.sendMessageModel.anonimityLevel
                        onValueChanged: walletAdapter.sendMessageModel.anonimityLevel = value
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
                        horizontalAlignment: Text.AlignRight
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
                        text: qsTr("Add Recipient")
                        onClicked: {
                            _recepientsListView.model.addUser()
                        }
                    }

                    UNButton {
                        text: qsTr("Add Attachment")
                        onClicked: {
                            _walletDialog.selectFolder = false
                            _walletDialog.selectExisting = true
                            _walletDialog.title = qsTr("Select attachment...")
                            _walletDialog.defaultSuffix = ""
                            _walletDialog.nameFilters = ["All Files (*.*)"]
                            _walletDialog.acceptedCallback = walletAdapter.sendMessageModel.attachmentsModel.appendFile
                            _walletDialog.open()
                        }
                    }

                    UNButton {
                        enabled: 0 !== _recepientsListView.model.rows

                        text: qsTr("Send")
                        onClicked: {
                            walletAdapter.sendMessageModel.send()
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
        DocumentHandler {
            id: document
            document: _encryptedMessageTextArea._textArea.textDocument
            cursorPosition: _encryptedMessageTextArea._textArea.cursorPosition
            selectionStart: _encryptedMessageTextArea._textArea.selectionStart
            selectionEnd: _encryptedMessageTextArea._textArea.selectionEnd
            textColor: colorDialog.color
            //Component.onCompleted: document.load("qrc:/texteditor.html")
            onLoaded: {
                _encryptedMessageTextArea._textArea.text = text
            }
            onError: {
                errorDialog.text = message
                errorDialog.visible = true
            }
        }
    }

    UploadProgressDialog {
        id: _progressDialog

        visible: false

        onRejected: {
            //cancel download
            walletAdapter.messagesTableModel.abortDownload()
        }
    }

    Connections {
        target: walletAdapter.messagesTableModel
        onDownloadProgressChanged: {
            _progressDialog.visible = true
            _progressDialog.value = value
        }
        onAbortDownload: {
            _progressDialog.value = 1
            _progressDialog.visible = false
        }
        onShowDownloadProgress: {
            _progressDialog.value = 0
            _progressDialog.visible = true
        }
    }

}
