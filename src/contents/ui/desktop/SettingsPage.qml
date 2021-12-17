//SPDX-FileCopyrightText: 2021 Felipe Kinoshita <kinofhek@gmail.com>
//SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.19 as Kirigami

Kirigami.CategorizedSettings {
    actions: [
        Kirigami.SettingAction {
            text: i18n("General")
            icon.name: "org.kde.angelfish"
            page: Qt.resolvedUrl("DesktopGeneralSettingsPage.qml")
        },
        Kirigami.SettingAction {
            text: i18n("Home")
            icon.name: "go-home-symbolic"
            page: Qt.resolvedUrl("DesktopHomeSettingsPage.qml")
        }
    ]
}
