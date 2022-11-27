// SPDX-FileCopyrightText: 2020 Rinigus <rinigus.git@gmail.com>
// SPDX-FileCopyrightText: 2020 Jonah Brüchert  <jbb@kaidan.im>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.3
import QtQuick.Controls 2.4 as Controls
import QtQuick.Layouts 1.11

import org.kde.kirigami 2.7 as Kirigami
import org.kde.kirigamiaddons.labs.mobileform 0.1 as MobileForm

import org.kde.angelfish 1.0

Kirigami.ScrollablePage {
    title: i18n("Navigation bar")

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
                
                Controls.Label {
                    text: i18n("Choose the buttons enabled in navigation bar. \
Some of the buttons can be hidden only in portrait \
orientation of the browser and are always shown if  \
the browser is wider than its height.\n\n \
Note that if you disable the menu buttons, you \
will be able to access the menus either by swiping \
from the left or right side or to a side along the bottom \
of the window.")
                    Layout.fillWidth: true
                    padding: Kirigami.Units.gridUnit
                    wrapMode: Text.WordWrap
                }
                
                MobileForm.FormDelegateSeparator {}
                
                MobileForm.FormCheckDelegate {
                    text: i18n("Main menu in portrait")
                    checked: Settings.navBarMainMenu
                    onCheckedChanged: Settings.navBarMainMenu = checked
                }
                
                MobileForm.FormCheckDelegate {
                    text: i18n("Tabs in portrait")
                    checked: Settings.navBarTabs
                    onCheckedChanged: Settings.navBarTabs = checked
                }
                
                MobileForm.FormCheckDelegate {
                    text: i18n("Context menu in portrait")
                    checked: Settings.navBarContextMenu
                    onCheckedChanged: Settings.navBarContextMenu = checked
                }
                
                MobileForm.FormCheckDelegate {
                    text: i18n("Go back")
                    checked: Settings.navBarBack
                    onCheckedChanged: Settings.navBarBack = checked
                }
                
                MobileForm.FormCheckDelegate {
                    text: i18n("Go forward")
                    checked: Settings.navBarForward
                    onCheckedChanged: Settings.navBarForward = checked
                }
                
                MobileForm.FormCheckDelegate {
                    text: i18n("Reload/Stop")
                    checked: Settings.navBarReload
                    onCheckedChanged: Settings.navBarReload = checked
                }
            }
        }
    }
}
