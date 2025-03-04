// SPDX-FileCopyrightText: 2020 Jonah Brüchert <jbb@kaidan.im>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import org.kde.kirigami as Kirigami

import QtWebEngine

Kirigami.InlineMessage {
    id: downloadQuestion

    property WebEngineDownloadRequest download

    text: i18nc("Would you like to download (filename) from (domain)?",
                "Would you like to download %1 from %2?",
                download.downloadFileName, new URL(download.url).host)
    showCloseButton: false

    position: Kirigami.Settings.isMobile ? Kirigami.InlineMessage.Footer : Kirigami.InlineMessage.Header

    actions: [
        Kirigami.Action {
            icon.name: "download"
            text: i18nc("@action:button", "Download")
            onTriggered: {
                downloadQuestion.download.resume()
                downloadQuestion.visible = false
            }
        },
        Kirigami.Action {
            icon.name: "dialog-cancel"
            text: i18nc("@action:button", "Cancel")
            onTriggered: {
                downloadQuestion.download.cancel()
                downloadQuestion.visible = false
            }
        }
    ]
}
