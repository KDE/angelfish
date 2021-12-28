// SPDX-FileCopyrightText: 2014-2015 Sebastian Kügler <sebas@kde.org>
// SPDX-FileCopyrightText: 2021 Devin Lin <espidev@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as Controls
import QtGraphicalEffects 1.0

//import QtWebEngine 1.0

import QtQuick.Layouts 1.0

import org.kde.kirigami 2.15 as Kirigami

import org.kde.angelfish 1.0

Kirigami.OverlayDrawer {
    id: tabsRoot
    
    height: contents.implicitHeight + Kirigami.Units.largeSpacing
    width: webBrowser.width
    edge: Qt.BottomEdge
    parent: applicationWindow().overlay
    
    onClosed: tabsSheetLoader.active = false // unload tabs when the sheet is closed

    property int itemHeight: Kirigami.Units.gridUnit * 6
    property int itemWidth: {
        if (!landscapeMode)
            return width - Kirigami.Units.smallSpacing * 2;
        // using grid width to take into account its scrollbar
        const n = Math.floor((grid.width - Kirigami.Units.largeSpacing) / (landscapeMinWidth + Kirigami.Units.largeSpacing));
        return Math.floor(grid.width / n) - Kirigami.Units.largeSpacing;
    }
    property int  landscapeMinWidth: Kirigami.Units.gridUnit * 12
    property bool landscapeMode: grid.width > landscapeMinWidth * 2 + 3 * Kirigami.Units.largeSpacing

    //Rectangle { anchors.fill: parent; color: "brown"; opacity: 0.5; }

    ColumnLayout {
        id: contents
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 0
        
        Kirigami.Icon {
            Layout.margins: Kirigami.Units.smallSpacing
            source: "arrow-down"
            implicitWidth: Kirigami.Units.gridUnit
            implicitHeight: Kirigami.Units.gridUnit
            Layout.alignment: Qt.AlignHCenter
        }
        
        RowLayout {
            Layout.maximumWidth: contents.tabsRoot.width - Kirigami.units.smallSpacing * 2
            Layout.leftMargin: Kirigami.Units.smallSpacing
            Layout.rightMargin: Kirigami.Units.smallSpacing
            Layout.bottomMargin: Kirigami.Units.smallSpacing
            Kirigami.Heading {
                level: 1
                elide: Text.ElideRight
                Layout.fillWidth: true
                text: rootPage.privateMode ? i18n("Private Tabs") : i18n("Tabs")
            }
            Controls.ToolButton {
                icon.name: "list-add"
                text: i18n("New Tab")
                onClicked: {
                    tabs.tabsModel.newTab("about:blank")
                    urlEntry.open();
                    tabsRoot.close();
                }
            }
            z: 1
        }
        
        Controls.ScrollView {
            id: scrollView
            Layout.fillWidth: true
            Layout.minimumHeight: Kirigami.Units.gridUnit * 12
            Layout.preferredHeight: applicationWindow().height * 0.6
            Layout.bottomMargin: Kirigami.Units.smallSpacing
            Layout.topMargin: Kirigami.Units.largeSpacing
            Controls.ScrollBar.horizontal.policy: Controls.ScrollBar.AlwaysOff
            
            GridView {
                id: grid
                model: tabs.model
                cellWidth: itemWidth + (landscapeMode ? Kirigami.Units.largeSpacing : 0)
                cellHeight: itemHeight + Kirigami.Units.largeSpacing
                clip: true
                
                add: Transition {
                    NumberAnimation { property: "opacity"; from: 0; to: 1.0; duration: Kirigami.Units.shortDuration }
                }
                remove: Transition {
                    NumberAnimation { property: "opacity"; from: 0; to: 1.0; duration: Kirigami.Units.shortDuration }
                }
                displaced: Transition {
                    NumberAnimation { properties: "x,y"; duration: Kirigami.Units.longDuration; easing.type: Easing.InOutQuad}
                }
                
                delegate: Controls.ItemDelegate {
                    id: gridItem
                    // taking care of spacing
                    width: grid.cellWidth
                    height: grid.cellHeight
                    
                    property int sourceX: (index % (grid.width / grid.cellWidth)) * grid.cellWidth
                    
                    DragHandler {
                        id: dragHandler
                        target: parent
                        yAxis.enabled: false
                        xAxis.enabled: true
                        onActiveChanged: {
                            xAnimator.stop();
                            
                            let rightThreshold = Math.min(gridItem.sourceX + grid.width * 0.5, grid.width + Kirigami.Units.gridUnit * 2);
                            let leftThreshold = Math.max(gridItem.sourceX - grid.width * 0.5, - Kirigami.Units.gridUnit * 2);
                            if (parent.x > rightThreshold) {
                                xAnimator.to = grid.width;
                            } else if (parent.x < leftThreshold) {
                                xAnimator.to = -grid.width;
                            } else {
                                xAnimator.to = gridItem.sourceX;
                            }
                            xAnimator.start();
                        }
                    }
                    NumberAnimation on x {
                        id: xAnimator
                        running: !dragHandler.active
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
                        print("Switch from " + tabs.currentIndex + "  to tab " + index);

                        tabs.currentIndex = index;
                        tabsRoot.close();
                    }
                    background: Item {}
                    
                    Item {
                        id: tabItem
                        anchors.centerIn: parent
                        width: itemWidth
                        height: itemHeight

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

                            LinearGradient {
                                id: grad
                                anchors.fill: parent
                                cached: true
                                start: Qt.point(0,0)
                                end: Qt.point(0,height)
                                gradient: Gradient {
                                    GradientStop { position: 0.4; color: "transparent"; }
                                    GradientStop { position: 1.3; color: "black"; }
                                }
                            }
                        }

                        Rectangle {
                            // border around a selected tile
                            anchors.fill: parent;
                            border.color: Kirigami.Theme.disabledTextColor
                            border.width: webBrowser.borderWidth
                            color: "transparent"
                            opacity: tabs.currentIndex === index ? 1.0 : 0.2
                        }

                        Rectangle {
                            // selection indicator
                            anchors.fill: parent
                            color: gridItem.pressed ? Kirigami.Theme.highlightColor : "transparent"
                            opacity: 0.2
                        }

                        Controls.ToolButton {
                            icon.name: "tab-close"
                            height: Kirigami.Units.gridUnit * 2
                            width: height
                            anchors.right: parent.right
                            anchors.rightMargin: Kirigami.Units.smallSpacing + Kirigami.Units.largeSpacing + (tabsRoot.landscapeMode ? 0 : tabsRoot.width-grid.width)
                            anchors.top: parent.top
                            anchors.topMargin: Kirigami.Units.smallSpacing
                            onClicked: tabs.tabsModel.closeTab(index)
                        }

                        Column {
                            id: label
                            anchors {
                                left: tabItem.left
                                right: tabItem.right
                                bottom: tabItem.bottom
                                bottomMargin: Kirigami.Units.smallSpacing
                                leftMargin: Kirigami.Units.largeSpacing
                                rightMargin: Kirigami.Units.largeSpacing
                            }
                            spacing: 0

                            Kirigami.Heading {
                                id: heading
                                elide: Text.ElideRight
                                level: 4
                                text: tabs.itemAt(index) ? tabs.itemAt(index).title : ""
                                width: label.width
                                color: "white"
                            }

                            Controls.Label {
                                elide: Text.ElideRight
                                font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.5
                                text: tabs.itemAt(index) ? tabs.itemAt(index).url : ""
                                width: label.width
                                color: "white"
                                visible: heading.text === ""
                            }
                        }

                        Image {
                            anchors {
                                bottom: tabItem.bottom
                                right: tabItem.right
                                bottomMargin: Kirigami.Units.smallSpacing
                                rightMargin: Kirigami.Units.smallSpacing + Kirigami.Units.largeSpacing + (tabsRoot.landscapeMode ? 0 : tabsRoot.width-grid.width)
                            }
                            fillMode: Image.PreserveAspectFit
                            height: Math.min(sourceSize.height, Kirigami.Units.gridUnit * 2)
                            source: tabs.itemAt(index) ? tabs.itemAt(index).icon : ""
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: grid.currentIndex = tabs.currentIndex
}
