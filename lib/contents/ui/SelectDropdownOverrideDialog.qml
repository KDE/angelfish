// SPDX-FileCopyrightText: 2020 UBports Foundation <developers@ubports.com>
// SPDX-FileCopyrightText: 2021 Devin Lin <devin@kde.org>
//
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick 2.15
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.15 as Controls
import org.kde.kirigami 2.7 as Kirigami

Kirigami.OverlaySheet {
    id: selectOverlay

    property string options: ""
    property int selectedIndex: -1
    property var selectOptions:  []
    property bool accepted: false

    signal accept(string text)
    signal reject()

    onOptionsChanged: {
        if (options.length > 0) {
            var props = JSON.parse(options)
            selectOptions = props.options
            selectedIndex = props.selectedIndex
        }
    }

    contentItem: ListView {
        model: selectOverlay.selectOptions
        currentIndex: selectedIndex
        Layout.preferredWidth: Kirigami.Units.gridUnit * 16

        delegate: Controls.RadioDelegate {
            topPadding: Kirigami.Units.smallSpacing * 2
            bottomPadding: Kirigami.Units.smallSpacing * 2
            width: parent.width

            checked: index == selectedIndex
            text: modelData

            onCheckedChanged: {
                if (checked) {
                    accepted = true;
                    selectOverlay.accept(index);
                    selectOverlay.close();
                }
            }
        }
    }

    onSheetOpenChanged: {
        if (!sheetOpen && !accepted) {
            selectOverlay.reject();
        } else if (sheetOpen) {
            accepted = false;
        }
    }
}
