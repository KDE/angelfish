/*
    SPDX-FileCopyrightText: 2017 Marco Martin <mart@kde.org>
    SPDX-FileCopyrightText: 2017 The Qt Company Ltd.
    SPDX-FileCopyrightText: 2020 Noah Davis <noahadvs@gmail.com>
    SPDX-License-Identifier: LGPL-3.0-only OR GPL-2.0-or-later
*/


import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Controls as Controls
import QtQuick.Controls.impl
import QtQuick.Templates as T
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard

T.Menu {
    id: control

    readonly property alias footerContent: footerLayout.children

    readonly property bool __hasIndicators: contentItem.contentItem.visibleChildren.some(menuItem => menuItem?.indicator?.visible ?? false)
    readonly property bool __hasIcons: contentItem.contentItem.visibleChildren.some(menuItem => __itemHasIcon(menuItem))
    readonly property bool __hasArrows: contentItem.contentItem.visibleChildren.some(menuItem => menuItem?.arrow?.visible ?? false)

    // palette: Kirigami.Theme.palette
    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            contentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             contentHeight + topPadding + bottomPadding)
    padding: 0
    margins: 0
    overlap: background && background.hasOwnProperty("border") ? background.border.width : 0
    z: Kirigami.OverlayZStacking.z

    function __itemHasIcon(item) {
        const hasName = (item?.icon?.name ?? "") !== ""
        const hasSource = (item?.icon?.source.toString() ?? "") !== ""
        return hasName || hasSource
    }

    // The default contentItem is a ListView, which has its own contentItem property,
    // so delegates will be created as children of control.contentItem.contentItem
    delegate: Controls.MenuItem {}

    contentItem: ColumnLayout {
        spacing: 0

        ListView {
            id: view

            spacing: 0
            implicitHeight: contentHeight - footerLayout.implicitHeight - 1
            // Cannot use `contentWidth` as this only accounts for Actions, not MenuItems or MenuSeparators
            implicitWidth: contentItem.visibleChildren.reduce((maxWidth, child) => Math.max(maxWidth, child.implicitWidth), 0)
            model: control.contentModel
            // For some reason, `keyNavigationEnabled: true` isn't needed and
            // using it causes separators and disabled items to be highlighted
            keyNavigationWraps: true

            // Makes it so you can't drag/flick the list view around unless the menu is taller than the window
            interactive: Window.window ? view.implicitHeight + control.topPadding + control.bottomPadding > Window.window.height : false
            clip: interactive // Only needed when the ListView can be dragged/flicked
            currentIndex: control.currentIndex || 0

            Controls.ScrollBar.vertical: Controls.ScrollBar {
                visible: view.interactive
            }

            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        FormCard.FormDelegateSeparator {}

        RowLayout {
            id: footerLayout
            spacing: Kirigami.Units.smallSpacing

            Layout.fillWidth: true
        }
    }

    enter: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                easing.type: Easing.OutCubic
                duration: Kirigami.Units.shortDuration
            }
        }
    }

    exit: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "opacity"
                from: 1
                to: 0
                easing.type: Easing.InCubic
                duration: Kirigami.Units.shortDuration
            }
        }
    }

    background: Kirigami.ShadowedRectangle {
        radius: Kirigami.Units.cornerRadius
        implicitWidth: Kirigami.Units.gridUnit * 8
        color: Kirigami.Theme.backgroundColor

        border {
            color: Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, Kirigami.Theme.frameContrast)
            width: 1
        }

        shadow {
            xOffset: 0
            yOffset: 2
            color: Qt.rgba(0, 0, 0, 0.3)
            size: 8
        }

        Kirigami.Theme.inherit: false
        Kirigami.Theme.colorSet: Kirigami.Theme.View
    }
}
