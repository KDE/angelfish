// SPDX-FileCopyrightText: 2020 Jonah Brüchert <jbb@kaidan.im>
// SPDX-FileCopyrightText: 2022 Devin Lin <devin@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard

import QtWebEngine 1.4

FormCard.FormCardDialog {
    id: root

    property AuthenticationDialogRequest request

    title: i18nc("@title:window", "Authentication Required")

    standardButtons: Kirigami.Dialog.Ok | Kirigami.Dialog.Cancel

    onAccepted: root.request.dialogAccept(usernameField.text, passwordField.text)
    onRejected: root.request.dialogReject()

    FormCard.FormTextFieldDelegate {
        id: usernameField

        label: i18nc("@label:textbox", "Username:")
    }

    FormCard.FormPasswordFieldDelegate {
        id: passwordField

        label: i18nc("@label:textbox", "Password:")
    }
}
