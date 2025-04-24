// SPDX-FileCopyrightText: 2019 Simon Schmeisser <s.schmeisser@gmx.net>
// SPDX-FileCopyrightText: 2019 Jonah Brüchert <jbb@kaidan.im>
// SPDX-FileCopyrightText: 2020 Rinigus <rinigus.git@gmail.com>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.angelfish

Controls.Drawer {
    id: overlay
    dragMargin: 0
    edge: Qt.BottomEdge
    width: parent.width

    property bool backHistory: true

    property int itemHeight: Kirigami.Units.gridUnit * 3

    property int fullHeight: Math.min(Math.max(itemHeight * 1, listView.contentHeight) + itemHeight,
                                      0.9 * rootPage.height)

    contentHeight: fullHeight
    contentWidth: parent.width
    contentItem: ListView {
        id: listView
        anchors.fill: parent

        boundsBehavior: Flickable.StopAtBounds
        clip: true

        delegate: UrlDelegate {
            title: model.title
            subtitle: model.url

            icon {
                name: model.icon.name > 0 ? model.icon.name : "internet-services"
                width: Kirigami.Units.largeSpacing * 3
                height: Kirigami.Units.largeSpacing * 3
            }

            showRemove: false
            onClicked: {
                currentWebView.goBackOrForward(model.offset);
                overlay.close();
            }
        }

        model: overlay.backHistory ? currentWebView.history.backItems :
                                     currentWebView.history.forwardItems
    }

    onClosed: {
        currentWebView.forceActiveFocus();
    }
}
