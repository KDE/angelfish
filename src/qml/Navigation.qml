// SPDX-FileCopyrightText: 2014-2015 Sebastian Kügler <sebas@kde.org>
// SPDX-FileCopyrightText: 2021 Devin Lin <espidev@gmail.com>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Layouts
import QtWebEngine
import QtQuick.Controls as Controls
import QtQuick.Templates as T

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard
import org.kde.angelfish
import org.kde.angelfish.core as Core

Item {
    id: root

    required property Core.WebView currentWebView
    required property FindInPageBar findInPage

    property double dismissValue: 0 // Value between 1 and 0 animating the dismiss state of the navbar. 0 is full, 1 is dismissed.
    property double dismissOpacity: Math.max(1 - (dismissValue * 2), 0)
    // The web view lags a bit when resizing, so this rounds the value.
    property int dismissHeight: expandedHeight * (1 - Math.round(dismissValue) * 0.6)

    height: {
        let progress = Math.max(-tabDragHandler.yAxis.activeValue, 0) / expandedHeight;
        let effectProgress = Math.atan(progress);
        return (expandedHeight + effectProgress * expandedHeight) * (1 - dismissValue * 0.6)
    }

    property bool navigationShown: true

    property int expandedHeight: Kirigami.Units.gridUnit * 3
    property int buttonSize: Kirigami.Units.gridUnit * 2
    property int gestureThreshold: expandedHeight * 2
    
    required property var tabsSheet
    required property HistorySheet historySheet
    
    signal activateUrlEntry
    signal openNewTab

    Rectangle { anchors.fill: parent; color: Kirigami.Theme.backgroundColor; }

    // left/right gesture icons
    Kirigami.Icon {
        id: leftGestureIcon
        anchors.margins: Kirigami.Units.gridUnit
        anchors.left: root.left
        anchors.top: root.top
        anchors.bottom: root.bottom
        implicitWidth: height
        
        opacity: Math.abs(navContainer.x) / gestureThreshold
        source: "arrow-left"
        transform: Scale {
            origin.x: leftGestureIcon.implicitWidth / 2
            origin.y: leftGestureIcon.implicitWidth / 2
            xScale: Math.max(0, navContainer.x / gestureThreshold)
            yScale: Math.max(0, navContainer.x / gestureThreshold)
        }
    }


    Kirigami.Icon {
        id: rightGestureIcon
        anchors.margins: Kirigami.Units.gridUnit
        anchors.right: root.right
        anchors.top: root.top
        anchors.bottom: root.bottom
        implicitWidth: height
        
        opacity: Math.abs(navContainer.x) / gestureThreshold
        source: "arrow-right"
        transform: Scale {
            origin.x: rightGestureIcon.implicitWidth / 2
            origin.y: rightGestureIcon.implicitWidth / 2
            xScale: Math.max(0, -navContainer.x / gestureThreshold)
            yScale: Math.max(0, -navContainer.x / gestureThreshold)
        }
    }

    DragHandler {
        id: tabDragHandler
        target: null
        yAxis.enabled: true
        xAxis.enabled: false
        enabled: dismissValue == 0
        onActiveChanged: {
            yAnimator.restart(); // go back to center

            if (root.height >= gestureThreshold) {
                tabsSheet.toggle()
            }
        }
    }

    NumberAnimation on height {
        id: yAnimator
        running: !tabDragHandler.active && dismissValue == 0
        duration: Kirigami.Units.longDuration
        easing.type: Easing.InOutQuad
        to: root.expandedHeight
    }
    
    Item {
        id: navContainer
        width: root.width
        height: root.height
        y: Math.max(Math.round((root.height - root.expandedHeight) / 10), 0)
        
        opacity: 1 - (Math.abs(navContainer.x) / (root.gestureThreshold * 2))

        // left/right gestures
        HapticsEffectLoader {
            id: vibrate
        }

        MouseArea {
            anchors.fill: parent
            enabled: root.dismissValue != 0
            onClicked: {
                rootPage.navigationAutoShow = true;
                rootPage.navigationAutoShowLock = false;
            }
        }

        DragHandler {
            id: dragHandler
            target: parent
            yAxis.enabled: false
            xAxis.enabled: true
            enabled: !root.tabsSheet.showTabs && root.dismissValue == 0
            xAxis.minimum: currentWebView.canGoForward ? -root.gestureThreshold : 0
            xAxis.maximum: currentWebView.canGoBack ? root.gestureThreshold : 0
            onActiveChanged: {
                xAnimator.restart(); // go back to center

                if (parent.x >= root.gestureThreshold && currentWebView.canGoBack) {
                    currentWebView.goBack()
                } else if (parent.x <= -root.gestureThreshold && currentWebView.canGoForward) {
                    currentWebView.goForward()
                }
            }
        }
        NumberAnimation on x {
            id: xAnimator
            running: !dragHandler.active && root.dismissValue == 0
            duration: Kirigami.Units.longDuration
            easing.type: Easing.InOutQuad
            to: 0
        }
        onXChanged: {
            if ((x >= root.gestureThreshold && currentWebView.canGoBack) || (x <= -gestureThreshold && currentWebView.canGoForward)) {
                vibrate.start();
            }
        }

        // This lets us find the width of the url text label.
        // Needed for centering the url within the small navbar.
        Controls.Label {
            id: labelTextWidth
            text:  {
                if (labelItem.scheme === "http" || labelItem.scheme === "https") {
                    return Core.UrlUtils.htmlFormattedUrl(currentWebView.requestedUrl)
                }
                return currentWebView.requestedUrl;
            }
            textFormat: Text.StyledText
            Kirigami.Theme.inherit: true
            visible: false
        }


        RowLayout {
            id: layout
            anchors.leftMargin: Kirigami.Units.gridUnit / 2
            anchors.rightMargin: Kirigami.Units.gridUnit / 2
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.right: parent.right


            visible: !root.tabsSheet.showTabs

            spacing: Kirigami.Units.smallSpacing
            Kirigami.Theme.inherit: true

            Controls.ToolButton {
                id: tabButton
                visible: webBrowser.landscape || Core.AngelfishSettings.navBarTabs
                opacity: root.dismissOpacity
                Layout.preferredWidth: root.buttonSize
                Layout.preferredHeight: root.buttonSize

                Rectangle {
                    anchors.centerIn: parent
                    height: Kirigami.Units.gridUnit * 1.25
                    width: Kirigami.Units.gridUnit * 1.25

                    color: "transparent"
                    border.color: Kirigami.Theme.textColor
                    border.width: Kirigami.Units.gridUnit / 10
                    radius: Kirigami.Units.gridUnit / 5

                    Kirigami.Theme.inherit: true

                    Controls.Label {
                        anchors.centerIn: parent
                        height: Kirigami.Units.gridUnit
                        width: Kirigami.Units.gridUnit
                        fontSizeMode: Text.Fit
                        minimumPixelSize: 0
                        minimumPointSize: 0
                        clip: true
                        text: "%1".arg(tabs.count)
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        Kirigami.Theme.inherit: true
                    }
                }

                enabled: root.dismissValue == 0
                onClicked: root.tabsSheet.toggle()
            }

            Controls.ToolButton {
                id: backButton

                Layout.preferredWidth: root.buttonSize
                Layout.preferredHeight: root.buttonSize

                visible: currentWebView.canGoBack && Core.AngelfishSettings.navBarBack
                opacity: root.dismissOpacity
                icon.name: "go-previous"

                Kirigami.Theme.inherit: true

                enabled: root.dismissValue == 0
                onClicked: currentWebView.goBack()
                onPressAndHold: {
                    root.historySheet.backHistory = true;
                    root.historySheet.open();
                }
            }

            Controls.ToolButton {
                id: forwardButton

                Layout.preferredWidth: root.buttonSize
                Layout.preferredHeight: root.buttonSize

                visible: currentWebView.canGoForward && Core.AngelfishSettings.navBarForward
                opacity: root.dismissOpacity
                icon.name: "go-next"

                Kirigami.Theme.inherit: true

                enabled: root.dismissValue == 0
                onClicked: currentWebView.goForward()
                onPressAndHold: {
                    root.historySheet.backHistory = false;
                    root.historySheet.open();
                }
            }

            Controls.ToolButton {
                id: labelItem
                Layout.fillWidth: true
                Layout.preferredHeight: root.buttonSize

                Layout.leftMargin: {
                    let leftCenterMargin = ((mainMenuButton.visible + root.buttonSize)
                                            + (tabButton.visible * root.buttonSize)
                                            + (backButton.visible * root.buttonSize)
                                            + (forwardButton.visible * root.buttonSize)
                                            - root.buttonSize / 2) // Value need to center the url on the left
                    return Math.round(-leftCenterMargin * root.dismissValue)
                }
                Layout.rightMargin: {
                    let rightCenterMargin = ((reloadButton.visible * root.buttonSize)
                                             + (optionsButton.visible * root.buttonSize)
                                             - root.buttonSize / 2) // Value need to center the url on the right
                    return Math.round(-rightCenterMargin * root.dismissValue)
                }

                property string scheme: Core.UrlUtils.urlScheme(currentWebView.requestedUrl)

                Row {
                    id: urlBar
                    anchors {
                        horizontalCenter: labelItem.horizontalCenter
                        verticalCenter: labelItem.verticalCenter
                    }
                    height: labelItem.height
                    width: Math.round(childrenRect.width)

                    Controls.ToolButton {
                        id: schemeIcon
                        icon.name: {
                            if (labelItem.scheme === "https") return "lock";
                            if (labelItem.scheme === "http") return "unlock";
                            return "";
                        }
                        visible: icon.name
                        height: parent.height
                        width: visible ? Math.round(root.buttonSize * 0.5) : 0
                        Kirigami.Theme.inherit: true
                        enabled: root.dismissValue == 0
                        onClicked: root.activateUrlEntry()
                    }


                    Controls.Label {
                        id: labelText
                        width: {
                            let widthDiff = (labelItem.width - schemeIcon.width)
                            let widthFull = Math.round(labelTextWidth.contentWidth + schemeIcon.width / 2) // Full width of the url label
                            let widthFullAn = (1 - ((1 - (Math.min(widthDiff, widthFull) / widthDiff)) * dismissValue))
                            return Math.round(widthDiff * widthFullAn) // Multiply widthDiff by widthFullAn to fill the width of the navbar when dismissed.
                        }
                        height: parent.height

                        text:  {
                            if (labelItem.scheme === "http" || labelItem.scheme === "https") {
                                return Core.UrlUtils.htmlFormattedUrl(currentWebView.requestedUrl)
                            }
                            return currentWebView.requestedUrl;
                        }

                        textFormat: Text.StyledText
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                        Kirigami.Theme.inherit: true
                    }
                }


                enabled: root.dismissValue == 0
                onClicked: root.activateUrlEntry()
            }

            Controls.ToolButton {
                id: reloadButton

                Layout.preferredWidth: root.buttonSize
                Layout.preferredHeight: root.buttonSize

                visible: Core.AngelfishSettings.navBarReload
                opacity: root.dismissOpacity
                icon.name: currentWebView.loading ? "process-stop" : "view-refresh"

                Kirigami.Theme.inherit: true

                enabled: root.dismissValue == 0
                onClicked: currentWebView.loading ? currentWebView.stopLoading() : currentWebView.reload()

            }

            Controls.ToolButton {
                id: optionsButton

                property string targetState: "overview"

                Layout.fillWidth: false
                Layout.preferredWidth: root.buttonSize
                Layout.preferredHeight: root.buttonSize

                visible: webBrowser.landscape || Core.AngelfishSettings.navBarContextMenu
                opacity: root.dismissOpacity
                icon.name: "overflow-menu"

                Kirigami.Theme.inherit: true

                enabled: root.dismissValue == 0
                onClicked: pageMenu.open()
                hoverEnabled: true

                AngelfishMenu {
                    id: pageMenu

                    parent: root.Controls.Overlay.overlay

                    Binding {
                        pageMenu.x: root.Controls.Overlay.overlay.width - pageMenu.width - Kirigami.Units.largeSpacing
                        pageMenu.y: root.Controls.Overlay.overlay.height - pageMenu.height - Kirigami.Units.largeSpacing
                    }

                    FormCard.FormButtonDelegate {
                        icon.name: "view-private"
                        trailingLogo.visible: false
                        onClicked: {
                            rootPage.privateMode ? rootPage.privateMode = false : rootPage.privateMode = true
                            pageMenu.close()
                        }
                        text: rootPage.privateMode ? i18nc("@action:inmenu", "Leave Private Mode") : i18nc("@action:inmenu", "Private Mode")
                    }

                    FormCard.FormButtonDelegate {
                        icon.name: "bookmarks"
                        trailingLogo.visible: false
                        onClicked: {
                            popSubPages();
                            pageStack.push(Qt.resolvedUrl("Bookmarks.qml"))
                            pageMenu.close()
                        }
                        text: i18nc("@action:inmenu", "Bookmarks")
                    }

                    FormCard.FormButtonDelegate {
                        icon.name: "shallow-history"
                        trailingLogo.visible: false
                        onClicked: {
                            popSubPages();
                            pageStack.push(Qt.resolvedUrl("History.qml"))
                            pageMenu.close()
                        }
                        text: i18nc("@action:inmenu", "History")
                    }

                    FormCard.FormButtonDelegate {
                        icon.name: "download"
                        text: i18nc("@action:inmenu", "Downloads")
                        trailingLogo.visible: false
                        onClicked: {
                            popSubPages();
                            pageStack.push(Qt.resolvedUrl("Downloads.qml"))
                            pageMenu.close()
                        }
                    }

                    FormCard.FormButtonDelegate {
                        icon.name: "configure"
                        text: i18nc("@action:inmenu", "Settings")
                        trailingLogo.visible: false
                        onClicked: {
                            popSubPages();
                            configurationView.open();
                        }
                    }

                    FormCard.FormDelegateSeparator {}

                    FormCard.FormButtonDelegate {
                        action: Controls.Action {
                            icon.name: "edit-find"
                            shortcut: "Ctrl+F"
                            onTriggered: {
                                findInPage.activate()
                                pageMenu.close();
                            }
                            text: i18nc("@action:inmenu", "Find in Page")
                        }
                        trailingLogo.visible: false
                    }

                    FormCard.FormButtonDelegate {
                        id: addHomeScreenAction

                        icon.name: "list-add"
                        text: i18nc("@action:inmenu", "Add to Homescreen")
                        enabled: !webAppCreator.exists
                        trailingLogo.visible: false
                        onClicked: {
                            webAppCreator.createDesktopFile(currentWebView.title, currentWebView.url, currentWebView.icon);
                            pageMenu.close();
                        }
                    }

                    FormCard.FormButtonDelegate {
                        icon.name: "application-x-object"
                        text: i18nc("@action:inmenu", "Open in App")
                        onClicked: {
                            Qt.openUrlExternally(currentWebView.url)
                            pageMenu.close();
                        }
                        trailingLogo.visible: false
                    }

                    FormCard.FormButtonDelegate {
                        id: bookmarkAction

                        checkable: true
                        checked: urlObserver.bookmarked
                        icon.name: checked ? "bookmark-remove-symbolic" : "bookmarks"
                        text: checked ? i18nc("@info:status", "Bookmarked") : i18nc("@action:inmenu", "Bookmark")
                        trailingLogo.visible: false
                        onToggled: if (checked) {
                            var request = {
                                url: currentWebView.url,
                                title: currentWebView.title,
                                icon: currentWebView.icon
                            }
                            Core.BrowserManager.addBookmark(request);
                            pageMenu.close();
                        } else {
                            Core.BrowserManager.removeBookmark(currentWebView.url);
                            pageMenu.close();
                        }
                    }

                    FormCard.FormSwitchDelegate {
                        icon.name: checked ? "phone-symbolic" : "computer-symbolic"
                        text: checked ? i18nc("@action:inmenu", "Show Mobile Site") : i18nc("@action:inmenu", "Show Desktop Site")
                        checkable: true
                        checked: !root.currentWebView.userAgent.isMobile
                        onToggled: {
                            root.currentWebView.userAgent.isMobile = !root.currentWebView.userAgent.isMobile;
                            pageMenu.close();
                        }
                    }

                    FormCard.FormButtonDelegate {
                        icon.name: currentWebView.readerMode ? "view-readermode-active" : "view-readermode"
                        text: i18nc("@action:inmenu", "Reader Mode")
                        checkable: true
                        checked: currentWebView.readerMode
                        onToggled: {
                            root.currentWebView.readerModeSwitch()
                            pageMenu.close();
                        }
                        trailingLogo.visible: false
                    }

                    FormCard.FormButtonDelegate {
                        visible: root.visible
                        icon.name: "edit-select-text"
                        text: i18nc("@action:inmenu", "Hide Navigation Bar")
                        onClicked: {
                            rootPage.navigationAutoShowLock = true
                            pageMenu.close();
                        }
                        trailingLogo.visible: false
                    }

                    FormCard.FormButtonDelegate {
                        id: showDeveloperTools
                        icon.name: "dialog-scripts"
                        text: i18nc("@action:inmenu", "Show Developer Tools")
                        checkable: true
                        trailingLogo.visible: false
                        onToggled: {
                            tabs.tabsModel.toggleDeveloperTools(tabs.currentIndex);
                            pageMenu.close();
                        }

                        Binding {
                            showDeveloperTools.checked: tabs.itemAt(tabs.currentIndex).isDeveloperToolsOpen
                        }
                    }

                    FormCard.FormButtonDelegate {
                        icon.name: "computer"
                        text: i18nc("@action:inmenu", "Toggle Desktop Mode")
                        trailingLogo.visible: false
                        onClicked: {
                            InterfaceLoader.isMobile = !InterfaceLoader.isMobile;
                        }
                    }

                    footerContent: [
                        FormCard.FormButtonDelegate {
                            enabled: root.currentWebView.canGoBack
                            icon.name: "go-previous"
                            trailingLogo.visible: false
                            onClicked: {
                                root.currentWebView.goBack();
                                pageMenu.close();
                            }
                            Accessible.name: i18nc("@action:inmenu", "Go Back")
                        },
                        FormCard.FormButtonDelegate {
                            enabled: root.currentWebView.canGoForward
                            icon.name: "go-next"
                            trailingLogo.visible: false
                            onClicked: {
                                root.currentWebView.goForward();
                                pageMenu.close();
                            }

                            Accessible.name: i18nc("@action:inmenu", "Go Forward")
                        },
                        FormCard.FormButtonDelegate {
                            icon.name: root.currentWebView.loading ? "process-stop" : "view-refresh"
                            trailingLogo.visible: false
                            onClicked: {
                                root.currentWebView.loading ? root.currentWebView.stopLoading() : root.currentWebView.reload();
                                pageMenu.close();
                            }

                            Accessible.name: root.currentWebView.loading ? i18nc("@action:inmenu", "Stop Loading") : i18nc("@action:inmenu", "Refresh")
                        },
                        FormCard.FormButtonDelegate {
                            icon.name: "document-share"
                            trailingLogo.visible: false

                            onClicked: {
                                sheetLoader.setSource("ShareSheet.qml")
                                sheetLoader.item.url = currentWebView.url
                                sheetLoader.item.inputTitle = currentWebView.title
                                sheetLoader.item.open()
                                pageMenu.close();
                            }

                            Accessible.name: i18nc("@action:inmenu", "Share Page")
                        }
                    ]
                }
            }
        }

        RowLayout {
            id: tabLayout
            anchors.fill: parent
            anchors.leftMargin: Kirigami.Units.gridUnit / 2
            anchors.rightMargin: Kirigami.Units.gridUnit / 2

            visible: root.tabsSheet.showTabs

            spacing: Kirigami.Units.smallSpacing
            Kirigami.Theme.inherit: true

            Controls.ToolButton {
                Layout.preferredWidth: root.buttonSize * 3
                Layout.preferredHeight: root.buttonSize

                Controls.Label {
                    anchors.centerIn: parent
                    height: Kirigami.Units.gridUnit
                    width: Kirigami.Units.gridUnit * 3
                    fontSizeMode: Text.Fit
                    minimumPixelSize: 0
                    minimumPointSize: 0
                    clip: true
                    text: i18nc("@action:intoolbar", "Done")
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    Kirigami.Theme.inherit: true
                }

                onClicked: root.tabsSheet.toggle()
            }

            Controls.Label {
                Layout.fillWidth: true
                minimumPixelSize: 0
                minimumPointSize: 0
                text: i18nc("@info:status", "%1 tabs", tabs.count)
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                Kirigami.Theme.inherit: true
            }

            Controls.ToolButton {
                id: newTab

                Layout.fillWidth: false
                Layout.preferredWidth: root.buttonSize * 3
                Layout.preferredHeight:  root.buttonSize

                icon.name: "list-add"
                text: i18nc("@action:inmenu", "New Tab")

                Kirigami.Theme.inherit: true

                onClicked: {
                    root.openNewTab()
                    root.activateUrlEntry()
                    root.tabsSheet.toggle()
                }
            }
        }
    }

    states: [
        State {
            name: "shown"
            when: navigationShown || tabLayout.visible
            PropertyChanges {
                target: root
                dismissValue: 0;
            }
        },
        State {
            name: "hidden"
            when: !navigationShown && !tabLayout.visible
            PropertyChanges {
                target: root
                dismissValue: 1;
            }
        }
    ]
    transitions: Transition {
        PropertyAnimation {
            properties: "dismissValue"; easing.type: Easing.OutCirc; duration: root.visible ? Kirigami.Units.longDuration : 0
        }
    }
}
