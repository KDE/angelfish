//SPDX-FileCopyrightText: 2021 Felipe Kinoshita <kinofhek@gmail.com>
//SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Window

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.delegates as Delegates

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

                placeholderText: i18n("Search history…")
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
                icon.name: "edit-clear-all"
                onClicked: BrowserManager.clearHistory()

                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                QQC2.ToolTip.text: i18n("Clear all history")
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

        model: BookmarksHistoryModel {
            history: true
            bookmarks: false
        }

        delegate: Delegates.RoundedItemDelegate {
            id: bookmarkDelegate

            required property int index
            required property string title
            required property string url
            required property string iconName

            text: title

            icon {
                name: iconName.length > 0 ? iconName : "internet-services"
                width: Kirigami.Units.largeSpacing * 3
                height: Kirigami.Units.largeSpacing * 3
            }

            onClicked: currentWebView.url = bookmarkDelegate.url

            contentItem: RowLayout {
                spacing: Kirigami.Units.smallSpacing

                Delegates.SubtitleContentItem {
                    itemDelegate: bookmarkDelegate
                    subtitle: bookmarkDelegate.url
                }

                QQC2.ToolButton {
                    icon.name: "entry-delete"
                    onClicked: BrowserManager.removeFromHistory(bookmarkDelegate.url)
                }
            }
        }
        Kirigami.PlaceholderMessage {
            visible: list.count === 0
            anchors.centerIn: parent

            text: i18n("Not history yet")
        }
    }
}
