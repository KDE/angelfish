// SPDX-FileCopyrightText: 2020 Jonah Brüchert <jbb@kaidan.im>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.0
import org.kde.kirigami 2.4 as Kirigami


Kirigami.InlineMessage {
    id: newTabQuestion
    type: Kirigami.MessageType.Warning
    text: url ? i18nc("@info:status", "Site wants to open a new tab:\n%1", url.toString()) : ""
    showCloseButton: true

    property url url

    actions: [
        Kirigami.Action {
            icon.name: "tab-new"
            text: i18nc("@action:inmenu", "Open")
            onTriggered: {
                tabs.tabsModel.newTab(newTabQuestion.url.toString())
                newTabQuestion.visible = false
            }
        }

    ]
}
