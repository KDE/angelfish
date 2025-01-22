// SPDX-FileCopyrightText: 2020 Jonah Brüchert <jbb@kaidan.im>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import org.kde.kirigami 2.4 as Kirigami
import QtWebEngine 1.9

Kirigami.InlineMessage {
    id: permissionQuestion

    property int permission
    property url origin

    position: Kirigami.Settings.isMobile ? Kirigami.InlineMessage.Footer : Kirigami.InlineMessage.Header

    text: {
        let url = new URL(permissionQuestion.origin)
        let host = url.host

        switch(permission) {
        case WebEngineView.MediaAudioCapture:
            return i18n("Do you want to allow the website <b>%1</b> to access the <b>microphone</b>?", host)
        case WebEngineView.MediaVideoCapture:
            return i18n("Do you want to allow the website <b>%1</b> to access the <b>camera</b>?", host)
        case WebEngineView.MediaAudioVideoCapture:
            return i18n("Do you want to allow the website <b>%1</b> to access the <b>camera and the microphone</b>?", host)
        case WebEngineView.DesktopVideoCapture:
            return i18n("Do you want to allow the website <b>%1</b> to share your <b>screen</b>?", host)
        case WebEngineView.DesktopAudioVideoCapture:
            return i18n("Do you want to allow the website <b>%1</b> to share the sound <b>output</b>?", host)
        case WebEngineView.Notifications:
            return i18n("Do you want to allow the website <b>%1</b> to send you <b>notifications</b>?", host)
        case WebEngineView.Geolocation:
            return i18n("Do you want to allow the website <b>%1</b> to access the <b>geo location</b>?", host)
        case WebEngineView.ClipboardReadWrite:
            return i18n("Do you want to allow the website <b>%1</b> to access the <b>clipboard</b>?", host)
        case WebEngineView.LocalFontsAccess:
            return i18n("Do you want to allow the website <b>%1</b> to access your <b>fonts</b>?", host)
        default:
            i18n("The website %1 requested an unknown permission %2", host, permission)
        }
    }
    showCloseButton: false

    actions: [
        Kirigami.Action {
            icon.name: "dialog-ok-apply"
            text: i18n("Accept")
            onTriggered: {
                currentWebView.grantFeaturePermission(
                    permissionQuestion.origin,
                    permissionQuestion.permission, true)
                permissionQuestion.visible = false
            }
        },
        Kirigami.Action {
            icon.name: "dialog-cancel"
            text: i18n("Decline")
            onTriggered: {
                currentWebView.grantFeaturePermission(
                    permissionQuestion.origin,
                    permissionQuestion.permission, false)
                permissionQuestion.visible = false
            }
        }
    ]
}
