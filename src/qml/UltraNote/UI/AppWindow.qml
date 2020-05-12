import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.13

import QtQuick.Window 2.13
import QtQuick.Dialogs 1.2 as Old

import UltraNote.UI 1.0
import UltraNote.UI.Controls 1.0
import UltraNote.UI.Pages 1.0
import UltraNote.UI.Dialogs 1.0

UNFramelessApplicationWindow {
    id: _appWindow

    width: 1052   //1024
    height: 840

    visible: true

    title: currencyAdapter.getCurrencyDisplayName() + qsTr(" Infinity ") + settings.getVersion()

    backgroundColor: Theme.pageBackgroundColor
    statusBarColor: Theme.statusBarColor

    QtObject {
        id: _globalProperties
        property var actualBalance: 0
        property string sendToAddress: ""
        property bool addressIsExposed: false
        property bool payToAddress: false

        readonly property color startColor: "#2258d8"
        readonly property color stopColor: Qt.darker(_globalProperties.startColor)
        readonly property string currency: currencyAdapter.getCurrencyTicker()
        readonly property int decimals: currencyAdapter.getNumberOfDecimalPlaces()
        readonly property int actStepSize: Math.pow(10, _globalProperties.decimals)


        function convertToAmount(value, locale) {
            return Number(value / _globalProperties.actStepSize).toLocaleString(locale, 'f', _globalProperties.decimals)
        }
        function setupSendMsg(addr) {
            _globalProperties.sendToAddress = addr
            _globalProperties.addressIsExposed = true
            _menuActionsList.currentIndex = 6
            _appPagesStackView.pop(null, StackView.PopTransition)
            _appPagesStackView.push(_sendMessagePageComponent)
        }
        function setupPayMsg(addr) {
            _globalProperties.sendToAddress = addr
            _globalProperties.payToAddress = true
            _menuActionsList.currentIndex = 1
            _appPagesStackView.pop(null, StackView.PopTransition)
            _appPagesStackView.push(_sendPageComponent)
        }
    }

    Connections {
        target: walletAdapter

        onRequestTransactionScreen: {
            _menuActionsList.currentIndex = 4
            _appPagesStackView.pop(null, StackView.PopTransition)
            _appPagesStackView.push(_transactionsPageComponent)
        }

        onWalletActualBalanceUpdatedSignal: {
            _globalProperties.actualBalance = _actualBalance
            walletBalance.values = [_actualBalance, walletBalance.values[1], _actualBalance + walletBalance.values[1]]
        }
        onWalletPendingBalanceUpdatedSignal: {
            walletBalance.values = [walletBalance.values[0], _pendingBalance, walletBalance.values[0] + _pendingBalance]
        }
        onWalletActualDepositBalanceUpdatedSignal: {
            depositsBalance.values = [depositsBalance.values[0], _actualDepositBalance, _actualDepositBalance + depositsBalance.values[0]]
        }
        onWalletPendingDepositBalanceUpdatedSignal: {
            depositsBalance.values = [_pendingDepositBalance, depositsBalance.values[1], depositsBalance.values[1] + _pendingDepositBalance]
        }
        onShowMessage: _messageDialogProperties.showMessage(title, text)
        onOpenWalletWithPasswordSignal: {
            _requestPasswordDialog.clear()
            _requestPasswordDialog.error = _error
            _requestPasswordDialog.open()
        }
    }
    Connections {
        target: walletAdapter.messagesTableModel
        onShowErrorDialog: {
            _messageDialogProperties.acceptCallback = null
            _messageDialogProperties.showMessage(title, msg)
        }
    }

    //TODO splash screen

    //        Splash {
    //            id: splash
    //            x: win.x + (win.width - width) / 2
    //            y: win.y + (win.height - height) / 2
    //            visible: true
    //        }
    //        Component.onCompleted: win.visible = true

    Old.FileDialog {
        id: _walletDialog
        property var acceptedCallback: null
        selectExisting: true
        visible: false
        folder: shortcuts.home
        selectFolder: false
        onAccepted: {
            if (null !== _walletDialog.acceptedCallback) {
                _walletDialog.acceptedCallback(_walletDialog.fileUrl)
                _walletDialog.acceptedCallback = null
            }
        }
    }

    contentStack: Item {
        id: _contentItem

        anchors.fill: parent

        clip: true

        RowLayout {
            id: _appWindowLayout

            anchors.fill: parent

            spacing: 0

            UNFluidDrawer {
                id: _drawer

                Layout.fillHeight: true
                Layout.preferredWidth: implicitWidth
                Layout.maximumWidth: implicitWidth
                Layout.minimumWidth: implicitWidth

                elevation: 16
                radius: 0

                z: _appPagesStackView.z + 1

                backgroundColor: Theme.drawerBackgroundColor

                UNBalanceReportDialog {
                    id: _balanceReport

                    x: parent.width + 24
                    y: _balanceButton.y + (_balanceButton.height / 2) - ((_balanceReport.pointerSize / 2) + _balanceReport.pointerOffset)

                    ColumnLayout {

                        anchors.left: parent.left
                        anchors.right: parent.right

                        spacing: 16

                        UNBalanceReport {
                            id: walletBalance

                            Layout.fillWidth: true
                            Layout.preferredHeight: implicitHeight
                            Layout.maximumHeight: implicitHeight
                            Layout.minimumHeight: implicitHeight

                            title: qsTr("Wallet")
                            names: [qsTr("Balance"), qsTr("Unconfirmed"), qsTr("Total")]
                            values: ["0.00", "0.00", "0.00"]
                        }

                        UNBalanceReport {
                            id: depositsBalance

                            Layout.fillWidth: true
                            Layout.preferredHeight: implicitHeight
                            Layout.maximumHeight: implicitHeight
                            Layout.minimumHeight: implicitHeight

                            title: qsTr("Deposits")
                            names: [qsTr("Locked"), qsTr("Unlocked"), qsTr("Total")]
                            values: ["0.00", "0.00", "0.00"]
                        }
                    }
                }


                contentItem: ColumnLayout{
                    anchors.fill: parent

                    spacing: 0

                    Flickable {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        contentHeight: _content.height

                        interactive: true
                        boundsBehavior: Flickable.StopAtBounds

                        Column {
                            id: _content

                            anchors.left: parent.left
                            anchors.right: parent.right

                            height: childrenRect.height

                            spacing: 0

                            Item {
                                id: _logoItem

                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.leftMargin: 0
                                anchors.rightMargin: 24

                                height: 56

                                Row {
                                    anchors.fill: parent

                                    spacing: 8

                                    Image {
                                        id: _stateControlIcon

                                        anchors.verticalCenter: parent.verticalCenter

                                        height: 24
                                        width: 24

                                        MouseArea {
                                            anchors.fill: parent
                                            anchors.margins: -8
                                            onClicked: {
                                                _drawer.state = _drawer.state === "collapsed" ? "expanded" : "collapsed"
                                            }
                                        }

                                        source: _drawer.state === "collapsed"
                                                ? "qrc:/icons/resources/icons/drawer_expand_icon.svg"
                                                : "qrc:/icons/resources/icons/drawer_collapse_icon.svg"
                                    }

                                    Image {
                                        id: _logoIcon

                                        anchors.verticalCenter: parent.verticalCenter

                                        height: 24
                                        width: 24

                                        source: "qrc:/images/resources/images/logo_white.png"

                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: {
                                                Qt.openUrlExternally("https://www.ultranote.org/")
                                            }
                                        }

                                    }

                                    Item {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 8
                                        height: 24
                                    }

                                    Image {
                                        id: _textLogoIcon

                                        anchors.verticalCenter: parent.verticalCenter

                                        height: 24
                                        fillMode: Image.PreserveAspectFit

                                        source: "qrc:/images/resources/images/logo_text_white.png"

                                        opacity: _logoItem.width > _logoIcon.width + _textLogoIcon.implicitWidth + 48 ? 1.0 : 0.0

                                        Behavior on opacity {
                                            OpacityAnimator{
                                                duration: 125
                                            }
                                        }
                                    }
                                }
                            }

                            Item {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                height: 32
                            }

                            UNDrawerMainActionButton {
                                id: _balanceButton

                                anchors.left: parent.left
                                anchors.leftMargin: 16

                                height: 56

                                width: Math.min(implicitWidth, 100)

                                text: qsTr("balance")
                                textColor: Theme.drawerMainActionButtonTextColor
                                iconSource: "qrc:/icons/resources/icons/drawer_main_action_icon.svg"
                                backgroundColor: Theme.drawerMainActionButtonColor
                                state: _drawer.state

                                onClicked: {
                                    _balanceReport.open()
                                }
                            }

                            Item {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                height: 28
                            }

                            Item {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                height: childrenRect.height

                                ListView {
                                    id: _menuActionsList

                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top


                                    interactive: false
                                    height: contentHeight

                                    currentIndex: 0

                                    model: ListModel {
                                        Component.onCompleted: {
                                            append({"text": qsTr("Deposits"), "iconSource": "qrc:/icons/resources/icons/drawer_deposits_list_item_icon.svg", "page": _depositsPageComponent, "pageObjectName": "deposits_page" })
                                            append({"text": qsTr("Send"), "iconSource": "qrc:/icons/resources/icons/drawer_send_list_item_icon.svg", "page": _sendPageComponent, "pageObjectName": "send_page" })
                                            append({"text": qsTr("Receive"), "iconSource": "qrc:/icons/resources/icons/drawer_receive_list_item_icon.svg", "page": _receivePageComponent, "pageObjectName": "receive_page" })
                                            append({"text": qsTr("Send Invoice"), "iconSource": "qrc:/icons/resources/icons/drawer_send_invoice_list_item_icon.svg", "page": _sendInvoicePageComponent, "pageObjectName": "send_invoice_page" })
                                            append({"text": qsTr("Transactions"), "iconSource": "qrc:/icons/resources/icons/drawer_transactions_list_item_icon.svg", "page": _transactionsPageComponent, "pageObjectName": "transactions_page" })
                                            append({"text": qsTr("Messages"), "iconSource": "qrc:/icons/resources/icons/drawer_messages_list_item_icon.svg", "page": _messagesPageComponent, "pageObjectName": "messages_page" })
                                            append({"text": qsTr("Send Message"), "iconSource": "qrc:/icons/resources/icons/drawer_send_message_list_item_icon.svg", "page": _sendMessagePageComponent, "pageObjectName": "send_message_page" })
                                            append({"text": qsTr("Address Book"), "iconSource": "qrc:/icons/resources/icons/drawer_address_book_list_item_icon.svg", "page": _addressBookPageComponent, "pageObjectName": "address_book_page" })
                                            append({"text": qsTr("Mining"), "iconSource": "qrc:/icons/resources/icons/drawer_mining_list_item_icon.svg", "page": _miningPageComponent, "pageObjectName": "mining_page" })
                                            //disable search tab
                                            //append({"text": qsTr("Search"), "iconSource": "qrc:/icons/resources/icons/drawer_search_list_item_icon.svg", "page": _searchPageComponent, "pageObjectName": "search_page" })
                                            append({"text": qsTr("Browser"), "iconSource": "qrc:/icons/resources/icons/earth-globe_icon.svg", "page": _browserPageComponent, "pageObjectName": "browser_page" })
                                        }
                                    }

                                    delegate: UNDrawerListItem {
                                        id: _menuAction

                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.leftMargin: 19 - (Theme.drawerIconSize - 18) / 2
                                        anchors.rightMargin: 24

                                        checked: index === _menuActionsList.currentIndex

                                        iconSource: model.iconSource
                                        text: model.text
                                        defaultColor: Theme.drawerTextColor
                                        activeColor: Theme.drawerActiveTextColor

                                        onClicked: {
                                            _menuActionsList.currentIndex = index
                                            if(_appPagesStackView.currentItem.objectName !== model.pageObjectName) {
                                                _appPagesStackView.pop(null, StackView.PopTransition)
                                                _appPagesStackView.push(model.page)
                                            }
                                        }
                                    }
                                }
                            }

                            Column {
                                id: _actionsColumn

                                anchors.left: parent.left
                                anchors.right: parent.right

                                height: childrenRect.height

                                opacity: _actionsColumn.width > 200 ? 1.0 : 0.0

                                visible: false //disabled - all functions moved to app menu bar

                                Behavior on opacity {
                                    OpacityAnimator{
                                        duration: 125
                                    }
                                }

                                Column {
                                    anchors.left: parent.left
                                    anchors.right: parent.right

                                    height: childrenRect.height

                                    Item {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        height: 28
                                    }

                                    UNHorizontalSeparator {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.leftMargin: 32
                                        anchors.rightMargin: 32

                                        color: Theme.drawerSeparatorColor
                                    }

                                    Item {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        height: 24
                                    }

                                    UNLabel {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.leftMargin: 35

                                        type: UNLabel.Type.TypeMedium
                                        size: 14
                                        horizontalAlignment: Label.AlignLeft
                                        verticalAlignment: Label.AlignVCenter
                                        color: Theme.drawerDefaultTextColor
                                        font.capitalization: Font.AllUppercase
                                        font.letterSpacing: 0.85

                                        text: qsTr("Wallet Actions")
                                    }

                                    Item {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        height: 24
                                    }

                                    UNDrawerListItem {
                                        id: _createWalletAction

                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.leftMargin: 19
                                        anchors.rightMargin: 24

                                        checkable: false
                                        checked: false
                                        iconSource: "qrc:/icons/resources/icons/drawer_wallet_actions_list_item_icon.svg"
                                        text: qsTr("Create Wallet")
                                        defaultColor: Theme.drawerTextColor
                                        activeColor: Theme.drawerActiveTextColor

                                        onClicked: {
                                            _walletDialog.selectFolder = false
                                            _walletDialog.selectExisting = false
                                            _walletDialog.title = qsTr("New wallet file")
                                            _walletDialog.defaultSuffix = "wallet"
                                            _walletDialog.nameFilters = ["Wallet Files (*.wallet)"]
                                            _walletDialog.acceptedCallback = walletAdapter.createWallet
                                            _walletDialog.open()
                                        }
                                    }

                                    UNDrawerListItem {
                                        id: _openWalletAction

                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.leftMargin: 19
                                        anchors.rightMargin: 24

                                        checkable: false
                                        checked: false
                                        iconSource: "qrc:/icons/resources/icons/drawer_wallet_actions_list_item_icon.svg"
                                        text: qsTr("Open wallet")
                                        defaultColor: Theme.drawerTextColor
                                        activeColor: Theme.drawerActiveTextColor

                                        onClicked: {
                                            _walletDialog.selectFolder = false
                                            _walletDialog.selectExisting = true
                                            _walletDialog.title = qsTr("Open .wallet/.keys file")
                                            _walletDialog.nameFilters = ["Wallet Files (*.wallet)", "Keys Files (*.keys)"]
                                            _walletDialog.acceptedCallback = walletAdapter.openWallet
                                            _walletDialog.open()
                                        }
                                    }

                                    UNDrawerListItem {
                                        id: _importPrivateKeyWalletAction

                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.leftMargin: 19
                                        anchors.rightMargin: 24

                                        checkable: false
                                        checked: false
                                        iconSource: "qrc:/icons/resources/icons/drawer_wallet_actions_list_item_icon.svg"
                                        text: qsTr("Import Private Key")
                                        defaultColor: Theme.drawerTextColor
                                        activeColor: Theme.drawerActiveTextColor

                                        onClicked: {
                                            _importPrivateKeyDialog.open()
                                        }
                                    }

                                    UNDrawerListItem {
                                        id: _backupWalletAction

                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.leftMargin: 19
                                        anchors.rightMargin: 24

                                        visible: walletAdapter.isWalletOpen

                                        checkable: false
                                        checked: false
                                        iconSource: "qrc:/icons/resources/icons/drawer_wallet_actions_list_item_icon.svg"
                                        text: qsTr("Backup Wallet")
                                        defaultColor: Theme.drawerTextColor
                                        activeColor: Theme.drawerActiveTextColor

                                        onClicked: {
                                            _walletDialog.selectFolder = false
                                            _walletDialog.selectExisting = false
                                            _walletDialog.title = qsTr("Backup wallet to...")
                                            _walletDialog.defaultSuffix = "wallet"
                                            _walletDialog.nameFilters = ["Wallet Files (*.wallet)"]
                                            _walletDialog.acceptedCallback = walletAdapter.backupWallet
                                            _walletDialog.open()
                                        }
                                    }

                                    UNDrawerListItem {
                                        id: _walletAction

                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.leftMargin: 19
                                        anchors.rightMargin: 24

                                        visible: walletAdapter.isWalletOpen

                                        checkable: false
                                        checked: false
                                        iconSource: "qrc:/icons/resources/icons/drawer_wallet_actions_list_item_icon.svg"
                                        text: qsTr("Reset Wallet")
                                        defaultColor: Theme.drawerTextColor
                                        activeColor: Theme.drawerActiveTextColor

                                        onClicked: {
                                            _messageDialogProperties.title = qsTr("Warning")
                                            _messageDialogProperties.okCancel = true
                                            _messageDialogProperties.acceptCallback = walletAdapter.resetWallet
                                            _messageDialogProperties.text = qsTr("Your wallet will be reset and restored from blockchain.\nAre you sure?")
                                        }
                                    }

                                    Item {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        height: 28
                                    }
                                }

                                Column {
                                    anchors.left: parent.left
                                    anchors.right: parent.right

                                    height: childrenRect.height

                                    UNHorizontalSeparator {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.leftMargin: 32
                                        anchors.rightMargin: 32

                                        color: Theme.drawerSeparatorColor
                                    }

                                    Item {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        height: 24
                                    }

                                    UNLabel {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.leftMargin: 35

                                        type: UNLabel.Type.TypeMedium
                                        size: 14
                                        horizontalAlignment: Label.AlignLeft
                                        verticalAlignment: Label.AlignVCenter
                                        color: Theme.drawerDefaultTextColor
                                        font.capitalization: Font.AllUppercase
                                        font.letterSpacing: 0.85

                                        text: qsTr("Settings")
                                    }

                                    Item {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        height: 24
                                    }

                                    UNDrawerListItem {
                                        id: _encryptWalletAction

                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.leftMargin: 19
                                        anchors.rightMargin: 24

                                        visible: !walletAdapter.isWalletEncrypted

                                        checkable: false
                                        checked: false
                                        iconSource: "qrc:/icons/resources/icons/drawer_settings_list_item_icon.svg"
                                        text: qsTr("Encrypt Wallet")
                                        defaultColor: Theme.drawerTextColor
                                        activeColor: Theme.drawerActiveTextColor

                                        onClicked: {
                                            _changePasswordDialog.changePwd = false
                                            _changePasswordDialog.clear()
                                            _changePasswordDialog.open()
                                        }
                                    }

                                    UNDrawerListItem {
                                        id: _changePasswordAction

                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.leftMargin: 19
                                        anchors.rightMargin: 24

                                        visible: walletAdapter.isWalletEncrypted

                                        checkable: false
                                        checked: false
                                        iconSource: "qrc:/icons/resources/icons/drawer_settings_list_item_icon.svg"
                                        text: qsTr("Change Password")
                                        defaultColor: Theme.drawerTextColor
                                        activeColor: Theme.drawerActiveTextColor

                                        onClicked: {
                                            _changePasswordDialog.changePwd = true
                                            _changePasswordDialog.clear()
                                            _changePasswordDialog.open()
                                        }
                                    }

                                    UNDrawerListItem {
                                        id: _conectionAction

                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.leftMargin: 19
                                        anchors.rightMargin: 24

                                        checkable: false
                                        checked: false
                                        iconSource: "qrc:/icons/resources/icons/drawer_settings_list_item_icon.svg"
                                        text: qsTr("Connection")
                                        defaultColor: Theme.drawerTextColor
                                        activeColor: Theme.drawerActiveTextColor

                                        onClicked: {
                                            _connectionSettingsDialog.open()
                                        }
                                    }

                                    UNDrawerListItem {
                                        id: _changeFiatSymbolAction

                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.leftMargin: 19
                                        anchors.rightMargin: 24

                                        checkable: false
                                        checked: false
                                        iconSource: "qrc:/icons/resources/icons/drawer_settings_list_item_icon.svg"
                                        text: qsTr("Change Fiat Symbol")
                                        defaultColor: Theme.drawerTextColor
                                        activeColor: Theme.drawerActiveTextColor

                                        onClicked: {
                                            _fiatSymbolDialog.open()
                                        }
                                    }

                                    UNDrawerListItem {
                                        id: _startOnLoginAction

                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.leftMargin: 19
                                        anchors.rightMargin: 24

                                        checked: walletAdapter.isStartOnLoginEnabled
                                        iconSource: checked
                                                    ? "qrc:/icons/resources/icons/drawer_checkbox_checked_list_item_icon.svg"
                                                    : "qrc:/icons/resources/icons/drawer_checkbox_unchecked_list_item_icon.svg"
                                        text: qsTr("Start on system login")
                                        defaultColor: Theme.drawerTextColor
                                        activeColor: Theme.drawerActiveTextColor

                                        onClicked: {
                                            walletAdapter.isStartOnLoginEnabled = checked
                                        }
                                    }

                                    UNDrawerListItem {
                                        id: _EnableTOR

                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.leftMargin: 19
                                        anchors.rightMargin: 24

                                        checked: walletAdapter.isTorEnabled
                                        iconSource: checked
                                                    ? "qrc:/icons/resources/icons/drawer_checkbox_checked_list_item_icon.svg"
                                                    : "qrc:/icons/resources/icons/drawer_checkbox_unchecked_list_item_icon.svg"
                                        text: qsTr("Enable TOR")
                                        defaultColor: Theme.drawerTextColor
                                        activeColor: Theme.drawerActiveTextColor
                                    }

                                    Item {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        height: 24
                                    }
                                }
                            }
                        }

                    }
                }
            }

            ColumnLayout {
                Layout.fillHeight: true
                Layout.fillWidth: true
                spacing: 0

                StackView {
                    id: _appPagesStackView

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    pushEnter: Transition {
                        YAnimator { from: 40; to: 0; duration: 225; easing.type: Easing.OutCubic }
                        NumberAnimation { property: "opacity"; from: 0.4; to: 1.0; duration: 225; easing.type: Easing.OutCubic }
                    }

                    pushExit: Transition {
                        PauseAnimation { duration: 225 }
                    }

                    popEnter: Transition {
                        PauseAnimation { duration: 225 }
                    }

                    popExit: Transition {
                        PauseAnimation { duration: 225 }
                    }

                    initialItem: _depositsPageComponent

                    Component {
                        id: _depositsPageComponent

                        DepositsPage {
                            id: _depositsPageComponentItem
                        }
                    }

                    Component {
                        id: _addressBookPageComponent

                        AddressBookPage {
                            id: _addressBookPageComponentItem
                        }
                    }

                    Component {
                        id: _sendPageComponent

                        SendPage {
                            id: _sendPageComponentItem
                        }
                    }

                    Component {
                        id: _receivePageComponent

                        ReceivePage {
                            id: _receivePageComponentItem
                        }
                    }

                    Component {
                        id: _sendInvoicePageComponent

                        SendInvoicePage {
                            id: sendInvoicePageComponentItem
                        }
                    }

                    Component {
                        id: _transactionsPageComponent

                        TransactionsPage {
                            id: _transactionsPageComponentItem
                        }
                    }

                    Component {
                        id: _messagesPageComponent

                        MessagesPage {
                            id: _messagesPageComponentItem
                        }
                    }

                    Component {
                        id: _sendMessagePageComponent

                        SendMessagePage {
                            id: _sendMessagePageComponentItem
                        }
                    }

                    Component {
                        id: _miningPageComponent

                        MiningPage {
                            id: _miningPageComponentItem
                        }
                    }

                    //disable search tab
                    /*Component {
                        id: _searchPageComponent

                        SearchPage {
                            id: _searchPageComponentItem
                        }
                    }*/
                    Component {
                        id: _browserPageComponent

                        BrowserPage {
                            id: _browserPageComponentItem
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.maximumHeight: 32
                    Layout.minimumHeight: 32
                    Layout.preferredHeight: 32

                    UNElevatedPanel {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: -5
                        anchors.right: parent.right
                        anchors.rightMargin: -5
                        radius: 5

                        z: parent.z + 1

                        height: 32
                        width: 190

                        elevation: 12

                        color: Theme.panelBackgroundColor
                        borderColor: Theme.panelBorderColor

                        RowLayout {
                            id: iconRow

                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 21
                            anchors.bottomMargin: 5

                            spacing: 0

                            UNLabel {
                                id: _statusText

                                Layout.maximumWidth: implicitWidth
                                Layout.minimumWidth: implicitWidth
                                Layout.preferredWidth: implicitWidth
                                Layout.alignment: Qt.AlignVCenter

                                type: UNLabel.Type.TypeMedium

                                color: "white"
                                elide: Label.ElideNone
                                wrapMode: Label.NoWrap

                                text: qsTr("Status")

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onEntered: {
                                        statusTooltip.open()
                                    }
                                    onExited: {
                                        statusTooltip.hide()
                                    }
                                }

                                UNToolTip {
                                    id: statusTooltip

                                    timeout: 10000
                                    delay: 0
                                    text: walletAdapter.statusBarText
                                }
                            }

                            UNLayoutSpacer {}

                            UNImage {
                                id: remoteModeIcon

                                Layout.maximumWidth: 15
                                Layout.minimumWidth: 15
                                Layout.preferredWidth: 15
                                Layout.maximumHeight: 15
                                Layout.minimumHeight: 15
                                Layout.preferredHeight: 15
                                Layout.alignment: Qt.AlignVCenter

                                source: walletAdapter.remoteModeIcon
                                toolTip: walletAdapter.remoteModeToolTip
                            }

                            UNLayoutSpacer {
                                fixedWidth: 8
                            }

                            UNImage {
                                Layout.maximumWidth: 15
                                Layout.minimumWidth: 15
                                Layout.preferredWidth: 15
                                Layout.maximumHeight: 15
                                Layout.minimumHeight: 15
                                Layout.preferredHeight: 15
                                Layout.alignment: Qt.AlignVCenter

                                source: walletAdapter.connectionStateIcon
                                toolTip: walletAdapter.connectionStateToolTip
                            }

                            UNLayoutSpacer {
                                fixedWidth: 8
                            }

                            UNImage {
                                Layout.maximumWidth: 15
                                Layout.minimumWidth: 15
                                Layout.preferredWidth: 15
                                Layout.maximumHeight: 15
                                Layout.minimumHeight: 15
                                Layout.preferredHeight: 15
                                Layout.alignment: Qt.AlignVCenter

                                source: walletAdapter.encryptionStateIcon
                                toolTip: walletAdapter.encryptionStateToolTip

                            }

                            UNLayoutSpacer {
                                fixedWidth: 8
                            }

                            UNAnimatedImage {
                                Layout.maximumWidth: 15
                                Layout.minimumWidth: 15
                                Layout.preferredWidth: 15
                                Layout.maximumHeight: 15
                                Layout.minimumHeight: 15
                                Layout.preferredHeight: 15
                                Layout.alignment: Qt.AlignVCenter

                                source: walletAdapter.synchronizationStateIcon
                                toolTip: walletAdapter.synchronizationStateToolTip
                                playing: walletAdapter.synchronizationStatePlaying
                            }

                        }

                    }

                }
            }
        }

        RequestPasswordDialog {
            id: _requestPasswordDialog
        }

        ChangePasswordDialog {
            id: _changePasswordDialog
        }

        AddressBookDialog {
            id: _addressBookDialog
        }

        MessageDetailsDialog {
            id: _messageDetailsDialog
        }

        TransactionDetailsDialog {
            id: _transactionDetailsDialog
        }

        DepositDetailsDialog {
            id: _depositDetailsDialog
        }

        NewRemoteNodeDialog {
            id: _newRemoteNodeDialog
        }

        NewAddressDialog {
            id: _newAddressDialog
        }

        ConnectionSettingsDialog {
            id: _connectionSettingsDialog
        }

        ImportPrivateKeyDialog {
            id: _importPrivateKeyDialog
        }

        FiatSymbolDialog {
            id: _fiatSymbolDialog

            fiatModel: walletAdapter.fiatConverter.availableFiatList
            selectedIndex: walletAdapter.fiatConverter.currentIndex

            onAccepted: {
                walletAdapter.fiatConverter.currentIndex = _fiatSymbolDialog.selectedIndex
                walletAdapter.fiatConverter.setFiatId(_fiatSymbolDialog.selectedIndex)
            }
        }

        MessageDialog {
            id: _messageDialog

            QtObject {
                id: _messageDialogProperties
                property string title: ""
                property string text: ""
                property bool okCancel: false
                property var acceptCallback: null

                onTextChanged: {
                    if("" !== _messageDialogProperties.text) {
                        _messageDialog.open()
                    }
                }

                function createNewList() {
                    var newListModel = Qt.createQmlObject('import QtQuick 2.13; ListModel {}', _messageDialog);
                    return newListModel;
                }

                function fillMessageDialogButtonsModel() {
                    _messageDialog.buttons.clear()

                    var listModel = createNewList()

                    listModel.append({'type': UNDialog.ButtonType.TypeNormal, 'role': DialogButtonBox.AcceptRole, 'text': qsTr("OK")})
                    if(okCancel) {
                        listModel.append({'type': UNDialog.ButtonType.TypeNormal, 'role': DialogButtonBox.RejectRole, 'text': qsTr("Cancel")})
                    }
                    _messageDialog.buttons = listModel
                }

                Component.onCompleted: {
                    fillMessageDialogButtonsModel()
                }

                onOkCancelChanged: {
                    fillMessageDialogButtonsModel()
                }

                function showMessage(title, msg) {
                    _messageDialogProperties.title = title
                    _messageDialogProperties.okCancel = false
                    _messageDialogProperties.acceptCallback = null
                    _messageDialogProperties.text = msg
                }
            }
        }
    }

    Row {
        id: _appMenuRow

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.topMargin: _appWindow.maximized ? 0 : 10
        anchors.leftMargin: 16

        height: 32

        width: childrenRect.width

        UNStatusBarMenuButton{
            anchors.top: parent.top
            anchors.bottom: parent.bottom

            text: qsTr("Wallet")

            onClicked: {
                _walletMenu.open()
            }

            UNMenu {
                id: _walletMenu

                y: parent.height
                x: 0

                margins: 20
                topPadding: 24
                bottomPadding: 24
                rightPadding: 24

                color: Theme.statusBarMenuColor

                UNMenuItem {
                    text: qsTr("Create Wallet")

                    onClicked: {
                        _walletDialog.selectFolder = false
                        _walletDialog.selectExisting = false
                        _walletDialog.title = qsTr("New wallet file")
                        _walletDialog.defaultSuffix = "wallet"
                        _walletDialog.nameFilters = ["Wallet Files (*.wallet)"]
                        _walletDialog.acceptedCallback = walletAdapter.createWallet
                        _walletDialog.open()
                    }
                }

                UNMenuItem {
                    text: qsTr("Open wallet")

                    onClicked: {
                        _walletDialog.selectFolder = false
                        _walletDialog.selectExisting = true
                        _walletDialog.title = qsTr("Open .wallet/.keys file")
                        _walletDialog.nameFilters = ["Wallet Files (*.wallet)", "Keys Files (*.keys)"]
                        _walletDialog.acceptedCallback = walletAdapter.openWallet
                        _walletDialog.open()
                    }
                }

                UNMenuItem {
                    text: qsTr("Import Private Key")

                    onClicked: {
                        _importPrivateKeyDialog.open()
                    }
                }

                UNMenuItem {
                    text: qsTr("Backup Wallet")

                    onClicked: {
                        _walletDialog.selectFolder = false
                        _walletDialog.selectExisting = false
                        _walletDialog.title = qsTr("Backup wallet to...")
                        _walletDialog.defaultSuffix = "wallet"
                        _walletDialog.nameFilters = ["Wallet Files (*.wallet)"]
                        _walletDialog.acceptedCallback = walletAdapter.backupWallet
                        _walletDialog.open()
                    }
                }

                UNMenuItem {
                    text: qsTr("Reset Wallet")

                    onClicked: {
                        _messageDialogProperties.title = qsTr("Warning")
                        _messageDialogProperties.okCancel = true
                        _messageDialogProperties.acceptCallback = walletAdapter.resetWallet
                        _messageDialogProperties.text = qsTr("Your wallet will be reset and restored from blockchain.\nAre you sure?")
                    }
                }

                UNMenuItem {
                    text: qsTr("Optimize Wallet")
                    onClicked: walletAdapter.optimizeClicked()
                }

                UNMenuItem {
                    checkable: true
                    checked: walletAdapter.isAutoOpimizationEnabled()
                    text: qsTr("Auto Optimization")

                    onClicked: {

                        if(walletAdapter.isAutoOpimizationEnabled())
                            _messageDialogProperties.showMessage("Auto Optimization", "Auto Optimization Disabled.")
                        else _messageDialogProperties.showMessage("Auto Optimization", "Auto Optimization Enabled. Your wallet will be optimized automatically every 15 minutes.")
                        walletAdapter.autoOptimizeClicked()
                    }
                }

                UNMenuItem {
                    text: qsTr("Exit")

                    onClicked: {
                        _appWindow.close();
                    }
                }
            }
        }

        UNStatusBarMenuButton{
            anchors.top: parent.top
            anchors.bottom: parent.bottom

            text: qsTr("Settings")

            onClicked: {
                _settingsMenu.open()
            }

            UNMenu {
                id: _settingsMenu

                y: parent.height
                x: 0

                margins: 20
                topPadding: 24
                bottomPadding: 27
                rightPadding: 50

                color: Theme.statusBarMenuColor


                UNMenuItem {
                    text: walletAdapter.isWalletEncrypted ? qsTr("Change Password") : qsTr("Encrypt Wallet")

                    onClicked: {
                        _changePasswordDialog.changePwd = walletAdapter.isWalletEncrypted
                        _changePasswordDialog.clear()
                        _changePasswordDialog.open()
                    }
                }

                UNMenuItem {
                    text: qsTr("Connection")

                    onClicked: {
                        _connectionSettingsDialog.open()
                    }
                }

                UNMenuItem {
                    text: qsTr("Change Fiat Symbol")

                    onClicked: {
                        _fiatSymbolDialog.open()
                    }
                }

                UNMenuItem {
                    checkable: true
                    checked: walletAdapter.isStartOnLoginEnabled
                    text: qsTr("Start on system login")

                    onClicked: {
                        walletAdapter.isStartOnLoginEnabled = checked
                    }
                }
                UNMenuItem {
                    checkable: true
                    checked: walletAdapter.isTorEnabled
                    text: qsTr("Enable TOR")

                    onClicked: {
                        walletAdapter.isTorEnabled = checked
                        walletAdapter.enableTor()
                    }
                }
            }
        }
    }

}
