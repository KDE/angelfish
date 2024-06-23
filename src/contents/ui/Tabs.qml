// SPDX-FileCopyrightText: 2014-2015 Sebastian Kügler <sebas@kde.org>
// SPDX-FileCopyrightText: 2021 Devin Lin <espidev@gmail.com>
// SPDX-FileCopyrightText: 2023 Michael Lang <criticaltemp@protonmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as QQC2

import org.kde.kirigami 2.19 as Kirigami
import org.kde.kirigamiaddons.components 1.0 as Components

import org.kde.angelfish 1.0

Components.BottomDrawer {
    id: tabsRoot

    property int columns: width > 800 ? 4 : width > 600 ? 3 : 2
    property real ratio: webBrowser.height / webBrowser.width
    readonly property int itemWidth: webBrowser.width / columns - Kirigami.Units.smallSpacing * 2
    readonly property int itemHeight: (itemWidth * ratio + Kirigami.Units.gridUnit) * columns / 4
    property bool firstItemDrag: true // prevents a gridview layout issue

    height: applicationWindow().height * 0.8
    width: applicationWindow().width
    edge: Qt.BottomEdge

    Component.onCompleted: grid.currentIndex = tabs.currentIndex

    onOpened: grid.width = width // prevents gridview layout issues
    onClosed: {
        tabsSheetLoader.active = false // unload tabs when the sheet is closed
        firstItemDrag = true
    }

    headerContentItem: RowLayout {
        Layout.maximumWidth: tabsRoot.width - Kirigami.Units.smallSpacing * 2
        Layout.leftMargin: Kirigami.Units.smallSpacing
        Layout.rightMargin: Kirigami.Units.smallSpacing
        Layout.bottomMargin: Kirigami.Units.smallSpacing
        z: 1
        Kirigami.Heading {
            text: i18n("Tabs")

        }
        Item { Layout.fillWidth: true }

        QQC2.ToolButton {
            icon.name: "list-add"
            text: i18n("New Tab")
            onClicked: {
                tabs.tabsModel.newTab("about:blank")
                tabs.tabsModel.setLatestTab()
                urlEntry.open();
                tabsRoot.close();
            }
        }
    }

    drawerContentItem: GridView {
        anchors.fill: parent
        id: grid
        clip: true
        model: tabs.model
        cellWidth: itemWidth + Kirigami.Units.largeSpacing
        cellHeight: itemHeight + Kirigami.Units.largeSpacing

        add: Transition {
            NumberAnimation { property: "opacity"; from: 0; to: 1.0; duration: Kirigami.Units.shortDuration }
        }
        remove: Transition {
            NumberAnimation { property: "opacity"; from: 0; to: 1.0; duration: Kirigami.Units.shortDuration }
        }
        displaced: Transition {
            NumberAnimation { properties: "x"; duration: Kirigami.Units.longDuration; easing.type: Easing.InOutQuad}
        }

        delegate: QQC2.ItemDelegate {
            id: gridItem
            // taking care of spacing
            width: grid.cellWidth
            height: grid.cellHeight
            padding: Kirigami.Units.smallSpacing + borderWidth
            clip: true

            property int sourceX: (index % (grid.width / grid.cellWidth)) * grid.cellWidth
            property int borderWidth: 2

            NumberAnimation on x {
                id: xAnimator
                running: !dragHandler.active && !firstItemDrag
                duration: Kirigami.Units.longDuration
                easing.type: Easing.InOutQuad
                to: gridItem.sourceX
                onFinished: {
                    if (to != gridItem.sourceX) { // close tab
                        tabs.tabsModel.closeTab(index);
                    }
                }
            }

            onClicked: {
                tabs.currentIndex = index;
                tabsRoot.close();
            }

            background: Item {
                anchors.centerIn: parent
                width: itemWidth
                height: itemHeight
                Rectangle {
                    // border around a selected tile
                    anchors.fill: parent;
                    border.color: tabs.currentIndex === index ? Kirigami.Theme.highlightColor : Kirigami.Theme.disabledTextColor
                    border.width: borderWidth
                    color: "transparent"
                    opacity: tabs.currentIndex === index ? 1.0 : 0.2
                }

                Rectangle {
                    // selection indicator
                    anchors.fill: parent
                    color: gridItem.pressed ? Kirigami.Theme.highlightColor : "transparent"
                    opacity: 0.2
                }
            }

            contentItem: Column {
                anchors.horizontalCenter: parent.horizontalCenter
                width: itemWidth - Kirigami.Units.smallSpacing

                Kirigami.Theme.inherit: false
                Kirigami.Theme.colorSet: Kirigami.Theme.Header

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: Kirigami.Theme.backgroundColor
                    width: itemWidth - Kirigami.Units.smallSpacing
                    height: Kirigami.Units.gridUnit * 1.5

                    RowLayout {
                        anchors.fill: parent
                        spacing: Kirigami.Units.smallSpacing

                        Image {
                            Layout.leftMargin: 2
                            Layout.alignment: Qt.AlignVCenter
                            Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                            Layout.preferredWidth: height
                            fillMode: Image.PreserveAspectFit
                            sourceSize: Qt.size(Kirigami.Units.iconSizes.smallMedium, Kirigami.Units.iconSizes.smallMedium)
                            source: tabs.itemAt(index) ? tabs.itemAt(index).icon : ""
                        }

                        QQC2.Label {
                            Layout.alignment: Qt.AlignVCenter
                            Layout.fillWidth: true
                            color: Kirigami.Theme.textColor
                            text: tabs.itemAt(index) ?
                            tabs.itemAt(index).readerMode ?
                            i18n("Reader Mode: %1", tabs.itemAt(index).readerTitle)
                            : tabs.itemAt(index).title
                            : ""
                            font.pointSize: Kirigami.Theme.defaultFont.pointSize - 2
                            elide: Text.ElideRight
                        }

                        QQC2.AbstractButton {
                            Layout.alignment: Qt.AlignVCenter
                            Layout.preferredHeight: Kirigami.Units.gridUnit * 1.5
                            Layout.preferredWidth: height
                            onClicked: tabs.tabsModel.closeTab(index)

                            background: Rectangle {
                                anchors.fill: parent
                                radius: height / 2
                                color: hoverHandler.hovered ? Kirigami.Theme.backgroundColor : Kirigami.Theme.disabledTextColor
                                border.width: 6
                                border.color: Kirigami.Theme.backgroundColor
                            }

                            contentItem: Kirigami.Icon {
                                source: "tab-close-symbolic"
                                color: hoverHandler.hovered ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.backgroundColor
                                anchors.centerIn: parent
                                implicitWidth: parent.width
                                implicitHeight: width
                            }

                            QQC2.ToolTip.visible: hoverHandler.hovered
                            QQC2.ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
                            QQC2.ToolTip.text: i18n("Close tab")

                            HoverHandler {
                                id: hoverHandler
                                acceptedDevices: PointerDevice.Mouse | PointerDevice.Stylus
                            }
                        }
                    }
                }

                Item {
                    id: tabItem
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: itemWidth - Kirigami.Units.smallSpacing
                    height: itemHeight - Kirigami.Units.gridUnit * 1.5 - Kirigami.Units.smallSpacing

                    // ShaderEffectSource requires that corresponding WebEngineView is
                    // visible. Here, visibility is enabled while snapshot is taken and
                    // removed as soon as it is ready.
                    ShaderEffectSource {
                        id: shaderItem

                        live: false
                        anchors.fill: parent
                        sourceRect: Qt.rect(0, 0, sourceItem.width, height/width * sourceItem.width)
                        sourceItem: tabs.itemAt(index)

                        Component.onCompleted: {
                            sourceItem.readyForSnapshot = true;
                            scheduleUpdate();
                        }
                        onScheduledUpdateCompleted: sourceItem.readyForSnapshot = false
                    }
                }
            }
        }
    }
}

