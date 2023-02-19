// SPDX-FileCopyrightText: 2014-2015 Sebastian Kügler <sebas@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQml.Models 2.15
import QtWebEngine 1.10

import org.kde.kirigami 2.19 as Kirigami

import org.kde.angelfish 1.0

Repeater {
    id: tabs

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

    delegate: QQC2.SplitView {
        id: tabDelegate

        required property bool isMobile
        required property url pageurl
        required property bool isDeveloperToolsOpen

        required property int index

        anchors.fill: parent
        orientation: width < height ? Qt.Vertical : Qt.Horizontal

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
            QQC2.SplitView.minimumWidth: 25
            QQC2.SplitView.minimumHeight: 25
            QQC2.SplitView.fillWidth: true
            QQC2.SplitView.fillHeight: true

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
            QQC2.SplitView.minimumWidth: 75
            QQC2.SplitView.minimumHeight: 27 // height of the developer tools menu
            QQC2.SplitView.preferredWidth: 500
            QQC2.SplitView.preferredHeight: 200
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
