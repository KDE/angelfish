//SPDX-FileCopyrightText: 2021 Felipe Kinoshita <kinofhek@gmail.com>
//SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.19 as Kirigami

Kirigami.CategorizedSettings {
    actions: [
        Kirigami.SettingAction {
            actionName: "general"
            text: i18n("General")
            icon.name: "org.kde.angelfish"
            page: Qt.resolvedUrl("SettingsGeneral.qml")
        },
        Kirigami.SettingAction {
            actionName: "adblock"
            text: i18n("Ad Block")
            icon.name: "security-medium"
            page: Qt.resolvedUrl("SettingsAdblock.qml")
        },
        Kirigami.SettingAction {
            actionName: "webapps"
            text: i18n("Web Apps")
            icon.name: "applications-all"
            page: Qt.resolvedUrl("SettingsWebApps.qml")
        },
        Kirigami.SettingAction {
            actionName: "searchengine"
            text: i18n("Search Engine")
            icon.name: "preferences-desktop-search"
            page: Qt.resolvedUrl("SettingsSearchEnginePage.qml")
        },
        Kirigami.SettingAction {
            actionName: "Toolbars"
            text: i18n("Toolbars")
            icon.name: "home"
            page: Kirigami.Settings.isMobile ? Qt.resolvedUrl("SettingsNavigationBarPage.qml") : Qt.resolvedUrl("DesktopHomeSettingsPage.qml")
        }
    ]
}
