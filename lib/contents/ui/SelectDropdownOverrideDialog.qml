/*
 * Copyright 2020 UBports Foundation
 *
 * This file is part of morph-browser.
 *
 * morph-browser is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * morph-browser is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

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

    ListView {
        model: selectOverlay.selectOptions
        currentIndex: selectedIndex
        Layout.preferredWidth: Kirigami.Units.gridUnit * 16

        delegate: Controls.RadioDelegate {
            topPadding: Kirigami.Units.smallSpacing * 2
            bottomPadding: Kirigami.Units.smallSpacing * 2
            implicitWidth: Kirigami.Units.gridUnit * 16

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
