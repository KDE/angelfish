// SPDX-FileCopyrightText: 2019 Jonah Brüchert
// SPDX-FileCopyrightText: 2022 Devin Lin <devin@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick.Controls 2.1 as Controls
import QtQuick.Layouts 1.7
import QtQuick 2.7

import org.kde.kirigami 2.20 as Kirigami

Kirigami.PromptDialog {
    id: root
    property string placeholderText
    property string description
    property string text

    standardButtons: Kirigami.Dialog.Ok

    onAccepted: root.text = textField.text

    ColumnLayout {
        Controls.Label {
            Layout.fillWidth: true
            text: root.description
            wrapMode: Text.WordWrap
        }

        Controls.TextField {
            id: textField
            Layout.fillWidth: true
            placeholderText: root.placeholderText
            text: root.text
            focus: true
            onAccepted: accept()
        }
    }

    onVisibleChanged: {
        if (visible) {
            textField.forceActiveFocus()
        }
    }
}
