//SPDX-FileCopyrightText: 2021 Felipe Kinoshita <kinofhek@gmail.com>
//SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.19 as Kirigami
import org.kde.kirigamiaddons.formcard 1.0 as FormCard

import org.kde.angelfish 1.0

Kirigami.ScrollablePage {
    id: root
    title: i18n("Toolbars")

    leftPadding: 0
    rightPadding: 0
    topPadding: Kirigami.Units.gridUnit
    bottomPadding: Kirigami.Units.gridUnit

    ColumnLayout {
        spacing: 0

        FormCard.FormHeader {
            title: root.title
        }

        FormCard.FormCard {
            Layout.fillWidth: true

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
}
