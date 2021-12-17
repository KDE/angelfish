//SPDX-FileCopyrightText: 2021 Felipe Kinoshita <kinofhek@gmail.com>
//SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.19 as Kirigami

import org.kde.angelfish 1.0

RowLayout {
    id: tabsComponent

    Shortcut {
        sequences: ["Ctrl+Tab", "Ctrl+PgDown"]
        onActivated: {
            if (listview.currentIndex != listview.count -1) {
                tabs.currentIndex++;
            } else {
                tabs.currentIndex = 0;
            }
        }
    }
    Shortcut {
        sequences: ["Ctrl+Shift+Tab", "Ctrl+PgUp"]
        onActivated: {
            if (listview.currentIndex === 0) {
                tabs.currentIndex = listview.count - 1;
            } else {
                tabs.currentIndex--;
            }
        }
    }

    Shortcut {
        sequence: "Ctrl+W"
        onActivated: {
            tabs.tabsModel.closeTab(listview.currentIndex);
        }
    }

    Shortcut {
        sequence: "Ctrl+1"
        onActivated: {
            if (listview.currentIndex !== 0) {
                tabs.currentIndex = 0;
            }
        }
    }
    Shortcut {
        sequence: "Ctrl+2"
        onActivated: {
            if (listview.currentIndex !== 1) {
                tabs.currentIndex = 1;
            }
        }
    }
    Shortcut {
        sequence: "Ctrl+3"
        onActivated: {
            if (listview.currentIndex !== 2) {
                tabs.currentIndex = 2;
            }
        }
    }
    Shortcut {
        sequence: "Ctrl+4"
        onActivated: {
            if (listview.currentIndex !== 3) {
                tabs.currentIndex = 3;
            }
        }
    }
    Shortcut {
        sequence: "Ctrl+5"
        onActivated: {
            if (listview.currentIndex !== 4) {
                tabs.currentIndex = 4;
            }
        }
    }
    Shortcut {
        sequence: "Ctrl+6"
        onActivated: {
            if (listview.currentIndex !== 5) {
                tabs.currentIndex = 5;
            }
        }
    }
    Shortcut {
        sequence: "Ctrl+7"
        onActivated: {
            if (listview.currentIndex !== 6) {
                tabs.currentIndex = 6;
            }
        }
    }
    Shortcut {
        sequence: "Ctrl+8"
        onActivated: {
            if (listview.currentIndex !== 7) {
                tabs.currentIndex = 7;
            }
        }
    }
    Shortcut {
        sequence: "Ctrl+9"
        onActivated: {
            if (listview.currentIndex !== listview.count - 1) {
                tabs.currentIndex = listview.count - 1;
            }
        }
    }

    ListView {
        id: listview
        Layout.fillWidth: true
        Layout.preferredHeight: footerItem.height
        model: tabs.model
        orientation: ListView.Horizontal
        currentIndex: tabs.currentIndex
        delegate: QQC2.ItemDelegate {
            id: control

            highlighted: ListView.isCurrentItem

            width: Kirigami.Units.gridUnit * 15
            height: tabsComponent.height

            background: Rectangle {
                Kirigami.Theme.colorSet: Kirigami.Theme.Button
                Kirigami.Theme.inherit: false
                implicitHeight: Kirigami.Units.gridUnit * 3 + Kirigami.Units.smallSpacing * 2
                color: control.highlighted ? Kirigami.Theme.backgroundColor
                    : (control.hovered ? Qt.darker(Kirigami.Theme.backgroundColor, 1.05)
                    : Qt.darker(Kirigami.Theme.backgroundColor, 1.1))
                Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration } }

                QQC2.ToolSeparator {
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    orientation: Qt.Vertical
                }

                QQC2.ToolSeparator {
                    visible: index === 0
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    orientation: Qt.Vertical
                }

                MouseArea {
                    anchors.fill: parent

                    acceptedButtons: Qt.AllButtons

                    onClicked: {
                        if (mouse.button === Qt.LeftButton) {
                            tabs.currentIndex = model.index;
                        } else if (mouse.button === Qt.MiddleButton) {
                            tabs.tabsModel.closeTab(model.index);
                        }
                    }
                }
            }

            contentItem: RowLayout {
                id: layout
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Icon {
                    id: tabIcon
                    Layout.alignment: Qt.AlignLeft
                    Layout.preferredWidth: Kirigami.Units.iconSizes.small
                    Layout.preferredHeight: width
                    source: tabs.itemAt(model.index).icon
                }

                QQC2.Label {
                    id: titleLabel
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignLeft
                    Layout.leftMargin: Kirigami.Units.smallSpacing
                    Layout.rightMargin: Kirigami.Units.smallSpacing
                    text: tabs.itemAt(model.index).title
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignLeft
                }

                QQC2.ToolButton {
                    Layout.alignment: Qt.AlignRight
                    Layout.preferredWidth: Kirigami.Units.iconSizes.small
                    Layout.preferredHeight: width
                    icon.name: "tab-close"
                    onClicked: tabs.tabsModel.closeTab(model.index)

                    opacity: control.hovered ? 1 : 0
                    Behavior on opacity {
                        OpacityAnimator {
                            duration: Kirigami.Units.shortDuration
                            easing.type: Easing.InOutQuad
                        }
                    }
                }
            }
        }
        footer: QQC2.ToolButton {
            action: Kirigami.Action {
                icon.name: "list-add"
                onTriggered: tabs.tabsModel.newTab(Settings.newTabUrl)
            }
        }
        add: Transition {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Kirigami.Units.longDuration; easing.type: Easing.InQuad }
        }
        remove: Transition {
            NumberAnimation { property: "opacity"; to: 0; duration: Kirigami.Units.longDuration; easing.type: Easing.OutQuad }
        }
    }
}
