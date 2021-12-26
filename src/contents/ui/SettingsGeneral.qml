// SPDX-FileCopyrightText: 2020 Rinigus <rinigus.git@gmail.com>
// SPDX-FileCopyrightText: 2021 Jonah Brüchert  <jbb@kaidan.im>
// SPDX-FileCopyrightText: 2021 Felipe Kinoshita <kinofhek@gmail.com>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import org.kde.kirigami 2.5 as Kirigami
import QtQuick.Controls 2.5 as Controls

import QtQuick.Layouts 1.12

import org.kde.angelfish 1.0

Kirigami.ScrollablePage {
    topPadding: 0
    bottomPadding: 0
    leftPadding: 0
    rightPadding: 0

    ColumnLayout {
        spacing: 0

        Controls.SwitchDelegate {
            text: i18n("Enable JavaScript")
            Layout.fillWidth: true
            checked: Settings.webJavaScriptEnabled
            onClicked: Settings.webJavaScriptEnabled = checked
            leftPadding: Kirigami.Units.gridUnit
            rightPadding: Kirigami.Units.gridUnit
            implicitHeight: Kirigami.Units.gridUnit * 2.5
        }

        Kirigami.Separator {
            Layout.fillWidth: true
        }

        Controls.SwitchDelegate {
            text: i18n("Load images")
            Layout.fillWidth: true
            checked: Settings.webAutoLoadImages
            onClicked: Settings.webAutoLoadImages = checked
            leftPadding: Kirigami.Units.gridUnit
            rightPadding: Kirigami.Units.gridUnit
            implicitHeight: Kirigami.Units.gridUnit * 2.5
        }

        Kirigami.Separator {
            Layout.fillWidth: true
        }

        Controls.ItemDelegate {
            text: i18n("Search Engine")
            Layout.fillWidth: true
            onClicked: pageStack.push(Qt.resolvedUrl("SettingsSearchEnginePage.qml"))
            leftPadding: Kirigami.Units.gridUnit
            rightPadding: Kirigami.Units.gridUnit
            implicitHeight: Kirigami.Units.gridUnit * 2.5
        }

        Kirigami.Separator {
            Layout.fillWidth: true
        }

        Controls.SwitchDelegate {
            text: i18n("Enable adblock")
            Layout.fillWidth: true
            visible: AdblockUrlInterceptor.adblockSupported
            enabled: AdblockUrlInterceptor.adblockSupported
            checked: AdblockUrlInterceptor.enabled
            onClicked: AdblockUrlInterceptor.enabled = checked
            leftPadding: Kirigami.Units.gridUnit
            rightPadding: Kirigami.Units.gridUnit
            implicitHeight: Kirigami.Units.gridUnit * 2.5
        }
        
        Kirigami.Separator {
            Layout.fillWidth: true
        }
    }
}
