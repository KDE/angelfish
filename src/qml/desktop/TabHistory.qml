// SPDX-FileCopyrightText: 2021 Felipe Kinoshita <kinofhek@gmail.com>
// SPDX-FileCopyrightText: 2023 Michael Lang <criticaltemp@protonmail.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

import org.kde.angelfish
import org.kde.angelfish.core as Core

QQC2.Menu {
    id: historyMenu

    property var entries: []
    property bool isBackMenu: true  // true for back history, false for forward

    Repeater {
        model: historyMenu.entries

        QQC2.MenuItem {
            property var entry: modelData

            text: model.url
            icon.name: model.iconName && model.iconName.length > 0 ? model.iconName : "internet-services"

            onTriggered: {
                if (historyMenu.isBackMenu) {
                    currentWebView.url = url;
                } else {
                    currentWebView.url = url;
                }
            }
        }
    }

    function showBackHistory() {
        historyMenu.entries = currentWebView.history.backItems
        historyMenu.isBackMenu = true
        historyMenu.open()
    }

    function showForwardHistory() {
        historyMenu.entries = currentWebView.history.forwardItems
        historyMenu.isBackMenu = false
        historyMenu.open()
    }
}
