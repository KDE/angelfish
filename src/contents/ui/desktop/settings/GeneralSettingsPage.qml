//SPDX-FileCopyrightText: 2021 Felipe Kinoshita <kinofhek@gmail.com>
//SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.19 as Kirigami

import org.kde.angelfish 1.0

Kirigami.ScrollablePage {
    title: i18n("General")

    Kirigami.FormLayout {
        anchors.centerIn: parent

        QQC2.CheckBox {
            Kirigami.FormData.label: i18n("General:")
            text: i18n("Enable JavaScript")
            checked: Settings.webJavaScriptEnabled
            onClicked: Settings.webJavaScriptEnabled = checked
        }

        QQC2.CheckBox {
            text: i18n("Load images")
            checked: Settings.webAutoLoadImages
            onClicked: Settings.webAutoLoadImages = checked
        }

        QQC2.CheckBox {
            visible: AdblockUrlInterceptor.adblockSupported
            enabled: AdblockUrlInterceptor.adblockSupported
            text: i18n("Enable Adblock")
            checkable: true
            checked: AdblockUrlInterceptor.enabled
            onCheckedChanged: {
                AdblockUrlInterceptor.enabled = checked
            }
        }

        QQC2.CheckBox {
            text: i18n("When you open a link, image or media in a new tab, switch to it immediately")
            checked: Settings.switchToNewTab
            onClicked: Settings.switchToNewTab = checked
        }
    }
}
