// SPDX-FileCopyrightText: 2020 Rinigus <rinigus.git@gmail.com>
// SPDX-FileCopyrightText: 2021 Jonah Brüchert  <jbb@kaidan.im>
// SPDX-FileCopyrightText: 2021 Felipe Kinoshita <kinofhek@gmail.com>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick.Controls 2.5 as Controls
import QtQuick.Layouts 1.12

import org.kde.kirigami 2.5 as Kirigami
import org.kde.kirigamiaddons.labs.mobileform 0.1 as MobileForm

import org.kde.angelfish 1.0

Kirigami.ScrollablePage {
    id: root
    title: i18n("General")

    leftPadding: 0
    rightPadding: 0
    topPadding: Kirigami.Units.gridUnit
    bottomPadding: Kirigami.Units.gridUnit

    Kirigami.Theme.colorSet: Kirigami.Theme.Window
    Kirigami.Theme.inherit: false

    ColumnLayout {
        spacing: 0

        MobileForm.FormCard {
            Layout.fillWidth: true

            contentItem: ColumnLayout {
                spacing: 0
                MobileForm.FormCardHeader{
                    title:root.title
                }
                MobileForm.FormSwitchDelegate {
                    id: enableJavascript
                    text: i18n("Enable JavaScript")
                    description: i18n("This may be required on certain websites for them to work.")
                    checked: Settings.webJavaScriptEnabled
                    onClicked: Settings.webJavaScriptEnabled = checked
                }
                
                MobileForm.FormDelegateSeparator { above: enableJavascript; below: loadImages }
                
                MobileForm.FormSwitchDelegate {
                    id: loadImages
                    text: i18n("Load images")
                    description: i18n("Whether to load images on websites.")
                    checked: Settings.webAutoLoadImages
                    onClicked: Settings.webAutoLoadImages = checked
                }
                
                MobileForm.FormDelegateSeparator { above: loadImages; below: enableAdblock }
                
                MobileForm.FormSwitchDelegate {
                    id: enableAdblock
                    text: i18n("Enable adblock")
                    description: enabled ? i18n("Attempts to prevent advertisements on websites from showing.") : i18n("AdBlock functionality was not included in this build.")
                    enabled: AdblockUrlInterceptor.adblockSupported
                    checked: AdblockUrlInterceptor.enabled
                    onClicked: AdblockUrlInterceptor.enabled = checked
                }
                
                MobileForm.FormDelegateSeparator { above: enableAdblock; below: openLinkSwitch }
                
                MobileForm.FormSwitchDelegate {
                    id: openLinkSwitch
                    text: i18n("Switch to new tab immediately")
                    description: i18n("When you open a link, image or media in a new tab, switch to it immediately")
                    checked: Settings.switchToNewTab
                    onClicked: Settings.switchToNewTab = checked
                }
            }
        }
    }
}
