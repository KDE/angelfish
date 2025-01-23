//SPDX-FileCopyrightText: 2021 Felipe Kinoshita <kinofhek@gmail.com>
//SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.19 as Kirigami
import org.kde.kirigamiaddons.settings 1.0 as KirigamiSettings

KirigamiSettings.ConfigurationView {
    modules: [
        KirigamiSettings.ConfigurationModule {
            moduleId: "general"
            text: i18nc("@title:window", "General")
            icon.name: "org.kde.angelfish"
            page: () => Qt.createComponent("SettingsGeneral.qml")
        },
        KirigamiSettings.ConfigurationModule {
            moduleId: "adblock"
            text: i18nc("@title:window", "Adblock")
            icon.name: "security-medium"
            page: () => Qt.createComponent("SettingsAdblock.qml")
        },
        KirigamiSettings.ConfigurationModule {
            moduleId: "webapps"
            text: i18nc("@title:window", "Web Apps")
            icon.name: "applications-all"
            page: () => Qt.createComponent("SettingsWebApps.qml")
        },
        KirigamiSettings.ConfigurationModule {
            moduleId: "searchengine"
            text: i18nc("@title:window", "Search Engines")
            icon.name: "preferences-desktop-search"
            page: () => Qt.createComponent("SettingsSearchEnginePage.qml")
        },
        KirigamiSettings.ConfigurationModule {
            moduleId: "Toolbars"
            text: i18nc("@title:window", "Toolbars")
            icon.name: "home"
            page: () => Kirigami.Settings.isMobile ? Qt.createComponent("SettingsNavigationBarPage.qml") : Qt.createComponent("DesktopHomeSettingsPage.qml")
        }
    ]
}
