// SPDX-FileCopyrightText: 2021 Felipe Kinoshita <kinofhek@gmail.com>
// SPDX-FileCopyrightText: 2023 Michael Lang <criticaltemp@protonmail.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.19 as Kirigami

import org.kde.angelfish 1.0

RowLayout {
    id: tabsComponent
    spacing: 0

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
        visible: Settings.showTabBar || listview.count > 1
        Layout.fillWidth: true
        Layout.preferredHeight: footerItem.height
        model: tabs.model
        orientation: ListView.Horizontal
        currentIndex: tabs.currentIndex
        interactive: false
        boundsBehavior: Flickable.StopAtBounds
        headerPositioning: ListView.OverlayHeader
        header: Rectangle {
            z: 3
            height: parent.height
            width: listview.tabScroll ? height : 0
            color: Kirigami.Theme.backgroundColor

            QQC2.ToolButton {
                visible: listview.tabScroll
                enabled: !listview.atXBeginning
                icon.name: "arrow-left"
                onClicked: listview.flick(1000, 0)
                onDoubleClicked: listview.flick(5000, 0)
            }
        }

        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: listview.flick(event.angleDelta.y * 10, 0)
        }

        property int baseWidth: Kirigami.Units.gridUnit * 14
        property real tabWidth: baseWidth * Math.min(Math.max(listview.width / (baseWidth * (listview.count + 1)), 0.4), 1)
        property bool tabScroll: listview.tabWidth * listview.count > listview.width

        delegate: QQC2.ItemDelegate {
            id: control

            leftInset: 0
            rightInset: 0
            topInset: 0
            bottomInset: 0
            padding: 0

            hoverEnabled: true
            highlighted: ListView.isCurrentItem

            width: listview.tabWidth
            height: tabsComponent.height

            onClicked: {
                tabs.currentIndex = model.index;
            }

            background: Rectangle {
                implicitHeight: Kirigami.Units.gridUnit * 3 + Kirigami.Units.smallSpacing * 2
                color: control.highlighted ? Qt.lighter(Kirigami.Theme.backgroundColor, 1.1)
                    : (control.hovered ? Qt.darker(Kirigami.Theme.backgroundColor, 1.05)
                    : Kirigami.Theme.backgroundColor)
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

                    onClicked: (mouse) => {
                        if (mouse.button === Qt.MiddleButton) {
                            tabs.tabsModel.closeTab(model.index);
                        } else if (mouse.button === Qt.RightButton) {
                            tabMenu.index = model.index
                            if (tabMenu.visible) {
                                tabMenu.close()
                            } else {
                                tabMenu.popup(control)
                            }
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
                    text: tabs.itemAt(model.index).readerMode ?
                        i18n("Reader Mode: %1", tabs.itemAt(model.index).readerTitle)
                        : tabs.itemAt(model.index).title
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignLeft
                }

                QQC2.AbstractButton {
                    id: closeButton
                    
                    hoverEnabled: true
                    visible: control.highlighted || control.width > Kirigami.Units.gridUnit * 8
                    Layout.alignment: Qt.AlignRight
                    Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                    Layout.fillHeight: true
                    onClicked: tabs.tabsModel.closeTab(model.index)

                    background: Item {}

                    contentItem: Kirigami.Icon {
                        source: 'tab-close-symbolic'
                        isMask: closeButton.hovered
                        color: Kirigami.Theme.textColor
                        anchors.centerIn: parent
                        implicitWidth: Kirigami.Units.iconSizes.smallMedium
                        implicitHeight: Kirigami.Units.iconSizes.smallMedium
                    }

                    QQC2.ToolTip.visible: closeButton.hovered
                    QQC2.ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
                    QQC2.ToolTip.text: i18n("Close tab")
                }

                QQC2.ToolTip.visible: control.hovered
                QQC2.ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
                QQC2.ToolTip.text: titleLabel.text
            }
        }
        footerPositioning: listview.tabScroll ? ListView.OverlayFooter : ListView.InlineFooter
        footer: Rectangle {
            z: 3
            height: row.height
            width: row.width
            color: Kirigami.Theme.backgroundColor

            Row {
                id: row
                QQC2.ToolButton {
                    visible: listview.tabScroll
                    enabled: !listview.atXEnd
                    icon.name: "arrow-right"
                    onClicked: listview.flick(-1000, 0)
                    onDoubleClicked: listview.flick(-5000, 0)
                }
                QQC2.ToolButton {
                    icon.name: "list-add"
                    onClicked: tabs.tabsModel.newTab(Settings.newTabUrl)

                    QQC2.ToolTip.visible: hoverHandler.hovered
                    QQC2.ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
                    QQC2.ToolTip.text: i18n("Open a new tab")

                    HoverHandler {
                        id: hoverHandler
                        acceptedDevices: PointerDevice.Mouse | PointerDevice.Stylus
                    }
                }

            }
        }
        add: Transition {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Kirigami.Units.longDuration; easing.type: Easing.InQuad }
        }
        remove: Transition {
            NumberAnimation { property: "opacity"; to: 0; duration: Kirigami.Units.longDuration; easing.type: Easing.OutQuad }
        }
    }

    Rectangle {
        Layout.alignment: Qt.AlignRight
        z: 3
        height: listview.footerItem.height
        width: height
        color: Kirigami.Theme.backgroundColor

        QQC2.ToolButton {
            id: menuButton
            icon.name: "arrow-down"
            down: menu.visible
            onPressed: menu.visible ? menu.close() : menu.popup(tabsComponent.width, tabsComponent.y + menuButton.height)

            QQC2.ToolTip.visible: hoverHandler.hovered
            QQC2.ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
            QQC2.ToolTip.text: i18n("List all tabs")

            HoverHandler {
                id: hoverHandler
                acceptedDevices: PointerDevice.Mouse | PointerDevice.Stylus
            }
        }
    }

    QQC2.Menu {
        id: menu
        Instantiator {
            model: tabs.model
            onObjectAdded: (index, object) => menu.insertItem(index, object)
            onObjectRemoved: (index, object) => menu.removeItem(object)
            delegate: QQC2.MenuItem {
                icon.name: tabs.itemAt(model.index).icon
                text: tabs.itemAt(model.index).title
                onTriggered: {
                    tabs.currentIndex = model.index;
                    menu.close();
                }
            }
        }
    }

    QQC2.Menu {
        id: tabMenu
        property int index

        Kirigami.Action {
            text: i18n("New Tab")
            icon.name: "list-add"
            shortcut: "Ctrl+T"
            onTriggered: tabs.tabsModel.newTab(Settings.newTabUrl)
        }

        QQC2.MenuSeparator {}

        Kirigami.Action {
            text: i18n("Reload Tab")
            icon.name: "view-refresh"
            shortcut: "Ctrl+R"
            onTriggered: {
                currentWebView.reload();
            }
        }
        Kirigami.Action {
            text: i18n("Duplicate Tab")
            icon.name: "tab-duplicate"
            onTriggered: tabs.tabsModel.newTab(currentWebView.url)
        }

        QQC2.MenuSeparator {}

        Kirigami.Action {
            text: i18n("Bookmark Tab")
            icon.name: urlObserver.bookmarked ? "rating" : "rating-unrated"
            shortcut: "Ctrl+D"
            onTriggered: {
                const request = {
                    url: currentWebView.url,
                    title: currentWebView.title,
                    icon: currentWebView.icon
                }
                BrowserManager.addBookmark(request)
            }
        }

        QQC2.MenuSeparator {}

        Kirigami.Action {
            text: i18n("Close Tab")
            icon.name: "tab-close"
            onTriggered: tabs.tabsModel.closeTab(tabMenu.index)
        }
    }
}
