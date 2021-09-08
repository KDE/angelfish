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
        anchors.fill: parent
        orientation: Qt.Vertical

        property bool readyForSnapshot: false
        property bool showView: index === tabs.currentIndex
        property bool isVisible: (showView || readyForSnapshot || pageWebView.loadingActive) && tabs.activeTabs
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
                userAgent.isMobile: model.isMobile
                width: tabs.width

                profile: tabs.profile

                Component.onCompleted: {
                    url = model.pageurl
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
            visible: model.isDeveloperToolsOpen

            Loader {
                id: developerToolsLoader
                anchors.fill: parent

                onLoaded: {
                    item.inspectedView = pageWebView;
                }

                Connections {
                    target: tabsModel
                    onDataChanged: {
                        if (model.isDeveloperToolsOpen) {
                            developerToolsLoader.setSource("WebDeveloperTools.qml");
                        }
                    }
                }
            }
        }
    }
}
