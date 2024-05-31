//SPDX-FileCopyrightText: 2021 Felipe Kinoshita <kinofhek@gmail.com>
//SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard

import org.kde.angelfish

FormCard.FormCardPage {
    id: root

    title: i18n("Toolbars")

    FormCard.FormHeader {
        title: root.title
    }

    FormCard.FormCard {
        FormCard.FormSwitchDelegate {
            id: showHome
            text: i18n("Show home button:")
            description: i18n("The home button will be shown next to the reload button in the toolbar.")
            checked: Settings.showHomeButton
            onClicked: Settings.showHomeButton = checked
        }

        FormCard.FormDelegateSeparator { above: homepage; below: showHome; visible: homepage.visible }

        FormCard.FormTextFieldDelegate {
            id: homepage
            visible: Settings.showHomeButton
            label: i18n("Homepage:")
            text: Settings.homepage
            onAccepted: {
                let url = text;
                if (url.indexOf(":/") < 0) {
                    url = "http://" + url;
                }
                Settings.homepage = url;
            }
            onEditingFinished: {
                let url = text;
                if (url.indexOf(":/") < 0) {
                    url = "http://" + url;
                }
                Settings.homepage = url;
            }

        }

        FormCard.FormDelegateSeparator { above: newTab }

        FormCard.FormTextFieldDelegate {
            id: newTab
            label: i18n("New tabs:")
            text: Settings.newTabUrl
            onAccepted: {
                let url = text;
                if (url.indexOf(":/") < 0) {
                    url = "http://" + url;
                }
                Settings.newTabUrl = url;
            }
            onEditingFinished: {
                let url = text;
                if (url.indexOf(":/") < 0) {
                    url = "http://" + url;
                }
                Settings.newTabUrl = url;
            }

        }

        FormCard.FormDelegateSeparator { above: alwaysShowTabs }

        FormCard.FormSwitchDelegate {
            id: alwaysShowTabs
            text: i18n("Always show the tab bar")
            description: i18n("The tab bar will be displayed even if there is only one tab open")
            checked: Settings.showTabBar
            onClicked: Settings.showTabBar = checked
        }
    }
}
