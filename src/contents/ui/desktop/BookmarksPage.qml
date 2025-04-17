//SPDX-FileCopyrightText: 2021 Felipe Kinoshita <kinofhek@gmail.com>
//SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Window

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.delegates as Delegates

import org.kde.angelfish
import org.kde.angelfish.core as Core

Kirigami.ScrollablePage {
    globalToolBarStyle: Kirigami.ApplicationHeaderStyle.None
    Kirigami.ColumnView.fillWidth: false

    header: QQC2.ToolBar {
        anchors.horizontalCenter: parent.horizontalCenter
        height: webBrowser.pageStack.globalToolBar.preferredHeight + 1 // to match tabs height
        width: parent.width

        RowLayout {
            anchors.fill: parent

            Kirigami.SearchField {
                id: search
                Layout.fillWidth: true

                placeholderText: i18nc("@info:placeholder", "Search bookmarks…")
                inputMethodHints: rootPage.privateMode ? Qt.ImhNoPredictiveText : Qt.ImhNone
                onAccepted: {
                    if (text === "" || text.length > 2) {
                        list.model.filter = displayText;
                    }
                }
                Keys.onEscapePressed: pageStack.pop()
            }
            QQC2.ToolButton {
                icon.name: "tab-close"
                onClicked: pageStack.pop()
            }
        }
    }

    ListView {
        id: list

        currentIndex: -1

        model: Core.BookmarksHistoryModel {
            history: false
            bookmarks: true
        }

        delegate: UrlDelegate {
            id: bookmarkDelegate
            title: model.title
            subtitle: model.url

            icon {
                name: model.iconName.length > 0 ? model.iconName : "internet-services"
                width: Kirigami.Units.largeSpacing * 3
                height: Kirigami.Units.largeSpacing * 3
            }

            onClicked: currentWebView.url = model.url
            onRemoved: BrowserManager.removeBookmark(model.url)
        }

        Kirigami.PlaceholderMessage {
            visible: list.count === 0
            anchors.centerIn: parent
            width: parent.width - Kirigami.Units.gridUnit * 4

            text: i18nc("@info:placeholder", "No bookmarks yet")
        }
    }

    Component.onCompleted: {
        Qt.callLater(() => {
            search.forceActiveFocus()
            search.selectAll()
        })
    }
}
