// SPDX-FileCopyrightText: 2019 Nicolas Fella <nicolas.fella@gmx.de>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick.Controls 2.1 as Controls
import QtQuick.Layouts 1.7
import QtQuick 2.7
import QtQuick.Window 2.15

import org.kde.kirigami 2.20 as Kirigami
import org.kde.purpose 1.0 as Purpose

Kirigami.Dialog {
    id: inputSheet
    property url url
    property string inputTitle

    title: i18n("Share page to")
    preferredWidth: Kirigami.Units.gridUnit * 16
    standardButtons: Kirigami.Dialog.NoButton

    Purpose.AlternativesView {
        id: view
        pluginType: "ShareUrl"
        clip: true

        delegate: Kirigami.BasicListItem {
            id: shareDelegate

            required property string display
            required property int index

            label: shareDelegate.display
            onClicked: view.createJob (shareDelegate.index)
            Keys.onReturnPressed: view.createJob (shareDelegate.index)
            Keys.onEnterPressed: view.createJob (shareDelegate.index)
            
            trailing: Kirigami.Icon {
                implicitWidth: Kirigami.Units.iconSizes.small
                implicitHeight: Kirigami.Units.iconSizes.small
                source: "arrow-right"
            }
        }

        onFinished: close()
    }

    onVisibleChanged: {
        view.inputData = {
            "urls": [inputSheet.url.toString()],
            "title": inputSheet.inputTitle
        }
    }
}

