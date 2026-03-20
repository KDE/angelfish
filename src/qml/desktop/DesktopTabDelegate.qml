// SPDX-FileCopyrightText: 2021 Felipe Kinoshita <kinofhek@gmail.com>
// SPDX-FileCopyrightText: 2023 Michael Lang <criticaltemp@protonmail.com>
// SPDX-FileCopyrightText: 2025 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

QQC2.ItemDelegate {
    id: control
    property var tab

    signal rightClicked()
    signal closeRequested()

    leftInset: 0
    rightInset: 0
    topInset: 0
    bottomInset: 0
    topPadding: 0
    bottomPadding: 0
    leftPadding: 0
    rightPadding: 0

    hoverEnabled: true
    highlighted: ListView.isCurrentItem

    background: Rectangle {
        implicitHeight: Kirigami.Units.gridUnit * 3 + Kirigami.Units.smallSpacing * 2
        color: control.highlighted ? Kirigami.Theme.backgroundColor
            : (control.hovered ? Qt.darker(Kirigami.Theme.backgroundColor, 1.05)
            : Kirigami.Theme.backgroundColor)

        Kirigami.Theme.inherit: false
        Kirigami.Theme.colorSet: control.highlighted ? Kirigami.Theme.Header : Kirigami.Theme.Window

        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            color: Kirigami.Theme.highlightColor
            height: 1
            visible: control.highlighted
        }

        Kirigami.Separator {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
        }

        MouseArea {
            anchors.fill: parent

            acceptedButtons: Qt.AllButtons

            onClicked: (mouse) => {
                if (mouse.button === Qt.MiddleButton) {
                    control.closeRequested();
                } else if (mouse.button === Qt.RightButton) {
                    control.rightClicked();
                }
            }
        }
    }

    contentItem: RowLayout {
        id: layout
        spacing: 0

        Kirigami.Icon {
            id: tabIcon
            Layout.leftMargin: Kirigami.Units.smallSpacing
            Layout.rightMargin: Kirigami.Units.smallSpacing
            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
            Layout.preferredWidth: Kirigami.Units.iconSizes.small
            Layout.preferredHeight: width
            source: control.tab.icon
        }

        QQC2.Label {
            id: titleLabel
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
            text: control.tab.readerMode ?
                i18nc("@label", "Reader mode: %1", control.tab.readerTitle)
                : control.tab.title
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignLeft
        }

        QQC2.ToolButton {
            id: closeButton

            hoverEnabled: true
            visible: control.highlighted || control.width > Kirigami.Units.gridUnit * 8
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            Layout.preferredWidth: height
            Layout.fillHeight: true
            Layout.topMargin: Kirigami.Units.smallSpacing / 2
            Layout.bottomMargin: Kirigami.Units.smallSpacing / 2
            Layout.rightMargin: Kirigami.Units.smallSpacing / 2
            onClicked: control.closeRequested()

            contentItem: Item {
                Kirigami.Icon {
                    anchors.centerIn: parent
                    source: "tab-close-symbolic"
                    width: Kirigami.Units.iconSizes.small
                    height: Kirigami.Units.iconSizes.small
                }
            }

            QQC2.ToolTip.visible: closeButton.hovered
            QQC2.ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
            QQC2.ToolTip.text: i18nc("@info:tooltip", "Close tab")
        }

        QQC2.ToolTip.visible: control.hovered
        QQC2.ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
        QQC2.ToolTip.text: titleLabel.text
    }
}
