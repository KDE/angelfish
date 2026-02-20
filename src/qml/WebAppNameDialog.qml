// SPDX-FileCopyrightText: 2025 KDE Contributors
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami

Kirigami.PromptDialog {
    id: root
    
    property string appName: ""
    property url appUrl: ""
    property url appIcon: ""
    property var webAppCreator
    
    title: i18nc("@title:window", "Add to Application Launcher")
    standardButtons: Kirigami.Dialog.Ok | Kirigami.Dialog.Cancel
    
    parent: applicationWindow().overlay
    
    onAccepted: {
        if (webAppCreator) {
            webAppCreator.createDesktopFile(textField.text, appUrl, appIcon)
        }
    }
    
    ColumnLayout {
        Controls.Label {
            Layout.fillWidth: true
            text: i18nc("@info", "Enter a name for the web application:")
            wrapMode: Text.WordWrap
        }
        
        Controls.TextField {
            id: textField
            Layout.fillWidth: true
            placeholderText: i18nc("@info:placeholder", "Application name")
            text: root.appName
            focus: true
            onAccepted: root.accept()
        }
    }
    
    onVisibleChanged: {
        if (visible) {
            textField.text = root.appName
            textField.forceActiveFocus()
            textField.selectAll()
        }
    }
}
