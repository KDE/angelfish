// SPDX-FileCopyrightText: 2020 Rinigus <rinigus.git@gmail.com>
// SPDX-FileCopyrightText: 2020 Jonah Brüchert  <jbb@kaidan.im>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard

import org.kde.angelfish
import org.kde.angelfish.core as Core

FormCard.FormCardPage {
    id: root

    title: i18nc("@title:window", "Navigation Bar")

    FormCard.FormHeader {
        title: root.title
    }

    FormCard.FormCard {
        Controls.Label {
            text: i18n("Choose the buttons enabled in navigation bar. Some of the buttons can be hidden only in portrait orientation of the browser and are always shown if the browser is wider than its height.\n\n Note that if you disable the menu buttons, you will be able to access the menus either by swiping from the left or right side or to a side along the bottom of the window.")
            Layout.fillWidth: true
            padding: Kirigami.Units.gridUnit
            wrapMode: Text.WordWrap
        }

        FormCard.FormDelegateSeparator {}

        FormCard.FormCheckDelegate {
            text: i18nc("@label:checkbox", "Main menu in portrait")
            checked: Core.AngelfishSettings.navBarMainMenu
            onCheckedChanged: Core.AngelfishSettings.navBarMainMenu = checked
        }

        FormCard.FormCheckDelegate {
            text: i18nc("@label:checkbox", "Tabs in portrait")
            checked: Core.AngelfishSettings.navBarTabs
            onCheckedChanged: Core.AngelfishSettings.navBarTabs = checked
        }

        FormCard.FormCheckDelegate {
            text: i18nc("@label:checkbox", "Context menu in portrait")
            checked: SCore.Angelfishettings.navBarContextMenu
            onCheckedChanged: Core.AngelfishSettings.navBarContextMenu = checked
        }

        FormCard.FormCheckDelegate {
            text: i18nc("@label:checkbox", "Go back")
            checked: Core.AngelfishSettings.navBarBack
            onCheckedChanged: Core.AngelfishSettings.navBarBack = checked
        }

        FormCard.FormCheckDelegate {
            text: i18nc("@label:checkbox", "Go forward")
            checked: Core.AngelfishSettings.navBarForward
            onCheckedChanged: Core.AngelfishSettings.navBarForward = checked
        }

        FormCard.FormCheckDelegate {
            text: i18nc("@label:checkbox", "Reload/Stop")
            checked: Core.AngelfishSettings.navBarReload
            onCheckedChanged: Core.AngelfishSettings.navBarReload = checked
        }
    }
}
