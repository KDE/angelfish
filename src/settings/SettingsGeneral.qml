// SPDX-FileCopyrightText: 2020 Rinigus <rinigus.git@gmail.com>
// SPDX-FileCopyrightText: 2021 Jonah Brüchert  <jbb@kaidan.im>
// SPDX-FileCopyrightText: 2021 Felipe Kinoshita <kinofhek@gmail.com>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick.Controls as Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard

import org.kde.angelfish
import org.kde.angelfish.core as Core

FormCard.FormCardPage {
    id: root

    title: i18nc("@title:window", "General")

    FormCard.FormHeader {
        title: root.title
    }

    FormCard.FormCard {
        FormCard.FormSwitchDelegate {
            id: enableJavascript
            text: i18n("Enable JavaScript")
            description: i18n("This may be required on certain websites for them to work.")
            checked: Core.AngelfishSettings.webJavaScriptEnabled
            onClicked: Core.AngelfishSettings.webJavaScriptEnabled = checked
        }

        FormCard.FormDelegateSeparator { above: enableJavascript; below: loadImages }

        FormCard.FormSwitchDelegate {
            id: loadImages
            text: i18nc("@label:checkbox", "Load images")
            description: i18n("Whether to load images on websites.")
            checked: Core.AngelfishSettings.webAutoLoadImages
            onClicked: Core.AngelfishSettings.webAutoLoadImages = checked
        }

        FormCard.FormDelegateSeparator { above: loadImages; below: enableAdblock }

        FormCard.FormSwitchDelegate {
            id: enableAdblock
            text: i18nc("@label:checkbox", "Enable adblock")
            description: enabled ? i18n("Attempts to prevent advertisements on websites from showing.") : i18n("Adblock functionality was not included in this build.")
            enabled: AdblockUrlInterceptor.adblockSupported
            checked: AdblockUrlInterceptor.enabled
            onClicked: AdblockUrlInterceptor.enabled = checked
        }

        FormCard.FormDelegateSeparator { above: enableAdblock; below: openLinkSwitch }

        FormCard.FormSwitchDelegate {
            id: openLinkSwitch
            text: i18nc("@label:checkbox", "Switch to new tab immediately")
            description: i18n("When you open a link, image or media in a new tab, switch to it immediately.")
            checked: Core.AngelfishSettings.switchToNewTab
            onClicked: Core.AngelfishSettings.switchToNewTab = checked
        }

        FormCard.FormDelegateSeparator { above: openLinkSwitch; below: enableSmoothScrolling }

        FormCard.FormSwitchDelegate {
            id: enableSmoothScrolling
            text: i18nc("@label:checkbox", "Use smooth scrolling")
            description: i18n("Scrolling is smoother and will not stop suddenly when you stop scrolling. Requires app restart to take effect.")
            checked: Core.AngelfishSettings.webSmoothScrollingEnabled
            onClicked: Core.AngelfishSettings.webSmoothScrollingEnabled = checked
        }

        FormCard.FormDelegateSeparator { above: enableSmoothScrolling; below: enableDarkMode }

        FormCard.FormSwitchDelegate {
            id: enableDarkMode
            text: i18nc("@label:checkbox", "Use dark color scheme")
            description: i18n("Websites will have their color schemes set to dark. Requires app restart to take effect.")
            checked: Core.AngelfishSettings.webDarkModeEnabled
            onClicked: Core.AngelfishSettings.webDarkModeEnabled = checked
        }
    }
}
