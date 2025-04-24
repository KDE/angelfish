// SPDX-FileCopyrightText: 2020 Jonah Brüchert <jbb@kaidan.im>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import org.kde.kirigami as Kirigami
import org.kde.angelfish
import org.kde.angelfish.core as Core

Kirigami.InlineMessage {
    id: question
    showCloseButton: true

    visible: AdblockUrlInterceptor.adblockSupported

    text: i18nc("@info", "The adblocker is missing its filter lists, do you want to download them now?")
    position: Kirigami.Settings.isMobile ? Kirigami.InlineMessage.Footer : Kirigami.InlineMessage.Header

    AdblockFilterListsModel {
        id: filterListsModel
        onRefreshFinished: question.visible = false
        onResetAdblock: AdblockUrlInterceptor.resetAdblock()
    }

    onVisibleChanged: if (!visible) {
        Core.AngelfishSettings.adblockFilterDownloadDismissed = true
    }

    actions: [
        Kirigami.Action {
            id: downloadAction
            icon.name: "download"
            text: i18nc("@action:button", "Download")

            onTriggered: {
                filterListsModel.refreshLists()
                downloadAction.enabled = false;
                downloadAction.text = i18nc("@info", "Downloading…")
            }
        },
        Kirigami.Action {
            id: disableAction
            icon.name: "dialog-cancel"
            text: i18nc("@action:button", "Disable Adblock")

            onTriggered: {
                AdblockUrlInterceptor.enabled = false;
                disableAction.enabled = false;
                downloadAction.enabled = false;
                disableAction.text = i18nc("@info", "Adblock Disabled…")
            }
        }
    ]
}
