// SPDX-FileCopyrightText: 2014-2015 Sebastian Kügler <sebas@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami

import org.kde.angelfish
import org.kde.angelfish.core as Core

Core.WebView {
    id: webEngineView

    profile: Core.AngelfishWebProfile {
        httpUserAgent: userAgent.userAgent
        questionLoader: questionLoader
        offTheRecord: false
        storageName: "angelfish-webapp"
    }

    isAppView: true

    onNewWindowRequested: {
        if (Core.UrlUtils.urlHost(request.requestedUrl) === Core.UrlUtils.urlHost(Core.BrowserManager.initialUrl)) {
            url = request.requestedUrl;
        } else {
            Qt.openUrlExternally(request.requestedUrl);
        }
    }
}
