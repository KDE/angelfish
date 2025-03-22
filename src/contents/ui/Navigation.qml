// SPDX-FileCopyrightText: 2014-2015 Sebastian Kügler <sebas@kde.org>
// SPDX-FileCopyrightText: 2021 Devin Lin <espidev@gmail.com>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Layouts 1.0
import QtWebEngine 1.4
import QtQuick.Controls 2.0 as Controls

import org.kde.kirigami as Kirigami
import org.kde.angelfish 1.0

Item {
    id: navigation

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
        anchors.left: navigation.left
        anchors.top: navigation.top
        anchors.bottom: navigation.bottom
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
        anchors.right: navigation.right
        anchors.top: navigation.top
        anchors.bottom: navigation.bottom
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

            if (navigation.height >= gestureThreshold) {
                tabsSheet.toggle()
            }
        }
    }

    NumberAnimation on height {
        id: yAnimator
        running: !tabDragHandler.active && dismissValue == 0
        duration: Kirigami.Units.longDuration
        easing.type: Easing.InOutQuad
        to: navigation.expandedHeight
    }
    
    Item {
        id: navContainer
        width: navigation.width
        height: navigation.height
        y: Math.max(Math.round((navigation.height - navigation.expandedHeight) / 10), 0)
        
        opacity: 1 - (Math.abs(navContainer.x) / (navigation.gestureThreshold * 2))

        // left/right gestures
        HapticsEffectLoader {
            id: vibrate
        }

        MouseArea {
            anchors.fill: parent
            enabled: navigation.dismissValue != 0
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
            enabled: !navigation.tabsSheet.showTabs && navigation.dismissValue == 0
            xAxis.minimum: currentWebView.canGoForward ? -navigation.gestureThreshold : 0
            xAxis.maximum: currentWebView.canGoBack ? navigation.gestureThreshold : 0
            onActiveChanged: {
                xAnimator.restart(); // go back to center

                if (parent.x >= navigation.gestureThreshold && currentWebView.canGoBack) {
                    currentWebView.goBack()
                } else if (parent.x <= -navigation.gestureThreshold && currentWebView.canGoForward) {
                    currentWebView.goForward()
                }
            }
        }
        NumberAnimation on x {
            id: xAnimator
            running: !dragHandler.active && navigation.dismissValue == 0
            duration: Kirigami.Units.longDuration
            easing.type: Easing.InOutQuad
            to: 0
        }
        onXChanged: {
            if ((x >= navigation.gestureThreshold && currentWebView.canGoBack) || (x <= -gestureThreshold && currentWebView.canGoForward)) {
                vibrate.start();
            }
        }

        // This lets us find the width of the url text label.
        // Needed for centering the url within the small navbar.
        Controls.Label {
            id: labelTextWidth
            text:  {
                if (labelItem.scheme === "http" || labelItem.scheme === "https") {
                    return UrlUtils.htmlFormattedUrl(currentWebView.requestedUrl)
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


            visible: !navigation.tabsSheet.showTabs

            spacing: Kirigami.Units.smallSpacing
            Kirigami.Theme.inherit: true
            
            Controls.ToolButton {
                id: mainMenuButton
                icon.name: rootPage.privateMode ? "view-private" : "application-menu"
                visible: webBrowser.landscape || Settings.navBarMainMenu
                opacity: navigation.dismissOpacity

                Layout.preferredWidth: navigation.buttonSize
                Layout.preferredHeight: navigation.buttonSize

                Kirigami.Theme.inherit: true

                enabled: navigation.dismissValue == 0
                onClicked: globalDrawer.open()
            }

            Controls.ToolButton {
                id: tabButton
                visible: webBrowser.landscape || Settings.navBarTabs
                opacity: navigation.dismissOpacity
                Layout.preferredWidth: navigation.buttonSize
                Layout.preferredHeight: navigation.buttonSize

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

                enabled: navigation.dismissValue == 0
                onClicked: navigation.tabsSheet.toggle()
            }

            Controls.ToolButton {
                id: backButton

                Layout.preferredWidth: navigation.buttonSize
                Layout.preferredHeight: navigation.buttonSize

                visible: currentWebView.canGoBack && Settings.navBarBack
                opacity: navigation.dismissOpacity
                icon.name: "go-previous"

                Kirigami.Theme.inherit: true

                enabled: navigation.dismissValue == 0
                onClicked: currentWebView.goBack()
                onPressAndHold: {
                    navigation.historySheet.backHistory = true;
                    navigation.historySheet.open();
                }
            }

            Controls.ToolButton {
                id: forwardButton

                Layout.preferredWidth: navigation.buttonSize
                Layout.preferredHeight: navigation.buttonSize

                visible: currentWebView.canGoForward && Settings.navBarForward
                opacity: navigation.dismissOpacity
                icon.name: "go-next"

                Kirigami.Theme.inherit: true

                enabled: navigation.dismissValue == 0
                onClicked: currentWebView.goForward()
                onPressAndHold: {
                    navigation.historySheet.backHistory = false;
                    navigation.historySheet.open();
                }
            }

            Controls.ToolButton {
                id: labelItem
                Layout.fillWidth: true
                Layout.preferredHeight: navigation.buttonSize

                Layout.leftMargin: {
                    let leftCenterMargin = ((mainMenuButton.visible + navigation.buttonSize)
                                            + (tabButton.visible * navigation.buttonSize)
                                            + (backButton.visible * navigation.buttonSize)
                                            + (forwardButton.visible * navigation.buttonSize)
                                            - navigation.buttonSize / 2) // Value need to center the url on the left
                    return Math.round(-leftCenterMargin * navigation.dismissValue)
                }
                Layout.rightMargin: {
                    let rightCenterMargin = ((reloadButton.visible * navigation.buttonSize)
                                             + (optionsButton.visible * navigation.buttonSize)
                                             - navigation.buttonSize / 2) // Value need to center the url on the right
                    return Math.round(-rightCenterMargin * navigation.dismissValue)
                }

                property string scheme: UrlUtils.urlScheme(currentWebView.requestedUrl)

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
                        width: visible ? Math.round(navigation.buttonSize * 0.5) : 0
                        Kirigami.Theme.inherit: true
                        enabled: navigation.dismissValue == 0
                        onClicked: navigation.activateUrlEntry()
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
                                return UrlUtils.htmlFormattedUrl(currentWebView.requestedUrl)
                            }
                            return currentWebView.requestedUrl;
                        }

                        textFormat: Text.StyledText
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                        Kirigami.Theme.inherit: true
                    }
                }


                enabled: navigation.dismissValue == 0
                onClicked: navigation.activateUrlEntry()
            }

            Controls.ToolButton {
                id: reloadButton

                Layout.preferredWidth: navigation.buttonSize
                Layout.preferredHeight: navigation.buttonSize

                visible: Settings.navBarReload
                opacity: navigation.dismissOpacity
                icon.name: currentWebView.loading ? "process-stop" : "view-refresh"

                Kirigami.Theme.inherit: true

                enabled: navigation.dismissValue == 0
                onClicked: currentWebView.loading ? currentWebView.stopLoading() : currentWebView.reload()

            }

            Controls.ToolButton {
                id: optionsButton

                property string targetState: "overview"

                Layout.fillWidth: false
                Layout.preferredWidth: navigation.buttonSize
                Layout.preferredHeight: navigation.buttonSize

                visible: webBrowser.landscape || Settings.navBarContextMenu
                opacity: navigation.dismissOpacity
                icon.name: "overflow-menu"

                Kirigami.Theme.inherit: true

                enabled: navigation.dismissValue == 0
                onClicked: contextDrawer.open()
            }
        }

        RowLayout {
            id: tabLayout
            anchors.fill: parent
            anchors.leftMargin: Kirigami.Units.gridUnit / 2
            anchors.rightMargin: Kirigami.Units.gridUnit / 2

            visible: navigation.tabsSheet.showTabs

            spacing: Kirigami.Units.smallSpacing
            Kirigami.Theme.inherit: true

            Controls.ToolButton {
                Layout.preferredWidth: navigation.buttonSize * 3
                Layout.preferredHeight: navigation.buttonSize

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

                onClicked: navigation.tabsSheet.toggle()
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
                Layout.preferredWidth: navigation.buttonSize * 3
                Layout.preferredHeight:  navigation.buttonSize

                icon.name: "list-add"
                text: i18nc("@action:inmenu", "New Tab")

                Kirigami.Theme.inherit: true

                onClicked: {
                    navigation.openNewTab()
                    navigation.activateUrlEntry()
                    navigation.tabsSheet.toggle()
                }
            }
        }
    }


    states: [
        State {
            name: "shown"
            when: navigationShown || tabLayout.visible
            PropertyChanges {
                target: navigation
                dismissValue: 0;
            }
        },
        State {
            name: "hidden"
            when: !navigationShown && !tabLayout.visible
            PropertyChanges {
                target: navigation
                dismissValue: 1;
            }
        }
    ]
    transitions: Transition {
        PropertyAnimation {
            properties: "dismissValue"; easing.type: Easing.OutCirc; duration: navigation.visible ? Kirigami.Units.longDuration : 0
        }
    }
}
