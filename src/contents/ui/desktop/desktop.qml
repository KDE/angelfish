//SPDX-FileCopyrightText: 2021 Felipe Kinoshita <kinofhek@gmail.com>
//SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Window 2.15
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.19 as Kirigami

import org.kde.angelfish 1.0

Kirigami.ApplicationWindow {
    id: webBrowser

    title: currentWebView.title + " ― Angelfish"

    minimumWidth: Kirigami.Units.gridUnit * 40
    minimumHeight: Kirigami.Units.gridUnit * 20
    width: Kirigami.Units.gridUnit * 80
    height: Kirigami.Units.gridUnit * 50

    /** Pointer to the currently active view.
     *
     * Browser-level functionality should use this to refer to the current
     * view, rather than looking up views in the mode, as far as possible.
     */
    property WebView currentWebView: tabs.currentItem

    // Pointer to the currently active list of tabs.
    //
    // As there are private and normal tabs, switch between
    // them according to the current mode.
    property ListWebView tabs: rootPage.privateMode ? privateTabs : regularTabs

    header: QQC2.ToolBar {
        id: toolbar

        visible: webBrowser.visibility === Window.FullScreen ? false : true

        RowLayout {
            anchors.fill: parent

            QQC2.ToolButton {
                Layout.alignment: Qt.AlignLeft
                action: Kirigami.Action {
                    enabled: currentWebView.canGoBack
                    icon.name: "go-previous"
                    shortcut: StandardKey.Back
                    onTriggered: currentWebView.goBack()
                }
            }

            QQC2.ToolButton {
                Layout.alignment: Qt.AlignLeft
                action: Kirigami.Action {
                    enabled: currentWebView.canGoForward
                    icon.name: "go-next"
                    shortcut: StandardKey.Forward
                    onTriggered: currentWebView.goForward()
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
                visible: Settings.showHomeButton
                Layout.alignment: Qt.AlignLeft
                action: Kirigami.Action {
                    icon.name: "go-home"
                    onTriggered: currentWebView.url = Settings.homepage
                }
            }

            Item {
                Layout.fillWidth: true
            }

            QQC2.TextField {
                id: urlBar
                Layout.fillWidth: true
                Layout.maximumWidth: 1000
                text: currentWebView.url
                onAccepted: {
                    let url = text;
                    if (url.indexOf(":/") < 0) {
                        url = "http://" + url;
                    }

                    if (validURL(url)) {
                        currentWebView.url = url;
                    } else {
                        currentWebView.url = UrlUtils.urlFromUserInput(Settings.searchBaseUrl + text);
                    }

                    focus = false;
                }
                color: activeFocus ? Kirigami.Theme.textColor : Kirigami.Theme.disabledTextColor

                onActiveFocusChanged: {
                    if (activeFocus) {
                        urlBar.selectAll();
                    }
                }

                function validURL(str) {
                    var pattern = new RegExp('^(https?:\\/\\/)?'+ // protocol
                        '((([a-z\\d]([a-z\\d-]*[a-z\\d])*)\\.)+[a-z]{2,}|'+ // domain name
                        '((\\d{1,3}\\.){3}\\d{1,3}))'+ // OR ip (v4) address
                        '(\\:\\d+)?(\\/[-a-z\\d%_.~+]*)*'+ // port and path
                        '(\\?[;&a-z\\d%_.~+=-]*)?'+ // query string
                        '(\\#[-a-z\\d_]*)?$','i'); // fragment locator
                    return !!pattern.test(str);
                }

                QQC2.ToolButton {
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right

                    action: Kirigami.Action {
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
                                BrowserManager.addBookmark(request);
                            } else {
                                BrowserManager.removeBookmark(currentWebView.url);
                            }
                        }
                    }
                }

                Shortcut {
                    sequence: "Ctrl+L"
                    onActivated: {
                        urlBar.forceActiveFocus();
                    }
                }
            }

            Item {
                Layout.fillWidth: true
            }

            QQC2.ToolButton {
                Layout.alignment: Qt.AlignRight
                action: Kirigami.Action {
                    icon.name: "list-add"
                    shortcut: "Ctrl+T"
                    onTriggered: tabs.tabsModel.newTab(Settings.newTabUrl)
                }
            }

            QQC2.Menu {
                id: menu

                Kirigami.Action {
                    text: i18n("New Tab")
                    icon.name: "list-add"
                    shortcut: "Ctrl+T"
                    onTriggered: tabs.tabsModel.newTab(Settings.newTabUrl)
                }

                QQC2.MenuSeparator {}

                Kirigami.Action {
                    text: i18n("History")
                    icon.name: "view-history"
                    shortcut: "Ctrl+H"
                    onTriggered: {
                        popSubPages();
                        webBrowser.pageStack.push(Qt.resolvedUrl("HistoryPage.qml"));
                    }
                }
                Kirigami.Action {
                    text: i18n("Bookmarks")
                    icon.name: "bookmarks"
                    shortcut: "Ctrl+Shift+O"
                    onTriggered: {
                        popSubPages();
                        webBrowser.pageStack.push(Qt.resolvedUrl("BookmarksPage.qml"))
                    }
                }

                QQC2.MenuSeparator {}

                Kirigami.Action {
                    text: i18n("Full Screen")
                    icon.name: "view-fullscreen"
                    shortcut: "F11"
                    onTriggered: {
                        if (webBrowser.visibility !== Window.FullScreen) {
                            webBrowser.showFullScreen();
                        } else {
                            webBrowser.showNormal();
                        }
                    }
                }

                QQC2.MenuSeparator {}

                Kirigami.Action {
                    text: i18n("Settings")
                    icon.name: "settings-configure"
                    shortcut: "Ctrl+Shift+,"
                    onTriggered: {
                        const openDialogWindow = pageStack.pushDialogLayer("qrc:/DesktopSettingsPage.qml", {
                            width: webBrowser.width
                        }, {
                            title: i18n("Configure Angelfish"),
                            width: Kirigami.Units.gridUnit * 45,
                            height: Kirigami.Units.gridUnit * 35
                        });
                        openDialogWindow.Keys.escapePressed.connect(function() { openDialogWindow.closeDialog() });
                    }
                }
            }

            QQC2.ToolButton {
                id: menuButton
                Layout.alignment: Qt.AlignRight
                icon.name: "application-menu"
                checked: menu.opened
                onClicked: menu.popup(menuButton.x, menuButton.y + menuButton.height, webBrowser)
                onDoubleClicked: menu.popup(menuButton.x, menuButton.y + menuButton.height, webBrowser)
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

        header: Loader {
            id: tabsLoader

            visible: {
                if (webBrowser.visibility === Window.FullScreen) {
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

        ListWebView {
            id: regularTabs
            objectName: "regularTabsObject"
            anchors.fill: parent
            activeTabs: rootPage.initialized && !rootPage.privateMode
        }

        ListWebView {
            id: privateTabs
            anchors.fill: parent
            activeTabs: rootPage.initialized && rootPage.privateMode
            privateTabsMode: true
        }

        ErrorHandler {
            id: errorHandler

            errorString: currentWebView.errorString
            errorCode: currentWebView.errorCode

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            visible: currentWebView.errorCode !== ""

            onRefreshRequested: currentWebView.reload()
            onCertificateIgnored: {
                visible = Qt.binding(() => {
                    return currentWebView.errorCode !== "";
                })
            }

            function enqueue(error){
                errorString = error.description;
                errorCode = error.error;
                visible = true;
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

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
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

        UrlObserver {
            id: urlObserver
            url: currentWebView.url
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
