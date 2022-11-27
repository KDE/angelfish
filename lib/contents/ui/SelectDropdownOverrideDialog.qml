// SPDX-FileCopyrightText: 2020 UBports Foundation <developers@ubports.com>
// SPDX-FileCopyrightText: 2021 Devin Lin <devin@kde.org>
//
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick 2.15
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.15 as Controls
import org.kde.kirigami 2.20 as Kirigami

Kirigami.Dialog {
    id: selectOverlay

    property string options: ""
    property int selectedIndex: -1
    property var selectOptions:  []
    property bool hasAccepted: false

    signal acceptText(string text)

    onOptionsChanged: {
        if (options.length > 0) {
            var props = JSON.parse(options)
            selectOptions = props.options
            selectedIndex = props.selectedIndex
        }
    }
    preferredWidth: Kirigami.Units.gridUnit * 16
    standardButtons: Kirigami.Dialog.NoButton

    ColumnLayout {
        id: column
        spacing: 0
        Repeater {
            model: selectOverlay.selectOptions
            
            delegate: Controls.RadioDelegate {
                Layout.fillWidth: true
                topPadding: Kirigami.Units.smallSpacing * 2
                bottomPadding: Kirigami.Units.smallSpacing * 2

                checked: index == selectedIndex
                text: modelData

                onCheckedChanged: {
                    if (checked) {
                        hasAccepted = true;
                        selectOverlay.acceptText(index);
                        selectOverlay.accepted();
                        selectOverlay.close();
                    }
                }
            }
        }
    }
}
