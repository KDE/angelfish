// SPDX-FileCopyrightText: 2014-2015 Sebastian Kügler <sebas@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.3
import QtQuick.Controls 2.15
import QtQml.Models 2.1
import QtWebEngine 1.10

import org.kde.kirigami 2.7 as Kirigami
import org.kde.angelfish 1.0


Repeater {
    id: tabs
    clip: true

    property bool activeTabs: false
    property bool privateTabsMode: false

    property alias currentIndex: tabsModel.currentTab
    property WebView currentItem

    property alias tabsModel: tabsModel

    property WebEngineProfile profile: AngelfishWebProfile {
        httpUserAgent: tabs.currentItem.userAgent.userAgent
        offTheRecord: tabs.privateTabsMode
        storageName: tabs.privateTabsMode ? "Private" : Settings.profile

        questionLoader: rootPage.questionLoader
        urlInterceptor: typeof AdblockUrlInterceptor !== "undefined" && AdblockUrlInterceptor
    }

    model: TabsModel {
        id: tabsModel
        isMobileDefault: Kirigami.Settings.isMobile
        privateMode: privateTabsMode
    }

    delegate: SplitView {
        id: tabDelegate

        required property bool isMobile
        required property url pageurl
        required property bool isDeveloperToolsOpen

        required property int index

        anchors.fill: parent
        orientation: Qt.Vertical

        property bool readyForSnapshot: false
        property bool showView: index === tabs.currentIndex
        property bool isVisible: (showView || readyForSnapshot || pageWebView.loadingActive) && tabs.activeTabs
        property alias title: pageWebView.title
        property alias icon: pageWebView.icon
        property alias readerMode: pageWebView.readerMode
        property alias readerTitle: pageWebView.readerTitle

        onShowViewChanged: {
            if (showView) {
                tabs.currentItem = pageWebView
            }
        }
        x: showView && tabs.activeTabs ? 0 : -width
        z: showView && tabs.activeTabs ? 0 : -1
        visible: isVisible

        Item {
            SplitView.minimumHeight: 100
            WebView {
                id: pageWebView
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

        Item {
            SplitView.minimumHeight: 100
            visible: tabDelegate.isDeveloperToolsOpen

            Loader {
                id: developerToolsLoader
                anchors.fill: parent

                onLoaded: {
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
