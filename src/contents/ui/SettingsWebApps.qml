// SPDX-FileCopyrightText: 2021 Jonah Brüchert <jbb@kaidan.im>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.3
import QtQuick.Controls 2.4 as Controls
import QtQuick.Layouts 1.11

import org.kde.kirigami 2.7 as Kirigami
import org.kde.angelfish 1.0

Kirigami.ScrollablePage {
    title: i18n("Web Apps")

    ListView {
        model: WebAppManagerModel {
            id: webAppModel
        }

        delegate: Kirigami.SwipeListItem {
            required property int index;
            required property string desktopIcon;
            required property string name;
            required property string url;

            RowLayout {
                spacing: Kirigami.Units.largeSpacing
                Kirigami.Icon {
                    source: desktopIcon
                }

                Controls.Label {
                    Layout.fillWidth: true

                    text: name
                    elide: Text.ElideRight
                }
            }

            actions: [
                Kirigami.Action {
                    text: i18n("Remove app")
                    icon.name: "delete"
                    onTriggered: webAppModel.removeApp(index)
                }
            ]
        }
    }
}
