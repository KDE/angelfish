//SPDX-FileCopyrightText: 2021 Felipe Kinoshita <kinofhek@gmail.com>
//SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard

import org.kde.angelfish
import org.kde.angelfish.core as Core

FormCard.FormCardPage {
    id: root

    title: i18nc("@title:window", "Toolbars")

    FormCard.FormHeader {
        title: root.title
    }

    FormCard.FormCard {
        FormCard.FormSwitchDelegate {
            id: showHome
            text: i18nc("@label", "Show home button:")
            description: i18n("The home button will be shown next to the reload button in the toolbar.")
            checked: Core.AngelfishSettings.showHomeButton
            onClicked: Core.AngelfishSettings.showHomeButton = checked
        }

        FormCard.FormDelegateSeparator { above: homepage; below: showHome; visible: homepage.visible }

        FormCard.FormTextFieldDelegate {
            id: homepage
            visible: Core.AngelfishSettings.showHomeButton
            label: i18nc("@label", "Homepage:")
            text: Core.AngelfishSettings.homepage
            onAccepted: {
                let url = text;
                if (url.indexOf(":/") < 0) {
                    url = "http://" + url;
                }
                Core.AngelfishSettings.homepage = url;
            }
            onEditingFinished: {
                let url = text;
                if (url.indexOf(":/") < 0) {
                    url = "http://" + url;
                }
                Core.AngelfishSettings.homepage = url;
            }

        }

        FormCard.FormDelegateSeparator { above: newTab }

        FormCard.FormTextFieldDelegate {
            id: newTab
            label: i18nc("@label", "New tabs:")
            text: Core.AngelfishSettings.newTabUrl
            onAccepted: {
                let url = text;
                if (url.indexOf(":/") < 0) {
                    url = "http://" + url;
                }
                Core.AngelfishSettings.newTabUrl = url;
            }
            onEditingFinished: {
                let url = text;
                if (url.indexOf(":/") < 0) {
                    url = "http://" + url;
                }
                Core.AngelfishSettings.newTabUrl = url;
            }

        }

        FormCard.FormDelegateSeparator { above: alwaysShowTabs }

        FormCard.FormSwitchDelegate {
            id: alwaysShowTabs
            text: i18nc("@label:checkbox", "Always show the tab bar")
            description: i18n("The tab bar will be displayed even if there is only one tab open.")
            checked: Core.AngelfishSettings.showTabBar
            onClicked: Core.AngelfishSettings.showTabBar = checked
        }
    }
}
