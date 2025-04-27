// SPDX-FileCopyrightText: 2025 Yelsin Sepulveda <yelsinsepulveda@gmail.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtWebEngine

import org.kde.kirigami as Kirigami

import org.kde.angelfish
import org.kde.angelfish.core as Core

QQC2.Menu {
    id: root

    required property Core.WebView currentWebView
    property bool isBackMenu: true  // true for back history, false for forward
    readonly property WebEngineHistoryModel historyModel: isBackMenu ? currentWebView.history.backItems : currentWebView.history.forwardItems

    Repeater {
        model: root.historyModel

        QQC2.MenuItem {
            required property string url
            required property string title
            required property var model

            text: title
            icon.name: model.iconName && model.iconName.length > 0 ? model.iconName : "internet-services-symbolic"

            onTriggered: if (root.isBackMenu) {
                currentWebView.url = url;
            } else {
                currentWebView.url = url;
            }
        }
    }

    function showBackHistory(): void {
        root.isBackMenu = true;
        root.open();
    }

    function showForwardHistory(): void {
        root.isBackMenu = false;
        root.open();
    }
}
