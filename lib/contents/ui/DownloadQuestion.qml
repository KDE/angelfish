// SPDX-FileCopyrightText: 2020 Jonah Brüchert <jbb@kaidan.im>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import org.kde.kirigami as Kirigami

import QtWebEngine

Kirigami.InlineMessage {
    id: downloadQuestion
    text: i18n("Do you want to download this file?")
    showCloseButton: false

    property WebEngineDownloadRequest download

    actions: [
        Kirigami.Action {
            icon.name: "download"
            text: i18n("Download")
            onTriggered: {
                downloadQuestion.download.resume()
                downloadQuestion.visible = false
            }
        },
        Kirigami.Action {
            icon.name: "dialog-cancel"
            text: i18n("Cancel")
            onTriggered: {
                downloadQuestion.download.cancel()
                downloadQuestion.visible = false
            }
        }
    ]
}
