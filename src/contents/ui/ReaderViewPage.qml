// SPDX-FileCopyrightText: 2021 Jonah Brüchert <jbb@kaidan.im>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.7
import QtQuick.Controls 2.5 as Controls
import org.kde.kirigami 2.0 as Kirigami

import org.kde.angelfish 1.0

Kirigami.ScrollablePage {
    property var readerView

    title: readerView.title

    Controls.TextArea {
        textFormat: Text.RichText
        wrapMode: Text.WordWrap
        text: readerView.content
    }
}
