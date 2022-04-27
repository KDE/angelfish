//SPDX-FileCopyrightText: 2021 Felipe Kinoshita <kinofhek@gmail.com>
//SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.19 as Kirigami

import org.kde.angelfish 1.0

Kirigami.ScrollablePage {
    title: i18n("Toolbars")

    Kirigami.FormLayout {
        anchors.centerIn: parent

        QQC2.CheckBox {
            Kirigami.FormData.label: i18n("Show home button:")
            text: checked ? i18n("Enabled") : i18n("Disabled")
            checked: Settings.showHomeButton
            onClicked: Settings.showHomeButton = checked
        }

        QQC2.TextField {
            visible: Settings.showHomeButton
            Kirigami.FormData.label: i18n("Homepage:")
            text: Settings.homepage
            color: activeFocus ? Kirigami.Theme.textColor : Kirigami.Theme.disabledTextColor
            onActiveFocusChanged: {
                if (activeFocus) {
                    selectAll();
                }
            }
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

        QQC2.TextField {
            Kirigami.FormData.label: i18n("New tabs:")
            text: Settings.newTabUrl
            color: activeFocus ? Kirigami.Theme.textColor : Kirigami.Theme.disabledTextColor
            onActiveFocusChanged: {
                if (activeFocus) {
                    selectAll();
                }
            }
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

        QQC2.CheckBox {
            Kirigami.FormData.label: i18n("Always show the tab bar:")
            text: checked ? i18n("Enabled") : i18n("Disabled")
            checked: Settings.showTabBar
            onClicked: Settings.showTabBar = checked
        }
    }
}
