# SPDX-FileCopyrightText: 2024 Carl Schwan <carl@carlschwan.eu>
# SPDX-License-Identifier: BSD-2-Clause

qt_add_library(angelfish_settings STATIC)

ecm_add_qml_module(angelfish_settings
    GENERATE_PLUGIN_SOURCE
    URI org.kde.angelfish.settings
    QML_FILES
        AngelfishConfigurationView.qml
        DesktopHomeSettingsPage.qml
        SettingsAdblock.qml
        SettingsGeneral.qml
        SettingsNavigationBarPage.qml
        SettingsSearchEnginePage.qml
        SettingsWebApps.qml
)