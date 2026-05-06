// SPDX-FileCopyrightText: 2014-2015 Sebastian Kügler <sebas@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

import org.kde.kirigami as Kirigami
import org.kde.angelfish
import org.kde.angelfish.core as Core

Kirigami.ScrollablePage {
    title: i18nc("@title:window", "Bookmarks")
    objectName: "Bookmarks"
    Kirigami.ColumnView.fillWidth: false

    actions: [
        Kirigami.Action {
            visible: !InterfaceLoader.isMobile
            icon.name: "tab-close"

            onTriggered: pageStack.pop()
            tooltip: i18nc("@info:tooltip", "Close")
        }
    ]

    header: QQC2.ToolBar {
        anchors.horizontalCenter: parent.horizontalCenter
        height: Kirigami.Units.gridUnit * 3
        width: list.width

        Kirigami.SearchField {
            id: search
            anchors.centerIn: parent
            width: parent.width - Kirigami.Units.gridUnit

            clip: true
            inputMethodHints: rootPage.privateMode ? Qt.ImhNoPredictiveText : Qt.ImhNone

            onDisplayTextChanged: {
                if (displayText === "" || displayText.length > 2) {
                    list.model.filter = displayText;
                    timer.running = false;
                }
                else timer.running = true;
            }

            Timer {
                id: timer
                repeat: false
                interval: Math.max(1000, 3000 - search.displayText.length * 1000)
                onTriggered: list.model.filter = search.displayText
            }
        }
    }

    Component {
        id: delegateComponent

        UrlDelegate {
            highlightText: list.model.filter
            title: model.title
            subtitle: model.url

            icon {
                name: "image://favicon/" + model.url
                width: Kirigami.Units.largeSpacing * 3
                height: Kirigami.Units.largeSpacing * 3
            }

            onClicked: {
                currentWebView.url = model.url;
                pageStack.pop();
            }
            onMiddleClicked: tabs.tabsModel.newTab(model.url);
            onRemoved: Core.BrowserManager.removeBookmark(model.url);
        }
    }

    ListView {
        id: list
        anchors.fill: parent

        interactive: height < contentHeight
        clip: true

        model: Core.BookmarksHistoryModel {
            bookmarks: true
        }

        reuseItems: true
        delegate: delegateComponent
    }

    Component.onCompleted: {
        if (!InterfaceLoader.isMobile) {
            Qt.callLater(() => {
                search.forceActiveFocus()
                search.selectAll()
            })
        }
    }
    Keys.onEscapePressed: pageStack.pop()
}
