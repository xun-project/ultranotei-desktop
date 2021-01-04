import Qt.labs.settings 1.0
import QtQml 2.2
import QtQuick 2.2
import QtQuick 2.13 as QQPrivate
import QtQuick.Controls 1.4
import QtQuick.Controls.Private 1.0 as QQCPrivate
import QtQuick.Controls.Styles 1.4
import QtQuick.Dialogs 1.3
import QtQuick.Layouts 1.13
import QtWebEngine 1.9    //qt5.13.2
//import QtWebEngine 1.10 //qt5.14.1

import UltraNote.UI 1.0
import QtQuick.Controls 2.13 as QQC213

FocusScope {
    id: browserWindow

    property QtObject defaultProfile: WebEngineProfile {
        storageName: "Profile"
        offTheRecord: false
        useForGlobalCertificateVerification: true
    }

    property QtObject otrProfile: WebEngineProfile {
        offTheRecord: true
    }

    /*function createWindow(profile) {
        console.log("create window download")
        var newWindow = browserWindowComponent.createObject(root);
        newWindow.currentWebView.profile = profile;
        profile.downloadRequested.connect(newWindow.onDownloadRequested);
        return newWindow;
    }
    function createDialog(profile) {
        console.log("create Dialog")
        var newDialog = browserDialogComponent.createObject(root);
        newDialog.currentWebView.profile = profile;
        return newDialog;
    }*/

    function load(url) {
        console.log("url :"+url)
        var browserWindow = createWindow(defaultProfile);
        browserWindow.currentWebView.url = url;
    }

    function addStandardTab() {
        tabs.createEmptyTab(tabs.count !== 0 ? currentWebView.profile : defaultProfile);
        tabs.currentIndex = tabs.count - 1;
        addressBar.forceActiveFocus();
        addressBar.selectAll();
    }

    property Item currentWebView: tabs.currentIndex < tabs.count ? tabs.getTab(tabs.currentIndex).item : null

    // Make sure the Qt.WindowFullscreenButtonHint is set on OS X.
    Component.onCompleted: flags = flags | Qt.WindowFullscreenButtonHint

    /*onCurrentWebViewChanged: {
        findBar.reset();
    }*/

    // Create a styleItem to determine the platform.
    // When using style "mac", ToolButtons are not supposed to accept focus.
    QQCPrivate.StyleItem { id: styleItem }
    property bool platformIsMac: styleItem.style === "mac"

    Settings {
        id : appSettings
        property alias autoLoadImages: loadImages.checked
        property alias errorPageEnabled: errorPageEnabled.checked
        property alias pluginsEnabled: pluginsEnabled.checked
        property alias fullScreenSupportEnabled: fullScreenSupportEnabled.checked
        property alias autoLoadIconsForPage: autoLoadIconsForPage.checked
        property alias touchIconsEnabled: touchIconsEnabled.checked
        property alias devToolsEnabled: devToolsEnabled.checked
        property alias pdfViewerEnabled: pdfViewerEnabled.checked
    }

    /*Action {
        shortcut: "Ctrl+D"
        onTriggered: {
            downloadView.visible = !downloadView.visible;
        }
    }*/
    Action {
        id: focus
        shortcut: "Ctrl+L"
        onTriggered: {
            addressBar.forceActiveFocus();
            addressBar.selectAll();
        }
    }
    Action {
        shortcut: StandardKey.Refresh
        onTriggered: {
            if (currentWebView)
                currentWebView.reload();
        }
    }
    Action {
        shortcut: StandardKey.AddTab
        onTriggered: addStandardTab()
    }
    Action {
        shortcut: StandardKey.Close
        onTriggered: {
            currentWebView.triggerWebAction(WebEngineView.RequestClose);
        }
    }
    /*Action {
        shortcut: "Escape"
        onTriggered: {
            if (findBar.visible)
                findBar.visible = false;
        }
    }*/
    Action {
        shortcut: "Ctrl+0"
        onTriggered: currentWebView.zoomFactor = 1.0
    }
    Action {
        shortcut: StandardKey.ZoomOut
        onTriggered: currentWebView.zoomFactor -= 0.1
    }
    Action {
        shortcut: StandardKey.ZoomIn
        onTriggered: currentWebView.zoomFactor += 0.1
    }

    QQPrivate.Shortcut {
        sequence: StandardKey.Copy
        onActivated: currentWebView.triggerWebAction(WebEngineView.Copy)
        enabled: _dialog.visible
    }
    Action {
        shortcut: StandardKey.Cut
        onTriggered: currentWebView.triggerWebAction(WebEngineView.Cut)
    }
    Action {
        shortcut: StandardKey.Paste
        onTriggered: currentWebView.triggerWebAction(WebEngineView.Paste)
    }
    Action {
        shortcut: "Shift+"+StandardKey.Paste
        onTriggered: currentWebView.triggerWebAction(WebEngineView.PasteAndMatchStyle)
    }
    Action {
        shortcut: StandardKey.SelectAll
        onTriggered: currentWebView.triggerWebAction(WebEngineView.SelectAll)
    }
    Action {
        shortcut: StandardKey.Undo
        onTriggered: currentWebView.triggerWebAction(WebEngineView.Undo)
    }
    Action {
        shortcut: StandardKey.Redo
        onTriggered: currentWebView.triggerWebAction(WebEngineView.Redo)
    }
    Action {
        shortcut: StandardKey.Back
        onTriggered: currentWebView.triggerWebAction(WebEngineView.Back)
    }
    Action {
        shortcut: StandardKey.Forward
        onTriggered: currentWebView.triggerWebAction(WebEngineView.Forward)
    }
    /*Action {
        shortcut: StandardKey.Find
        onTriggered: {
            if (!findBar.visible)
                findBar.visible = true;
        }
    }
    Action {
        shortcut: StandardKey.FindNext
        onTriggered: findBar.findNext()
    }
    Action {
        shortcut: StandardKey.FindPrevious
        onTriggered: findBar.findPrevious()
    }*/

    // toolBar:
    ToolBar {
        id: navigationBar
        Layout.fillWidth: true
        style: ToolBarStyle {
            background: Rectangle {
                Layout.fillWidth: true
                color: "transparent"
            }
        }
        RowLayout {
            id: _toolBarRow
            anchors.fill: parent
            QQC213.ToolButton {
                id: _history
                icon.source: "qrc:/icons/resources/icons/browser_icons/history.svg"
                icon.color: enabled ? Theme.pageTitleColor : "gray"
                QQC213.ToolTip.delay: 200
                QQC213.ToolTip.timeout: 1000
                QQC213.ToolTip.visible: hovered
                QQC213.ToolTip.text: qsTr("Browsing history")
                enabled: true //currentWebView && (currentWebView.canGoBack || currentWebView.canGoForward)
                onClicked: _historyMenu.popup()
                QQC213.Menu {
                    id: _historyMenu
                    width: 350
                    Instantiator {
                        model: currentWebView && currentWebView.navigationHistory.items
                        QQC213.MenuItem {
                            text: model.title
                            onTriggered: currentWebView.goBackOrForward(model.offset)
                            checkable: !enabled
                            checked: !enabled
                            enabled: model.offset
                        }
                        onObjectAdded: function(index, object) {
                            _historyMenu.insertItem(index, object)
                        }
                        onObjectRemoved: function(index, object) {
                            _historyMenu.removeItem(object)
                        }
                    }
                }
            }
            QQC213.ToolButton {
                id: backButton
                icon.source: "qrc:/icons/resources/icons/browser_icons/leftArrow.svg"
                icon.color: enabled ? Theme.pageTitleColor : "gray"
                QQC213.ToolTip.delay: 200
                QQC213.ToolTip.timeout: 1000
                QQC213.ToolTip.visible: hovered
                QQC213.ToolTip.text: qsTr("Navigate backward")
                onClicked: currentWebView.goBack()
                enabled: currentWebView && currentWebView.canGoBack
                activeFocusOnTab: !browserWindow.platformIsMac
            }
            QQC213.ToolButton {
                id: forwardButton
                icon.source: "qrc:/icons/resources/icons/browser_icons/rightArrow.svg"
                icon.color: enabled ? Theme.pageTitleColor : "gray"
                QQC213.ToolTip.delay: 200
                QQC213.ToolTip.timeout: 1000
                QQC213.ToolTip.visible: hovered
                QQC213.ToolTip.text: qsTr("Navigate forward")
                onClicked: currentWebView.goForward()
                enabled: currentWebView && currentWebView.canGoForward
                activeFocusOnTab: !browserWindow.platformIsMac
            }
            QQC213.ToolButton {
                id: _homeButton
                icon.source: "qrc:/icons/resources/icons/browser_icons/home.svg"
                icon.color: "white"
                QQC213.ToolTip.delay: 200
                QQC213.ToolTip.timeout: 1000
                QQC213.ToolTip.visible: hovered
                QQC213.ToolTip.text: qsTr("Navigate Home")
                onClicked: {
                    tabs.count === 0 ? addStandardTab() : true
                    currentWebView.url = "http://thehiddenwiki.org/"
                }
            }
            TextField {
                id: addressBar
                QQC213.BusyIndicator {
                    id: _pageLoading
                    anchors.verticalCenter: addressBar.verticalCenter;
                    width: parent.height
                    height: parent.height
                    running: currentWebView && currentWebView.loading
                }
                Image {
                    id: _pageIcon
                    anchors.verticalCenter: addressBar.verticalCenter;
                    x: 5
                    z: 2
                    width: 16; height: 16
                    sourceSize: Qt.size(width, height)
                    source: currentWebView && currentWebView.icon
                    visible: !(currentWebView && currentWebView.loading)
                }
                style: TextFieldStyle {
                    padding {
                        left: 26;
                    }
                }
                focus: true
                Layout.fillWidth: true
                text: currentWebView && currentWebView.url
                onAccepted: currentWebView.url = browserUtils.goToUrl(text)
            }
            QQC213.ToolButton {
                id: reloadButton
                icon.source:currentWebView && currentWebView.loading ? "qrc:/icons/resources/icons/browser_icons/cancelButton.svg"
                                                                     : "qrc:/icons/resources/icons/browser_icons/reload.svg"
                icon.color: "white"
                QQC213.ToolTip.delay: 200
                QQC213.ToolTip.timeout: 1000
                QQC213.ToolTip.visible: hovered
                QQC213.ToolTip.text: qsTr("Reload")
                onClicked: currentWebView && currentWebView.loading ? currentWebView.stop() : currentWebView.reload()
                activeFocusOnTab: !browserWindow.platformIsMac
            }
            QQC213.ToolButton {
                id: _addBookmark
                icon.source: "qrc:/icons/resources/icons/browser_icons/bookmarkPlus.svg"
                icon.color: "white"
                QQC213.ToolTip.delay: 200
                QQC213.ToolTip.timeout: 1000
                QQC213.ToolTip.visible: hovered
                QQC213.ToolTip.text: "Bookmark this page"
                onClicked: {
                    browserUtils.addBookmark(currentWebView.url , currentWebView.title)
                    _bookmarkAdded.open()
                }
            }
            QQC213.ToolButton {
                id: settingsMenuButton
                icon.source: "qrc:/icons/resources/icons/browser_icons/setting.svg"
                icon.color: "white"
                QQC213.ToolTip.delay: 200
                QQC213.ToolTip.timeout: 1000
                QQC213.ToolTip.visible: hovered
                QQC213.ToolTip.text: qsTr("Setting")
                onClicked: _walletMenu.open()
                UNMenu{
                    id: _walletMenu
                    y: parent.y + 40
                    x: parent.x
                    margins: 18
                    color: Theme.statusBarMenuColor
                    UNMenuItem {
                        id: loadImages
                        text: qsTr("Autoload images")
                        checkable: true
                        checked: WebEngine.settings.autoLoadImages
                    }
                    UNMenuItem {
                        id: errorPageEnabled
                        text: qsTr("ErrorPage On")
                        checkable: true
                        checked: WebEngine.settings.errorPageEnabled
                    }
                    UNMenuItem {
                        id: pluginsEnabled
                        text: qsTr("Plugins On")
                        checkable: true
                        checked: true
                    }
                    UNMenuItem {
                        id: fullScreenSupportEnabled
                        text: qsTr("FullScreen On")
                        checkable: true
                        checked: WebEngine.settings.fullScreenSupportEnabled
                    }
                    UNMenuItem {
                        id: offTheRecordEnabled
                        text: qsTr("Off The Record")
                        checkable: true
                        checked: currentWebView && currentWebView.profile === otrProfile
                        onToggled: function(checked) {
                            if (currentWebView) {
                                currentWebView.profile = checked ? otrProfile : defaultProfile;
                            }
                        }
                    }
                    UNMenuItem {
                        id: httpDiskCacheEnabled
                        text: qsTr("HTTP Disk Cache")
                        checkable: currentWebView && !currentWebView.profile.offTheRecord
                        checked: currentWebView && (currentWebView.profile.httpCacheType === WebEngineProfile.DiskHttpCache)
                        onToggled: function(checked) {
                            if (currentWebView) {
                                currentWebView.profile.httpCacheType = checked ? WebEngineProfile.DiskHttpCache : WebEngineProfile.MemoryHttpCache;
                            }
                        }
                    }
                    UNMenuItem {
                        id: autoLoadIconsForPage
                        text: qsTr("Icons On")
                        checkable: true
                        checked: WebEngine.settings.autoLoadIconsForPage
                    }
                    UNMenuItem {
                        id: touchIconsEnabled
                        text: qsTr("Touch Icons On")
                        checkable: true
                        checked: WebEngine.settings.touchIconsEnabled
                        enabled: autoLoadIconsForPage.checked
                    }
                    UNMenuItem {
                        id: devToolsEnabled
                        text: qsTr("Open DevTools")
                        checkable: true
                        checked: false
                    }
                    UNMenuItem {
                        id: pdfViewerEnabled
                        text: qsTr("PDF viewer enabled")
                        checkable: true
                        checked: WebEngine.settings.pdfViewerEnabled
                    }
                    /*UNMenuItem {
                        id: showDownloads
                        text: qsTr("Downloads")
                        onTriggered: downloadView.visible = true;
                    }*/
                    UNMenuItem {
                        id: showBookmarks
                        text: qsTr("Bookmarks")
                        onTriggered: {
                            var backgroundTab = tabs.createEmptyTab(currentWebView.profile);
                            backgroundTab.item.loadHtml(browserUtils.getBookmarks(), "ultranoteinfinity://bookmarks")
                            tabs.currentIndex = tabs.count - 1;
                        }
                    }
                }
            }
        }
    }

    QQC213.Popup{
        id:_bookmarkAdded
        x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2)
        //anchors.centerIn: Overlay.overlay
        contentItem: Text {
            text: true ? "Bookmark added" : "Error in page bookmarking"
        }
    }

    TabView {
        id: tabs
        function createEmptyTab(profile) {
            var tab = addTab("", tabComponent);
            // We must do this first to make sure that tab.active gets set so that tab.item gets instantiated immediately.
            tab.active = true;
            tab.title = Qt.binding(function() { return tab.item.title })
            tab.item.profile = profile;
            return tab;
        }

        anchors.top: navigationBar.bottom
        anchors.bottom: devToolsView.top
        anchors.left: parent.left
        anchors.right: parent.right
        Component.onCompleted: createEmptyTab(defaultProfile)

        // Add custom tab view style so we can customize the tabs to include a close button
        style: TabViewStyle {
            property color frameColor: Theme.pageTabBarColor
            property color fillColor: Theme.statusBarColor
            property color nonSelectedColor: "#C8424242"
            frameOverlap: 1
            tabsMovable: true
            frame: Rectangle {
                color: Theme.statusBarColor
                border.color: frameColor
            }
            //rightCorner :
            tab: Rectangle {
                id: tabRectangle
                color: styleData.selected ? fillColor : nonSelectedColor
                border.width: 1
                border.color: frameColor
                implicitWidth: Math.max(text.width + 30, 80)
                implicitHeight: Math.max(text.height + 10, 20)
                Rectangle { height: 1 ; width: parent.width ; color: frameColor}
                Rectangle { height: parent.height ; width: 1; color: frameColor}
                Rectangle { x: parent.width - 2; height: parent.height ; width: 1; color: frameColor}
                Text {
                    id: text
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 6
                    text: styleData.title  === "ultranoteinfinity://bookmarks" ? "Bookmarks" : styleData.title
                    elide: Text.ElideRight
                    color: styleData.selected ? Theme.pageTitleColor : "gray"
                }
                Button {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.rightMargin: 4
                    height: 12
                    style: ButtonStyle {
                        background: Rectangle {
                            implicitWidth: 12
                            implicitHeight: 12
                            color: control.hovered ? "#ccc" : tabRectangle.color
                            Text {text: "x" ; anchors.centerIn: parent ; color: "gray"}
                        }}
                    onClicked: tabs.removeTab(styleData.index);
                }
            }
        }

        Component {
            id: tabComponent
            WebEngineView {
                id: webEngineView
                url: "http://thehiddenwiki.org/"
                settings.javascriptEnabled: true
                settings.javascriptCanOpenWindows: true
                settings.focusOnNavigationEnabled: true
                focus: true

                states: [
                    State {
                        name: "FullScreen"
                        PropertyChanges {
                            target: tabs
                            frameVisible: false
                            tabsVisible: false
                        }
                        PropertyChanges {
                            target: navigationBar
                            visible: false
                        }
                    }
                ]
                settings.autoLoadImages: appSettings.autoLoadImages
                settings.errorPageEnabled: appSettings.errorPageEnabled
                settings.pluginsEnabled: appSettings.pluginsEnabled
                settings.fullScreenSupportEnabled: appSettings.fullScreenSupportEnabled
                settings.autoLoadIconsForPage: appSettings.autoLoadIconsForPage
                settings.touchIconsEnabled: appSettings.touchIconsEnabled
                settings.pdfViewerEnabled: appSettings.pdfViewerEnabled

                onCertificateError: function(error) {
                    error.defer();
                    sslDialog.enqueue(error);
                }

                onNewViewRequested: function(request) {
                    if (!request.userInitiated)
                        print("Warning: Blocked a popup window.");
                    else if (request.destination === WebEngineView.NewViewInTab)
                        currentWebView.url = request.requestedUrl
                    else if (request.destination === WebEngineView.NewViewInBackgroundTab) {
                        var backgroundTab = tabs.createEmptyTab(currentWebView.profile);
                        request.openIn(backgroundTab.item);
                    } else if (request.destination === WebEngineView.NewViewInDialog) {
                        /*var dialog = applicationRoot.createDialog(currentWebView.profile);
                        request.openIn(dialog.currentWebView);*/
                    } else {
                        /*var window = applicationRoot.createWindow(currentWebView.profile);
                        request.openIn(window.currentWebView);*/
                    }
                }

                onQuotaRequested: function(request) {
                    if (request.requestedSize <= 5 * 1024 * 1024)
                        request.accept();
                    else
                        request.reject();
                }

                onRegisterProtocolHandlerRequested: function(request) {
                    console.log("accepting registerProtocolHandler request for "
                                + request.scheme + " from " + request.origin);
                    request.accept();
                }

                onRenderProcessTerminated: function(terminationStatus, exitCode) {
                    var status = "";
                    switch (terminationStatus) {
                    case WebEngineView.NormalTerminationStatus:
                        status = "(normal exit)";
                        break;
                    case WebEngineView.AbnormalTerminationStatus:
                        status = "(abnormal exit)";
                        break;
                    case WebEngineView.CrashedTerminationStatus:
                        status = "(crashed)";
                        break;
                    case WebEngineView.KilledTerminationStatus:
                        status = "(killed)";
                        break;
                    }

                    print("Render process exited with code " + exitCode + " " + status);
                    reloadTimer.running = true;
                }

                onWindowCloseRequested: {
                    if (tabs.count === 1)
                        browserWindow.close();
                    else
                        tabs.removeTab(tabs.currentIndex);
                }

                onSelectClientCertificate: function(selection) {
                    selection.certificates[0].select();
                }

                /*onFindTextFinished: function(result) {
                    if (!findBar.visible)
                        findBar.visible = true;

                    findBar.numberOfMatches = result.numberOfMatches;
                    findBar.activeMatch = result.activeMatch;
                }*/

                /*onLoadingChanged: function(loadRequest) {
                    if (loadRequest.status === WebEngineView.LoadStartedStatus)
                        findBar.reset();
                }*/

                Timer {
                    id: reloadTimer
                    interval: 0
                    running: false
                    repeat: false
                    onTriggered: currentWebView.reload()
                }
            }
        }
    }
    WebEngineView {
        id: devToolsView
        visible: devToolsEnabled.checked
        height: visible ? 250 : 0
        inspectedView: visible && tabs.currentIndex < tabs.count ? tabs.getTab(tabs.currentIndex).item : null
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        onNewViewRequested: function(request) {
            var tab = tabs.createEmptyTab(currentWebView.profile);
            tabs.currentIndex = tabs.count - 1;
            request.openIn(tab.item);
        }
    }
    MessageDialog {
        id: sslDialog

        property var certErrors: []
        icon: StandardIcon.Warning
        standardButtons: StandardButton.No | StandardButton.Yes
        title: "Server's certificate not trusted"
        text: "Do you wish to continue?"
        detailedText: "If you wish so, you may continue with an unverified certificate. " +
                      "Accepting an unverified certificate means " +
                      "you may not be connected with the host you tried to connect to.\n" +
                      "Do you wish to override the security check and continue?"
        onYes: {
            certErrors.shift().ignoreCertificateError();
            presentError();
        }
        onNo: reject()
        onRejected: reject()

        function reject(){
            certErrors.shift().rejectCertificate();
            presentError();
        }
        function enqueue(error){
            certErrors.push(error);
            presentError();
        }
        function presentError(){
            visible = certErrors.length > 0
        }
    }

    /*DownloadView {
        id: downloadView
        visible: false
        anchors.fill: parent
    }

    function onDownloadRequested(download) {
        console.log("onDownloadRequested")
        downloadView.visible = true;
        downloadView.append(download);
        download.accept();
    }*/

    /*FindBar {
        id: findBar
        visible: false
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.top: parent.top

        onFindNext: {
            if (text)
                currentWebView && currentWebView.findText(text);
            else if (!visible)
                visible = true;
        }
        onFindPrevious: {
            if (text)
                currentWebView && currentWebView.findText(text, WebEngineView.FindBackward);
            else if (!visible)
                visible = true;
        }
    }*/
}
