
// SPDX-FileCopyrightText: 2021 Felipe Kinoshita <kinofhek@gmail.com>
//
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Window
import QtWebEngine

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.delegates as Delegates

import Qt5Compat.GraphicalEffects

import org.kde.config as Config
import org.kde.angelfish
import org.kde.angelfish.core as Core
import org.kde.angelfish.settings as AngelfishSettings
import org.kde.kirigamiaddons.labs.components 1.0 as Addons
import "RegexWebUrl.js" as RegexWebUrl

Kirigami.ApplicationWindow {
    id: webBrowser

    title: currentWebView.title + " — Angelfish"

    minimumWidth: Kirigami.Units.gridUnit * 20
    minimumHeight: Kirigami.Units.gridUnit * 10

    Config.WindowStateSaver {
        configGroupName: "desktop"
    }

    /** Pointer to the currently active view.
     *
     * Browser-level functionality should use this to refer to the current
     * view, rather than looking up views in the mode, as far as possible.
     */
    property Core.WebView currentWebView: tabs.currentItem

    // Pointer to the currently active list of tabs.
    //
    // As there are private and normal tabs, switch between
    // them according to the current mode.
    property Core.ListWebView tabs: rootPage.privateMode ? privateTabs : regularTabs

    // Hides headers, toolbars and other controls when enabled
    property bool fullscreenMode: false

    AngelfishSettings.AngelfishConfigurationView {
        id: configurationView
        window: webBrowser
    }

    TabHistory {
        id: historyMenu
    }

    header: QQC2.ToolBar {
        id: toolbar

        visible: webBrowser.fullscreenMode || webBrowser.visibility === Window.FullScreen ? false : true

        RowLayout {
            anchors.fill: parent

            QQC2.ToolButton {
                id: backButton
                Layout.alignment: Qt.AlignLeft
                action: Kirigami.Action {
                    enabled: currentWebView.canGoBack
                    icon.name: "go-previous"
                    shortcut: StandardKey.Back
                    onTriggered: currentWebView.goBack()
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton
                    onClicked: {
                        if (currentWebView.canGoBack) {
                            historyMenu.showBackHistory()
                        }
                    }
                }
            }

            QQC2.ToolButton {
                id: forwardButton
                Layout.alignment: Qt.AlignLeft
                action: Kirigami.Action {
                    enabled: currentWebView.canGoForward
                    icon.name: "go-next"
                    shortcut: StandardKey.Forward
                    onTriggered: currentWebView.goForward()
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton
                    onClicked: {
                        if (currentWebView.canGoForward) {
                            historyMenu.showForwardHistory()
                        }
                    }
                }
            }

            QQC2.ToolButton {
                id: refreshButton
                Layout.alignment: Qt.AlignLeft
                action: Kirigami.Action {
                    icon.name: currentWebView.loading ? "process-stop" : "view-refresh"
                    onTriggered: {
                        if (currentWebView.loading) {
                            currentWebView.stop();
                        } else {
                            currentWebView.reload();
                        }
                    }
                }

                Shortcut {
                    sequences: [StandardKey.Refresh, "Ctrl+R"]
                    onActivated: refreshButton.action.trigger()
                }
            }

            QQC2.ToolButton {
                visible: Core.AngelfishSettings.showHomeButton
                Layout.alignment: Qt.AlignLeft
                action: Kirigami.Action {
                    icon.name: "go-home"
                    onTriggered: currentWebView.url = Core.AngelfishSettings.homepage
                }
            }

            Item {
                Layout.fillWidth: true
            }
            Addons.SearchPopupField {
                id: urlBar
                spaceAvailableLeft: true
                spaceAvailableRight: true
                Layout.fillWidth: true
                Layout.maximumWidth: 800
                autoAccept: false
                popup.width: width
                searchField.text: currentWebView.url
                searchField.placeholderText: i18nc("@info:placeholder", "Search or enter URL…")
                searchField.color: searchField.activeFocus ? Kirigami.Theme.textColor : Kirigami.Theme.disabledTextColor
                onAccepted: {
                    let url = text;
                    if (url.indexOf(":/") < 0) {
                        url = "http://" + url;
                    }

                    if (validURL(url)) {
                        currentWebView.url = url;
                    } else {
                        currentWebView.url = Core.UrlUtils.urlFromUserInput(Core.AngelfishSettings.searchBaseUrl + searchField.text);
                    }
                    urlBar.popup.close()
                }
                onTextChanged: {
                    if (searchField.text === "" || searchField.text.length > 2) {
                        historyList.model.filter = searchField.displayText;
                    }
                }
                searchField.onActiveFocusChanged: {
                    if (searchField.activeFocus) {
                        searchField.selectAll()
                    }
                }

                function validURL(str) {
                    return searchField.text.match(RegexWebUrl.re_weburl) || searchField.text.startsWith("chrome://")
                }

                searchField.focusSequence: "Ctrl+L"

                Item {
                    Kirigami.Action {
                        id: bookmarkButton

                        visible: !urlBar.searchField.activeFocus
                        icon.name: checked ? "rating" : "rating-unrated"
                        checkable: true
                        checked: urlObserver.bookmarked
                        onTriggered: {
                            if (checked) {
                                var request = {
                                    url: currentWebView.url,
                                    title: currentWebView.title,
                                    icon: currentWebView.icon
                                }
                                Core.BrowserManager.addBookmark(request);
                            } else {
                                Core.BrowserManager.removeBookmark(currentWebView.url);
                            }
                        }
                    }

                    Shortcut {
                        sequence: "Ctrl+D"
                        onActivated: bookmarkButton.action.trigger()
                    }
                }

                Component.onCompleted: {
                    searchField.rightActions[0] = bookmarkButton;
                }

                ColumnLayout {
                    anchors.fill: parent

                    QQC2.ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        clip: true


                        QQC2.ScrollBar.horizontal.visible: false

                        ListView {
                            id: historyList

                            currentIndex: -1
                            model: Core.BookmarksHistoryModel {
                                history: true
                                bookmarks: false
                                active: urlBar.popup.opened
                            }

                            delegate: Delegates.RoundedItemDelegate {
                                id: bookmarkDelegate

                                required property int index
                                required property string title
                                required property string url
                                required property string iconName

                                text: title

                                icon {
                                    name: iconName.length > 0 ? iconName : "internet-services"
                                    width: Kirigami.Units.largeSpacing * 3
                                    height: Kirigami.Units.largeSpacing * 3
                                }

                                onClicked: {
                                    currentWebView.url = bookmarkDelegate.url;
                                    urlBar.popup.close()
                                }

                                contentItem: Delegates.SubtitleContentItem {
                                    itemDelegate: bookmarkDelegate
                                    subtitle: bookmarkDelegate.url
                                    labelItem.textFormat: Text.PlainText
                                }
                            }
                        }
                    }
                }
            }


            Item {
                Layout.fillWidth: true
            }

            QQC2.Menu {
                id: menu

                Kirigami.Action {
                    text: i18nc("@action:inmenu", "New Tab")
                    icon.name: "list-add"
                    shortcut: "Ctrl+T"
                    onTriggered: tabs.tabsModel.newTab(Core.AngelfishSettings.newTabUrl)
                }

                Kirigami.Action { // TODO: should ideally open up a new window in private mode
                    text: rootPage.privateMode ? i18nc("@action:inmenu", "Leave Private Mode") : i18nc("@action:inmenu", "Private Mode")
                    icon.name: "view-private"
                    shortcut: "Ctrl+Shift+P"
                    onTriggered: rootPage.privateMode = !rootPage.privateMode
                }

                QQC2.MenuSeparator {}

                Kirigami.Action {
                    text: i18nc("@action:inmenu", "History")
                    icon.name: "view-history"
                    shortcut: "Ctrl+H"
                    onTriggered: {
                        popSubPages();
                        webBrowser.pageStack.push(Qt.resolvedUrl("HistoryPage.qml"));
                    }
                }
                Kirigami.Action {
                    text: i18nc("@action:inmenu", "Bookmarks")
                    icon.name: "bookmarks"
                    shortcut: "Ctrl+Shift+O"
                    onTriggered: {
                        if(webBrowser.pageStack.currentItem.objectName == "BookmarksPage"){
                            popSubPages();
                        } else {
                            webBrowser.pageStack.push(Qt.resolvedUrl("BookmarksPage.qml"))
                        }
                    }
                }
                Kirigami.Action {
                    text: i18nc("@action:inmenu", "Downloads")
                    icon.name: "download"
                    shortcut: "Ctrl+J"
                    onTriggered: {
                        popSubPages();
                        webBrowser.pageStack.push(Qt.resolvedUrl("Downloads.qml"))
                    }
                }

                QQC2.MenuSeparator {}

                Kirigami.Action {
                    icon.name: "document-print"
                    text: i18nc("@action:inmenu", "Print")
                    shortcut: "Ctrl+P"
                    onTriggered: currentWebView.printRequested()
                }

                Kirigami.Action {
                    text: i18nc("@action:inmenu", "Full Screen")
                    icon.name: "view-fullscreen"
                    shortcut: "F11"
                    onTriggered: {
                        if (webBrowser.fullscreenMode) {
                            webBrowser.showNormal();
                        } else {
                            webBrowser.showFullScreen();
                        }

                        webBrowser.fullscreenMode = !webBrowser.fullscreenMode
                    }
                }

                Kirigami.Action {
                    icon.name: "dialog-scripts"
                    text: tabs.itemAt(tabs.currentIndex) && tabs.itemAt(tabs.currentIndex).isDeveloperToolsOpen
                        ? i18nc("@action:inmenu", "Hide Developer Tools")
                        : i18nc("@action:inmenu", "Show Developer Tools")
                    shortcut: "F12"
                    onTriggered: tabs.tabsModel.toggleDeveloperTools(tabs.currentIndex)
                }

                Kirigami.Action {
                    icon.name: "edit-find"
                    shortcut: "Ctrl+F"
                    onTriggered: findInPage.activate()
                    text: i18nc("@action:inmenu", "Find in Page")
                }

                Kirigami.Action {
                    checkable: true
                    checked: currentWebView.readerMode
                    icon.name: currentWebView.readerMode ? "view-readermode-active" : "view-readermode"
                    shortcut: "Ctrl+Shift+R"
                    onTriggered: currentWebView.readerModeSwitch()
                    text: i18nc("@action:inmenu", "Reader Mode")
                }

                QQC2.MenuSeparator {}

                Kirigami.Action {
                    icon.name: "document-share"
                    text: i18nc("@action:inmenu", "Share Page")
                    onTriggered: {
                        sheetLoader.setSource("ShareSheet.qml")
                        sheetLoader.item.url = currentWebView.url
                        sheetLoader.item.inputTitle = currentWebView.title
                        Qt.callLater(sheetLoader.item.open)
                    }
                }

                Kirigami.Action {
                    text: i18nc("@action:inmenu", "Add to Application Launcher")
                    icon.name: "install"
                    enabled: !webAppCreator.exists

                    property WebAppCreator webAppCreator: WebAppCreator {
                        id: webAppCreator
                        websiteName: currentWebView.title
                    }

                    onTriggered: {
                        webAppCreator.createDesktopFile(currentWebView.title,
                                                        currentWebView.url,
                                                        currentWebView.icon)
                    }
                }

                QQC2.MenuSeparator {}

                Kirigami.Action {
                    text: i18nc("@action:inmenu", "Settings")
                    icon.name: "settings-configure"
                    shortcut: "Ctrl+Shift+,"
                    onTriggered: {
                        configurationView.open();
                    }
                }

                Kirigami.Action {
                    icon.name: "phone"
                    text: i18nc("@action:inmenu", "Toggle Mobile Mode")
                    onTriggered: {
                        InterfaceLoader.isMobile = !InterfaceLoader.isMobile;
                    }
                }

            }
            Item{
                //spacer to make the UrlBar centered
                Layout.fillHeight: true
                width: menuButton.width
            }
            Item{
                Layout.fillHeight: true
                width: menuButton.width
                Kirigami.Icon{
                    anchors.centerIn:parent
                    source: "view-private"
                    visible: rootPage.privateMode
                    implicitHeight: Kirigami.Units.gridUnit*1.2
                }
            }
            QQC2.ToolButton {
                id: menuButton
                Layout.alignment: Qt.AlignRight
                icon.name: "application-menu"
                down: menu.visible
                onPressed: menu.visible ? menu.close() : menu.popup(menuButton, menuButton.x, menuButton.y + menuButton.height)
            }
        }
    }

    pageStack.initialPage: Kirigami.Page {
        id: rootPage
        leftPadding: 0
        rightPadding: 0
        topPadding: 0
        bottomPadding: 0
        globalToolBarStyle: Kirigami.ApplicationHeaderStyle.None
        Kirigami.ColumnView.fillWidth: true
        Kirigami.ColumnView.pinned: true
        Kirigami.ColumnView.preventStealing: true

        // Required to enforce active tab reload
        // on start. As a result, mixed isMobile
        // tabs will work correctly
        property bool initialized: false

        property bool privateMode: false

        property alias questionLoader: questionLoader
        property alias questions: questions

        header: Loader {
            id: tabsLoader

            visible: {
                if (webBrowser.fullscreenMode || webBrowser.visibility === Window.FullScreen) {
                    return false;
                } else {
                    return true;
                }
            }
            height: visible ? implicitHeight : 0

            Kirigami.Separator {
                anchors.top: tabsLoader.item.bottom
                anchors.right: parent.right
                anchors.left: parent.left
            }

            source: Qt.resolvedUrl("DesktopTabs.qml")
        }

        Core.ListWebView {
            id: regularTabs
            objectName: "regularTabsObject"
            anchors.fill: parent
            activeTabs: rootPage.initialized && !rootPage.privateMode
        }

        Core.ListWebView {
            id: privateTabs
            anchors.fill: parent
            activeTabs: rootPage.initialized && rootPage.privateMode
            privateTabsMode: true
        }

        Core.ErrorHandler {
            id: errorHandler

            errorString: currentWebView.errorString
            errorCode: currentWebView.errorCode

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            visible: currentWebView.errorDomain !== null
                     && currentWebView.errorDomain !== WebEngineLoadingInfo.HttpStatusCodeDomain

            onRefreshRequested: currentWebView.reload()

            function enqueue(error){
                errorString = error.description;
                errorCode = error.error;
                errorHandler.open(error);
            }
        }

        Loader {
            id: sheetLoader
        }

        // Unload the ShareSheet again after it closed
        Connections {
            target: sheetLoader.item
            function onOpened() {
                if (!sheetLoader.item.opened) {
                    sheetLoader.source = ""
                }
            }
        }

        Loader {
            id: questionLoader

            Component.onCompleted: {
                if (AdblockUrlInterceptor.adblockSupported
                        && AdblockUrlInterceptor.downloadNeeded
                        && !Core.AngelfishSettings.adblockFilterDownloadDismissed) {
                    questionLoader.setSource("AdblockFilterDownloadQuestion.qml")
                }
            }

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
        }

        Core.Questions {
            id: questions

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
        }

        // Find bar
        FindInPageBar {
            id: findInPage

            Kirigami.Theme.colorSet: rootPage.privateMode ? Kirigami.Theme.Complementary : Kirigami.Theme.Window

            layer.enabled: GraphicsInfo.api !== GraphicsInfo.Software && active
            layer.effect: DropShadow {
                verticalOffset: - 1
                color: Kirigami.Theme.disabledTextColor
                samples: 10
                spread: 0.1
                cached: true // element is static
            }
        }

        // Container for the progress bar
        Item {
            id: progressItem

            height: Math.round(Kirigami.Units.gridUnit / 6)
            z: header.z + 1
            anchors {
                top: parent.top
                left: tabs.left
                right: tabs.right
            }

            opacity: currentWebView.loading ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Kirigami.Units.longDuration; easing.type: Easing.InOutQuad; } }

            Rectangle {
                color: Kirigami.Theme.highlightColor

                width: Math.round((currentWebView.loadProgress / 100) * parent.width)
                anchors {
                    top: parent.top
                    left: parent.left
                    bottom: parent.bottom
                }
            }
        }

        Core.UrlObserver {
            id: urlObserver
            url: currentWebView.url
        }
    }

    MouseArea {
        anchors.fill: parent

        acceptedButtons: Qt.ForwardButton | Qt.BackButton

        onClicked: {
            if (mouse.button === Qt.ForwardButton && forwardButton.action.enabled) {
                forwardButton.action.trigger();
            } else if (mouse.button === Qt.BackButton && backButton.action.enabled) {
                backButton.action.trigger();
            }
        }
    }

    Connections {
        target: webBrowser.pageStack
        function onCurrentIndexChanged() {
            // drop all sub pages as soon as the browser window is the
            // focussed one
            if (webBrowser.pageStack.currentIndex === 0)
                popSubPages();
        }
    }

    // Store window dimensions
    Component.onCompleted: {
        rootPage.initialized = true
    }

    function popSubPages() {
        while (webBrowser.pageStack.depth > 1)
            webBrowser.pageStack.pop();
    }
}
