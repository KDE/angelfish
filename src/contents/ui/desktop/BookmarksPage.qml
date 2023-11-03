//SPDX-FileCopyrightText: 2021 Felipe Kinoshita <kinofhek@gmail.com>
//SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Window 2.15
import QtQuick.Layouts 1.15
import org.kde.kirigami as Kirigami

import org.kde.angelfish 1.0

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

                placeholderText: i18n("Search bookmarks…")
                inputMethodHints: rootPage.privateMode ? Qt.ImhNoPredictiveText : Qt.ImhNone
                onAccepted: {
                    if (text === "" || text.length > 2) {
                        list.model.filter = displayText;
                    }
                }
                Keys.onEscapePressed: pageStack.pop()
                Component.onCompleted: search.forceActiveFocus()
            }
            QQC2.ToolButton {
                icon.name: "tab-close"
                onClicked: pageStack.pop()
            }
        }
    }

    ListView {
        id: list
        anchors.fill: parent

        currentIndex: -1
        model: BookmarksHistoryModel {
            history: false
            bookmarks: true
        }

        delegate: QQC2.ItemDelegate {
            id: delegate

            text: model.title
            width: ListView.view.width
            onClicked: currentWebView.url = model.url

            contentItem: RowLayout {
                Kirigami.TitleSubtitle {
                    title: delegate.text
                    subtitle: model.url

                    Layout.fillWidth: true
                }
                QQC2.ToolButton {
                    icon.name: "entry-delete"
                    onClicked: BrowserManager.removeBookmark(model.url)
                }
            }
        }

        Kirigami.PlaceholderMessage {
            visible: list.count === 0
            anchors.centerIn: parent

            text: i18n("No bookmarks yet")
        }
    }
}
