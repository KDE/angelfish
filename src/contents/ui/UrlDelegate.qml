// SPDX-FileCopyrightText: 2014-2015 Sebastian Kügler <sebas@kde.org>
// SPDX-FileCopyrightText: 2021 Felipe Kinoshita <kinofhek@gmail.com>
// SPDX-FileCopyrightText: 2024 Devin Lin <devin@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.delegates as Delegates

Delegates.RoundedItemDelegate {
    id: root
    property bool showRemove: true

    property string highlightText
    readonly property var regex: new RegExp(highlightText, 'i')
    readonly property string highlightedText: "<b><font color=\"" + Kirigami.Theme.selectionTextColor + "\">$&</font></b>"

    property string title
    property string subtitle
    signal removed

    text: title ? (highlightText ? title.replace(regex, highlightedText) : title) : ""

    contentItem: RowLayout {
        spacing: Kirigami.Units.smallSpacing

        Delegates.SubtitleContentItem {
            itemDelegate: root
            subtitle: root.subtitle ? (highlightText ? root.subtitle.replace(regex, highlightedText) : root.subtitle) : ""
        }

        QQC2.ToolButton {
            visible: root.showRemove
            icon.name: "entry-delete"
            onClicked: root.removed()
        }
    }
}
