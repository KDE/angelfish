// SPDX-FileCopyrightText: 2019 Nicolas Fella <nicolas.fella@gmx.de>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import QtQuick.Window

import org.kde.kirigami as Kirigami
import org.kde.purpose as Purpose
import org.kde.kirigamiaddons.delegates as Delegates

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

        delegate: Delegates.RoundedItemDelegate {
            id: shareDelegate

            required property int index
            required property var model

            text: model.display
            onClicked: view.createJob(shareDelegate.index)
            Keys.onReturnPressed: view.createJob(shareDelegate.index)
            Keys.onEnterPressed: view.createJob(shareDelegate.index)

            contentItem: RowLayout {
                spacing: Kirigami.Units.smallSpacing

                Delegates.DefaultContentItem {
                    itemDelegate: shareDelegate
                }

                Kirigami.Icon {
                    implicitWidth: Kirigami.Units.iconSizes.small
                    implicitHeight: Kirigami.Units.iconSizes.small
                    source: "arrow-right"
                }
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

