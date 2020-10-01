import QtQuick 2.13
import QtQuick.Controls.Material 2.13

pragma Singleton

QtObject {
    readonly property bool isWindows: Qt.platform.os === "windows"
    readonly property bool isMac: Qt.platform.os === "osx"

    readonly property int horizontalMargin: 20
    readonly property int verticalMargin: 20
    readonly property int textPointSize: isMac ? 13 : 10
    readonly property int tableHeaderHeight: 40
    readonly property real tableRowHeight: 30
    readonly property color tableRowColor: Qt.darker("grey")
    readonly property color tableRowActiveColor: "#1A237E"

    //[Message details dialog]
    readonly property color messageDetailsDialogButtonColor: "#FFFFFF"
    readonly property color messageDetailsDialogButtonTextColor: "#344955"
    readonly property color messageDetailsDialogTextAreaColor: Qt.lighter("gray")
    readonly property color messageDetailsDialogButtonActiveColor: "gray"
    readonly property int messageDetailsDialogButtonheight: 30
    readonly property int messageDetailsDialogButtonwidth: 75
    readonly property int messageDetailsDialogButtonFontSize: 12
    readonly property int messageDetailsDialogWindowWidth: 660

    //[V2 Common Colors]

    readonly property color primaryColor: "#344955"
    readonly property color primaryLightColor: "#4a6572"
    readonly property color primaryDarkColor: "#232f34"
    readonly property color secondaryColor: "#E0E0E0"

    readonly property color textColor: "#ffffff"
    readonly property color errorColor: "#ff4c5d"
    readonly property color drawerDefaultTextColor: "#FFFFFF"

    //[Controls]

    //StatusBar
    readonly property color statusBarColor: "#424242"

    //StatusBarMenu
    readonly property color statusBarMenuColor: "#FAFAFA"
    readonly property color statusBarMenuTextColor: "#000000"
    readonly property color statusBarMenuActiveTextColor: "#616161"
    readonly property color statusBarMenuCheckableFrameColor: "#616161"
    readonly property color statusBarMenuCheckableActiveColor: "#424242"
    readonly property color statusBarTitleColor: "#ffffff"

    //Drawer
    readonly property color drawerBackgroundColor: "#282D31"
    readonly property color drawerTextColor: "#C2DDDD"
    readonly property color drawerActiveTextColor: "#FFA500"
    readonly property color drawerSeparatorColor: "#444444"
    readonly property int drawerIconSize: 24

    //StatusPanel
    readonly property color panelBackgroundColor: "#282D31"
    readonly property color panelBorderColor: "#444444"

    //DrawerMainActionButton
    readonly property color drawerMainActionButtonColor: "#232f34"
    readonly property color drawerMainActionButtonTextColor: "#FFA500"
    readonly property color drawerMainActionButtonBorderColor: "#FFA500"

    //BalanceReport
    readonly property color balanceReportBackgroundColor: "#FAFAFA"
    readonly property color balanceReportTextColor: "#000000"

    //Page
    readonly property color pageTabBarColor: "#282D31"
    readonly property color pageTitleColor: "#ffffff"
    readonly property color pageBackgroundColor: "#2a2d30"

    //Button
    readonly property color buttonActiveColor: Qt.darker("#282D31", 1.5)
    readonly property color buttonBaseColor: "#282D31"
    readonly property color buttonDisabledColor: "#444444"
    readonly property color buttonTextColor: "#ffffff"
    readonly property color buttonDisabledTextColor: "#ffffff"
    readonly property color buttonActiveBorderColor: "#FFA500"
    readonly property color buttonDisabledBorderColor: "#444444"

    //Checkbox
    readonly property color checkboxIndicatorColor: "#344955"
    readonly property color checkboxTextColor: "#aeaeb1"
    readonly property color checkboxFrameColor: "#4a6572"
    readonly property color checkboxActiveColor: "#E0E0E0"
    readonly property int checkboxTextSize: 16

    //RadioButton
    readonly property color radioButtonTextColor: "#aeaeb1"
    readonly property color radioButtonFrameColor: "#4a6572"
    readonly property color radioButtonActiveColor: "#E0E0E0"
    readonly property color radioButtonInfinityActiveColor: "#FFA500"
    readonly property color radioButtonInfinityFrameColor: "#FFFFFF"
    readonly property color radioButtonInfinityTextColor: "#FFFFFF"

    //Dialog
    readonly property color dialogBackgroundColor: "#ffffff"
    readonly property color dialogTextColor: "#000000"
    readonly property color dialogTitleTextColor: "#232f34"
    readonly property color dialogActionButtonColor: "#344955"

    //DialogInfinity
    readonly property color dialogInfinityBackgroundColor: "#282D31"
    readonly property color dialogInfinityTextColor: "#C2DDDD"
    readonly property color dialogInfinityTitleTextColor: "#FFFFFF"

    //TextArea
    readonly property color textAreaActiveColor: "#E0E0E0"
    readonly property color textAreaBackgroundColor: "#4a6572"
    readonly property color textAreaPlaceholderTextColor: "#ffffff"
    readonly property double textAreaActiveOpacity: 0.18
    readonly property double textAreaRestingOpacity: 0.12
    readonly property int textAreaTextSize: 16
    readonly property color textAreaTextColor: "#aeaeb1"
    readonly property color textAreaSelectedTextColor: "#ffffff"
    readonly property color textAreaSelectionColor: "#1A237E"

    //TextField
    readonly property color textFieldActiveColor: "#E0E0E0"
    readonly property color textFieldBackgroundColor: "#4a6572"
    readonly property color textFieldPlaceholderTextColor: "#ffffff"
    readonly property double textFieldActiveOpacity: 1.18
    readonly property double textFieldRestingOpacity: 0.12
    readonly property int textFieldTextSize: 16
    readonly property color textFieldTextColor: "#aeaeb1"
    readonly property color textFieldSelectedTextColor: "#ffffff"
    readonly property color textFieldSelectionColor: "#1A237E"

    //TableView
    readonly property color tableTextColor: "#ffffff"

    //Tooltip
    readonly property color tooltipBackgroundColor: "#1A237E"
    readonly property color tooltipTextColor: "#ffffff"

    //Barcode Widget
    readonly property color barcodeBackgroundColor: "#282D31"
    readonly property color barcodeTitleColor: "#C2DDDD"
    readonly property color barcodeIconColor: "#ffffff"
    readonly property color barcodeBackgroundBorderColor: "#FFA500"

    //ScrollIndicator
    readonly property color scrollIndicatorBackgroundColor: "#4a6572"
    readonly property color scrollIndicatorColor: "#EEEEEE"

    //TableHeaderLabel
    readonly property color tableHeaderLabelBackgroundColor: "#616161"
    readonly property color tableHeaderLabelColor: "#ffffff"

    //SpinBox
    readonly property color spinBoxTextColor: "#ffffff"
    readonly property color spinBoxActiveColor: "#E0E0E0"
    readonly property int spinBoxFontSize: 16
    readonly property color dialogSpinBoxActiveColor: "#4a6572"
    readonly property color dialogSpinBoxTextColor: "#000000"

    //Slider
    readonly property color sliderActiveColor: "#E0E0E0"
    readonly property color sliderBackgroundColor: "#4a6572"

    //SearchListView
    readonly property color searchResultBackgroundColor: "#FFFFFF"
    readonly property color searchResultBackgroundBorder: "#E0E0E0"
    readonly property color searchResultTextColor: "#000000"

    //[Pages]
    //Receive page
    readonly property color privateBarcodeOverlayIconColor: "#aeaeb1"
    readonly property color privateBarcodeOverlayTextColor: "#aeaeb1"

    //Send Page
    readonly property color sendPageIconColor: "#E0E0E0"

    //Send Page
    readonly property color sendInvoicePageIconColor: "#E0E0E0"

    //Send Message Page
    readonly property color sendMessagePageIconColor: "#E0E0E0"

    //Mining page
    readonly property int miningCheckBoxTextColor: 18
}
