// SPDX-FileCopyrightText: 2014-2015 Sebastian Kügler <sebas@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Layouts 1.0

import org.kde.kirigami 2.8 as Kirigami
import org.kde.angelfish 1.0

Kirigami.ScrollablePage {
    title: i18n("History")
    Kirigami.ColumnView.fillWidth: false

    actions: [
        Kirigami.Action {
            text: "Clear"
            icon.name: "edit-clear-all"

            onTriggered: BrowserManager.clearHistory()
        }
    ]

    header: Item {
        anchors.horizontalCenter: parent.horizontalCenter
        height: Kirigami.Units.gridUnit * 3
        width: list.width

        Kirigami.SearchField {
            id: search
            anchors.centerIn: parent
            width: parent.width - Kirigami.Units.gridUnit

            clip: true
            inputMethodHints: rootPage.privateMode ? Qt.ImhNoPredictiveText : Qt.ImhNone
            Kirigami.Theme.inherit: true

            onDisplayTextChanged: {
                if (displayText === "" || displayText.length > 2) {
                    list.model.filter = displayText;
                    timer.running = false;
                }
                else timer.running = true;
            }
            Keys.onEscapePressed: pageStack.pop()

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
            
            // width: list.width
            icon {
                name: model.iconName.length > 0 ? model.iconName : "internet-services"
                width: Kirigami.Units.largeSpacing * 3
                height: Kirigami.Units.largeSpacing * 3
            }

            onClicked: {
                currentWebView.url = model.url;
                pageStack.pop();
            }
            onRemoved: BrowserManager.removeFromHistory(model.url);
        }
    }

    ListView {
        id: list
        anchors.fill: parent

        interactive: height < contentHeight
        clip: true

        reuseItems: true
        model: BookmarksHistoryModel {
            history: true
        }

        delegate: delegateComponent
    }

    Component.onCompleted: search.forceActiveFocus()
}
