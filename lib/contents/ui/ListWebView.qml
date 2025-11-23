// SPDX-FileCopyrightText: 2014-2015 Sebastian Kügler <sebas@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQml.Models
import QtWebEngine

import org.kde.kirigami as Kirigami

import org.kde.angelfish
import org.kde.angelfish.core as Core

Repeater {
    id: tabs

    property bool activeTabs: false
    property bool privateTabsMode: false

    property alias currentIndex: tabsModel.currentTab
    property WebView currentItem

    property alias tabsModel: tabsModel

    property int bottomOffset: 0

    property WebEngineProfile profile: Core.AngelfishWebProfile {
        httpUserAgent: tabs.currentItem.userAgent.userAgent
        offTheRecord: tabs.privateTabsMode
        storageName: tabs.privateTabsMode ? "Private" : Core.AngelfishSettings.profile

        questionLoader: rootPage.questionLoader
        urlInterceptor: typeof AdblockUrlInterceptor !== "undefined" && AdblockUrlInterceptor
    }

    model: Core.TabsModel {
        id: tabsModel
        isMobileDefault: Kirigami.Settings.isMobile
        privateMode: privateTabsMode
    }

    delegate: QQC2.SplitView {
        id: tabDelegate

        required property bool isMobile
        required property url pageurl
        required property bool isDeveloperToolsOpen

        required property int index

        width: parent.width
        height: parent.height - bottomOffset
        orientation: width < height ? Qt.Vertical : Qt.Horizontal

        property bool readyForSnapshot: false
        property bool showView: index === tabs.currentIndex
        property bool isVisible: (showView || readyForSnapshot || pageWebView.loadingActive) && tabs.activeTabs
        property alias pageWebView: pageWebViewLoader.item
        property string title: pageWebView ? pageWebView.title : i18nc("@title:webview", "Loading")
        property var icon: pageWebView ? pageWebView.icon : null
        property bool readerMode: pageWebView && pageWebView.readerMode
        property string readerTitle: pageWebView ? pageWebView.readerTitle : i18nc("@title:webview", "Loading")

        onShowViewChanged: {
            if (showView) {
                tabs.currentItem = Qt.binding(() => pageWebViewLoader.item)
            }
        }
        x: showView && tabs.activeTabs ? 0 : -width
        z: showView && tabs.activeTabs ? 0 : -1
        visible: isVisible

        Item {
            QQC2.SplitView.minimumWidth: 25
            QQC2.SplitView.minimumHeight: 25
            QQC2.SplitView.fillWidth: true
            QQC2.SplitView.fillHeight: true

            Loader {
                id: pageWebViewLoader
                anchors.fill: parent

                active: true
                asynchronous: true

                sourceComponent: WebView {
                    anchors.fill: parent
                    visible: isVisible

                    privateMode: tabs.privateTabsMode
                    userAgent.isMobile: tabDelegate.isMobile
                    width: tabs.width

                    profile: tabs.profile

                    Component.onCompleted: {
                        url = tabDelegate.pageurl
                    }

                    onRequestedUrlChanged: tabsModel.setUrl(index, requestedUrl)

                    Connections {
                        target: pageWebView.userAgent
                        function onUserAgentChanged() {
                            tabsModel.setIsMobile(index, pageWebView.userAgent.isMobile);
                        }
                    }
                }
            }

            Rectangle {
                color: Kirigami.Theme.backgroundColor
                anchors.fill: parent

                visible: pageWebViewLoader.status !== Loader.Ready

                QQC2.BusyIndicator {
                    anchors.centerIn: parent
                    running: pageWebViewLoader.status === Loader.Loading
                }
            }
        }

        Item {
            QQC2.SplitView.minimumWidth: 75
            QQC2.SplitView.minimumHeight: 27 // height of the developer tools menu
            QQC2.SplitView.preferredWidth: 500
            QQC2.SplitView.preferredHeight: 200
            visible: tabDelegate.isDeveloperToolsOpen

            // Prevent other tab content from showing through while loading
            Rectangle { anchors.fill: parent; color: Kirigami.Theme.backgroundColor }

            Loader {
                id: developerToolsLoader
                anchors.fill: parent
                active: showView || viewed

                property bool viewed: false

                onLoaded: {
                    viewed = true
                    item.inspectedView = pageWebView;
                }

                Connections {
                    target: developerToolsLoader.item

                    function onWindowCloseRequested() {
                        tabsModel.toggleDeveloperTools(tabDelegate.index)
                    }
                }

                Connections {
                    target: tabsModel
                    function onDataChanged(left, right, roles) {
                        if (tabsModel.isDeveloperToolsOpen(tabDelegate.index)) {
                            developerToolsLoader.setSource("WebDeveloperTools.qml");
                        } else {
                            developerToolsLoader.setSource("")
                        }
                    }
                }
            }
        }
    }
}
