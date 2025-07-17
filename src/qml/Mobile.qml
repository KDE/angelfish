// SPDX-FileCopyrightText: 2014-2015 Sebastian Kügler <sebas@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtWebEngine
import QtQuick.Window
import Qt5Compat.GraphicalEffects
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.config as Config
import QtWebEngine

import org.kde.kirigami as Kirigami

import org.kde.angelfish
import org.kde.angelfish.core as Core
import org.kde.angelfish.settings

Kirigami.ApplicationWindow {
    id: webBrowser
    title: i18nc("@title:window", "Angelfish Web Browser")

    Shortcut {
        sequence: "Ctrl+W"
        onActivated: {
            tabs.tabsModel.closeTab(tabs.currentIndex);
        }
    }

    Shortcut {
        sequence: "Ctrl+Shift+O"
        onActivated: {
            if(pageStack.currentItem.objectName == "Bookmarks"){
                popSubPages();
            } else {
                pageStack.push(Qt.resolvedUrl("Bookmarks.qml"))
            }
        }
    }

    Config.WindowStateSaver {
        configGroupName: "mobile"
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

    // Used to determine if the window is in landscape mode
    property bool landscape: width > height

    onCurrentWebViewChanged: {
        print("Current WebView is now : " + tabs.currentIndex);
    }
    property int borderWidth: Math.round(Kirigami.Units.gridUnit / 18);
    property color borderColor: Kirigami.Theme.highlightColor;

    pageStack.globalToolBar.style: Kirigami.ApplicationHeaderStyle.ToolBar
    pageStack.globalToolBar.showNavigationButtons: Kirigami.ApplicationHeaderStyle.ShowBackButton
    pageStack.columnView.columnResizeMode: Kirigami.ColumnView.SingleColumn


    globalDrawer: Kirigami.GlobalDrawer {
        id: globalDrawer

        handleVisible: false

        actions: [
            Kirigami.Action {
                icon.name: "tab-duplicate"
                onTriggered: {
                    popSubPages();
                    tabsSheetLoader.toggle();
                }
                text: i18nc("@action:inmenu", "Tabs")
            },
            Kirigami.Action {
                icon.name: "view-private"
                onTriggered: {
                    rootPage.privateMode ? rootPage.privateMode = false : rootPage.privateMode = true
                }
                text: rootPage.privateMode ? i18nc("@action:inmenu", "Leave Private Mode") : i18nc("@action:inmenu", "Private Mode")
            },
            Kirigami.Action {
                icon.name: "bookmarks"
                onTriggered: {
                    popSubPages();
                    pageStack.push(Qt.resolvedUrl("Bookmarks.qml"))
                }
                text: i18nc("@action:inmenu", "Bookmarks")
            },
            Kirigami.Action {
                icon.name: "shallow-history"
                onTriggered: {
                    popSubPages();
                    pageStack.push(Qt.resolvedUrl("History.qml"))
                }
                text: i18nc("@action:inmenu", "History")
            },
            Kirigami.Action {
                icon.name: "download"
                text: i18nc("@action:inmenu", "Downloads")
                onTriggered: {
                    popSubPages();
                    pageStack.push(Qt.resolvedUrl("Downloads.qml"))
                }
            },
            Kirigami.Action {
                icon.name: "configure"
                text: i18nc("@action:inmenu", "Settings")
                onTriggered: {
                    popSubPages();
                    configurationView.open();
                }
            },
            Kirigami.Action {
                icon.name: "computer"
                text: i18nc("@action:inmenu", "Toggle Desktop Mode")
                onTriggered: {
                    InterfaceLoader.isMobile = !InterfaceLoader.isMobile;
                }
            }
        ]
    }

    AngelfishConfigurationView {
        id: configurationView
        window: webBrowser
    }

    contextDrawer: Kirigami.ContextDrawer {
        id: contextDrawer

        actions: pageStack.currentItem?.actions ?? []
        enabled: true

        handleVisible: false
    }

    // Main Page
    pageStack.initialPage: Kirigami.Page {
        id: rootPage
        title: currentWebView.title
        leftPadding: 0
        rightPadding: 0
        topPadding: 0
        bottomPadding: 0

        globalToolBarStyle: pageStack.layers.depth === 1 ? Kirigami.ApplicationHeaderStyle.None : Kirigami.ApplicationHeaderStyle.ToolBar
        Kirigami.ColumnView.fillWidth: true
        Kirigami.ColumnView.pinned: true
        Kirigami.ColumnView.preventStealing: true

        // Required to enforce active tab reload
        // on start. As a result, mixed isMobile
        // tabs will work correctly
        property bool initialized: false

        property bool privateMode: false

        property int navHeight: navigation.expandedHeight

        // Used for automatically show or hid navigation
        // bar. Set separately to combine with other options
        // for navigation bar management (webapp and others)
        property bool navigationAutoShow: true
        property bool navigationAutoShowLock: false

        property alias questionLoader: questionLoader
        property alias questions: questions

        Core.ListWebView {
            id: regularTabs
            objectName: "regularTabsObject"
            anchors.fill: parent
            activeTabs: rootPage.initialized && !rootPage.privateMode
            bottomOffset: navigation.visible ? navigation.dismissHeight : 0
        }

        Core.ListWebView {
            id: privateTabs
            anchors.fill: parent
            activeTabs: rootPage.initialized && rootPage.privateMode
            privateTabsMode: true
            bottomOffset: navigation.visible ? navigation.dismissHeight : 0
        }

        Controls.ScrollBar {
            visible: true
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            position: currentWebView.scrollPosition.y / currentWebView.contentsSize.height
            orientation: Qt.Vertical
            size: currentWebView.height / currentWebView.contentsSize.height
            interactive: false
        }

        Core.ErrorHandler {
            id: errorHandler

            errorString: currentWebView.errorString
            errorCode: currentWebView.errorCode

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                bottom: navigation.top
            }
            visible: currentWebView && currentWebView.errorDomain !== null
                     && currentWebView.errorDomain !== WebEngineLoadingInfo.HttpStatusCodeDomain

            onRefreshRequested: currentWebView.reload()
            onCertificateIgnored: {
                visible = Qt.binding(() => {
                    return currentWebView.errorCode !== "";
                })
            }

            function enqueue(error){
                errorString = error.description;
                errorCode = error.error;
                errorHandler.open(error);
            }
        }

        Loader {
            id: questionLoader

            Component.onCompleted: {
                if (AdblockUrlInterceptor.adblockSupported && AdblockUrlInterceptor.downloadNeeded) {
                    questionLoader.setSource("AdblockFilterDownloadQuestion.qml")
                }
            }

            anchors.bottom: navigation.top
            anchors.left: parent.left
            anchors.right: parent.right
        }

        Core.Questions {
            id: questions

            anchors.bottom: navigation.top
            anchors.left: parent.left
            anchors.right: parent.right
        }

        // Container for the progress bar
        Item {
            id: progressItem

            height: Math.round(Kirigami.Units.gridUnit / 6)
            z: navigation.z + 1
            anchors {
                bottom: findInPage.active ? findInPage.top : navigation.top
                bottomMargin: -Math.round(height / 2)
                left: tabs.left
                right: tabs.right
            }

            opacity: currentWebView.loading ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Kirigami.Units.longDuration; easing.type: Easing.InOutQuad; } }

            Rectangle {
                color: Kirigami.Theme.highlightColor

                width: Math.round(((currentWebView ? currentWebView.loadProgress : 0) / 100) * parent.width)
                anchors {
                    top: parent.top
                    left: parent.left
                    bottom: parent.bottom
                }
            }
        }

        Loader {
            id: sheetLoader
        }

        // Unload the ShareSheet again after it closed
        Connections {
            target: sheetLoader.item
            function onVisibleChanged() {
                if (!sheetLoader.item.visible) {
                    sheetLoader.source = ""
                }
            }
        }

        Core.UrlObserver {
            id: urlObserver
            url: currentWebView.url
        }

        WebAppCreator {
            id: webAppCreator
            websiteName: currentWebView.title
        }

        // The menu at the bottom right
        actions: [
            Kirigami.Action {
                icon.name: "edit-find"
                shortcut: "Ctrl+F"
                onTriggered: findInPage.activate()
                text: i18nc("@action:inmenu", "Find in Page")
            },
            Kirigami.Action {
                icon.name: "document-share"
                text: i18nc("@action:inmenu", "Share Page")
                onTriggered: {
                    sheetLoader.setSource("ShareSheet.qml")
                    sheetLoader.item.url = currentWebView.url
                    sheetLoader.item.inputTitle = currentWebView.title
                    sheetLoader.item.open()
                }
            },
            Kirigami.Action {
                id: addHomeScreenAction
                icon.name: "list-add"
                text: i18nc("@action:inmenu", "Add to Homescreen")
                enabled: !webAppCreator.exists
                onTriggered: {
                    webAppCreator.createDesktopFile(currentWebView.title,
                                                           currentWebView.url,
                                                           currentWebView.icon)
                }
            },
            Kirigami.Action {
                icon.name: "application-x-object"
                text: i18nc("@action:inmenu", "Open in App")
                onTriggered: {
                    Qt.openUrlExternally(currentWebView.url)
                }
            },
            Kirigami.Action {
                enabled: currentWebView.canGoBack
                icon.name: "go-previous"
                text: i18nc("@action:inmenu", "Go Back")
                onTriggered: {
                    currentWebView.goBack()
                }
            },
            Kirigami.Action {
                enabled: currentWebView.canGoForward
                icon.name: "go-next"
                text: i18nc("@action:inmenu", "Go Forward")
                onTriggered: {
                    currentWebView.goForward()
                }
            },
            Kirigami.Action {
                icon.name: currentWebView.loading ? "process-stop" : "view-refresh"
                text: currentWebView.loading ? i18nc("@action:inmenu", "Stop Loading") : i18nc("@action:inmenu", "Refresh")
                onTriggered: {
                    currentWebView.loading ? currentWebView.stopLoading() : currentWebView.reload()
                }
            },
            Kirigami.Action {
                id: bookmarkAction
                checkable: true
                checked: urlObserver.bookmarked
                icon.name: "bookmarks"
                text: checked ? i18nc("@info:status", "Bookmarked") : i18nc("@action:inmenu", "Bookmark")
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
            },
            Kirigami.Action {
                icon.name: "computer"
                text: i18nc("@action:inmenu", "Show Desktop Site")
                checkable: true
                checked: !currentWebView.userAgent.isMobile
                onTriggered: {
                    currentWebView.userAgent.isMobile = !currentWebView.userAgent.isMobile;
                }
            },
            Kirigami.Action {
                icon.name: currentWebView.readerMode ? "view-readermode-active" : "view-readermode"
                text: i18nc("@action:inmenu", "Reader Mode")
                checkable: true
                checked: currentWebView.readerMode
                onTriggered: currentWebView.readerModeSwitch()

            },
            Kirigami.Action {
                icon.name: "edit-select-text"
                text: i18nc("@action:inmenu", "Hide Navigation Bar")
                visible: navigation.visible
                onTriggered: {
                    if (!navigation.visible) return;
                    rootPage.navigationAutoShowLock = true
                }
            },
            Kirigami.Action {
                icon.name: "dialog-scripts"
                text: i18nc("@action:inmenu", "Show Developer Tools")
                checkable: true
                checked: tabs.itemAt(tabs.currentIndex).isDeveloperToolsOpen
                onTriggered: {
                    tabs.tabsModel.toggleDeveloperTools(tabs.currentIndex)
                }
            }
        ]

        // Tabs sheet
        Loader {
            id: tabsSheetLoader
            active: false
            property bool showTabs: false
            function toggle() {
                if (active == false) {
                    active = true;
                    showTabs = true;
                } else if (showTabs == true) {
                    item.openTab()
                    showTabs = false;
                }
            }
            function close() {
                active = false;
                showTabs = false;
            }
            sourceComponent: Tabs {
                 tabsSheet: tabsSheetLoader
                 sheet: sheetLoader
            }
        }

        // Find bar
        FindInPageBar {
            id: findInPage
            Kirigami.Theme.colorSet: rootPage.privateMode ? Kirigami.Theme.Complementary : Kirigami.Theme.Window
        }

        // Bottom navigation bar
        Navigation {
            id: navigation

            anchors {
                bottom: parent.bottom
                left: parent.left
                right: parent.right
            }

            navigationShown: visible && rootPage.navigationAutoShow && !rootPage.navigationAutoShowLock
            visible: webBrowser.visibility !== Window.FullScreen && !findInPage.active

            tabsSheet: tabsSheetLoader
            historySheet: historySheet

            Kirigami.Theme.inherit: false
            Kirigami.Theme.colorSet: rootPage.privateMode ? Kirigami.Theme.Complementary : Kirigami.Theme.Window

            onActivateUrlEntry: urlEntry.open()
            onOpenNewTab: {
                webBrowser.tabs.tabsModel.newTab("about:blank")
                webBrowser.tabs.tabsModel.setLatestTab()
            }
        }

        NavigationEntrySheet {
            id: urlEntry
        }

        HistorySheet {
            id: historySheet
        }

        // Thin line above navigation or find
        Rectangle {
            height: webBrowser.borderWidth
            color: webBrowser.borderColor
            anchors {
                left: parent.left
                bottom: findInPage.active ? findInPage.top : navigation.top
                right: parent.right
            }
            visible: navigation.navigationShown || findInPage.active
        }

        // dealing with hiding and showing navigation bar
        property point oldScrollPosition: Qt.point(0, 0)
        property bool  pageAlmostReady: !currentWebView.loading || currentWebView.loadProgress > 90

        onPageAlmostReadyChanged: {
            if (!rootPage.pageAlmostReady)
                rootPage.navigationAutoShow = true;
            else
                rootPage.oldScrollPosition = currentWebView.scrollPosition;
        }

        Connections {
            target: currentWebView
            function onScrollPositionChanged() {
                var delta = 100;
                if (rootPage.navigationAutoShow && rootPage.pageAlmostReady) {
                    if (rootPage.oldScrollPosition.y + delta < currentWebView.scrollPosition.y) {
                        // hide navbar
                        rootPage.oldScrollPosition = currentWebView.scrollPosition;
                        rootPage.navigationAutoShow = false;
                    } else if (rootPage.oldScrollPosition.y > currentWebView.scrollPosition.y) {
                        // navbar open and scrolling up
                        rootPage.oldScrollPosition = currentWebView.scrollPosition;
                    }
                } else if (!rootPage.navigationAutoShow) {
                    if (rootPage.oldScrollPosition.y - delta > currentWebView.scrollPosition.y) {
                        // show navbar
                        rootPage.oldScrollPosition = currentWebView.scrollPosition;
                        rootPage.navigationAutoShow = true;
                    } else if (rootPage.oldScrollPosition.y < currentWebView.scrollPosition.y) {
                        // navbar closed and scrolling down
                        rootPage.oldScrollPosition = currentWebView.scrollPosition;
                    }
                }
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
