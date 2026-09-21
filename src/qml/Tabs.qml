// SPDX-FileCopyrightText: 2014-2015 Sebastian Kügler <sebas@kde.org>
// SPDX-FileCopyrightText: 2021 Devin Lin <espidev@gmail.com>
// SPDX-FileCopyrightText: 2023 Michael Lang <criticaltemp@protonmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.delegates as Delegates

import org.kde.angelfish

Kirigami.Page {
    id: tabsRoot

    property int columns: width > 800 ? 4 : width > 600 ? 3 : 2
    property real pageRatio: tabs.height / tabs.width
    property real ratio: pageRatio > 1 ? Math.sqrt(pageRatio) : pageRatio
    readonly property int itemWidth: (tabs.width / columns) -  Kirigami.Units.largeSpacing * 4
    readonly property int itemHeight: itemWidth * pageRatio
    readonly property int itemHeightClipped: itemWidth * ratio

    readonly property double fullZoomScale: itemWidth / tabs.width
    property double zoomValue: 1
    property double zoomScale: fullZoomScale + (zoomValue * (1 - fullZoomScale))
    readonly property int zoomSourceX: {
        let zoomGridX =  Kirigami.Units.largeSpacing * 2 + (tabs.currentIndex % columns) * grid.cellWidth;
        return (zoomGridX * (1 - zoomValue));
    }
    readonly property int zoomSourceY: {
        let zoomGridY = Kirigami.Units.gridUnit * 2 +  Kirigami.Units.largeSpacing  + Math.floor(tabs.currentIndex / columns) * grid.cellHeight;
        return ((zoomGridY - grid.contentY) * (1 - zoomValue));
    }
    readonly property int webHeight: (applicationWindow().height - rootPage.navHeight)

    property var tabsSheet
    property var sheet

    height: tabs.height
    width: tabs.width
    padding: 0

    Item {
        id: zoomTabImage
        width: tabs.width * zoomValue + itemWidth * (1 - zoomValue)
        height: tabs.height * zoomValue + itemHeightClipped * (1 - zoomValue)
        clip: true

        x: zoomSourceX
        y: zoomSourceY

        z: 3
        visible: zoomAnimator.running

        ShaderEffectSource {
            id: shaderTab
            live: parent.visible
            anchors.left: parent.left
            anchors.top: parent.top
            width: parent.width
            height: tabs.height * zoomValue + itemHeight * (1 - zoomValue)
            sourceItem: tabs.itemAt(tabs.currentIndex)
        }
    }

    NumberAnimation on zoomValue {
        id: zoomAnimator
        running: true
        duration: Kirigami.Units.longDuration
        easing.type: Easing.OutCubic
        to: 0
        onFinished: {
            if (to == 1) {tabsSheet.close()}
        }
    }

    function openTab() {
        zoomAnimator.stop()
        zoomAnimator.to = 1;
        zoomAnimator.start()
    }


    Flickable {
        id: flickable
        height: tabs.height
        width: tabs.width
        scale: 1 - (zoomValue * 0.15)
        opacity: 1 - zoomValue

        boundsMovement: Flickable.StopAtBounds
        boundsBehavior: Flickable.DragOverBounds
        flickDeceleration: 8000
        clip: true

        GridView {
            anchors.fill: parent
            id: grid
            currentIndex: tabs.currentIndex
            model: tabs.model
            cellWidth: itemWidth + Kirigami.Units.largeSpacing * 4
            cellHeight: itemHeightClipped + Kirigami.Units.gridUnit * 2 + Kirigami.Units.largeSpacing * 3

            add: Transition {
                NumberAnimation { property: "opacity"; from: 0; to: 1.0; duration: Kirigami.Units.shortDuration }
            }
            remove: Transition {
                NumberAnimation { property: "opacity"; from: 1.0; to: 0; duration: Kirigami.Units.shortDuration }
            }
            displaced: Transition {
                NumberAnimation { properties: "x"; duration: Kirigami.Units.longDuration; easing.type: Easing.InOutQuad}
                NumberAnimation { properties: "y"; duration: Kirigami.Units.longDuration; easing.type: Easing.InOutQuad}
            }

            delegate: QQC2.ItemDelegate {
                id: gridItem
                // taking care of spacing
                width: grid.cellWidth
                height: grid.cellHeight
                padding: Kirigami.Units.largeSpacing
                bottomPadding: padding

                z: mouseArea.pressed || scaleAnimator.running ? 1 : 0
                highlighted: tabs.currentIndex === index

                property double sourceX: (index % columns) * grid.cellWidth

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    drag.target: gridItem
                    drag.axis: "XAxis"
                    z: 0
                    drag.onActiveChanged: {
                        xAnimator.stop();
                        if (pressed) { return }
                        let rightThreshold = Math.min(gridItem.sourceX + grid.width * 0.45, grid.width + Kirigami.Units.gridUnit * 2);
                        let leftThreshold = Math.max(gridItem.sourceX - grid.width * 0.45, - Kirigami.Units.gridUnit * 2);
                        if (parent.x > rightThreshold) {
                            xAnimator.to = grid.width;
                        } else if (parent.x < leftThreshold) {
                            xAnimator.to = -grid.width;
                        } else {
                            xAnimator.to = gridItem.sourceX;
                        }
                        xAnimator.start();
                    }
                    onPressed: {
                        scaleAnimator.stop()
                        scaleAnimator.to = 0.9;
                        scaleAnimator.start()
                    }
                    onReleased: {
                        scaleAnimator.stop()
                        scaleAnimator.to = 1.0;
                        scaleAnimator.start()
                    }
                    onCanceled: {
                        scaleAnimator.stop()
                        scaleAnimator.to = 1.0;
                        scaleAnimator.start()
                    }
                    onPressAndHold: {
                        sheet.setSource("ShareSheet.qml")
                        sheet.item.url = currentWebView.url
                        sheet.item.inputTitle = currentWebView.title
                        sheet.item.open()
                        scaleAnimator.stop()
                        scaleAnimator.to = 1.0;
                        scaleAnimator.start()
                    }
                    onClicked: {
                        if (zoomAnimator.to != 1) {
                            tabs.currentIndex = index;
                            tabsSheet.toggle();
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.MiddleButton
                    onPressed: tabs.tabsModel.closeTab(model.index)
                }

                NumberAnimation on x {
                    id: xAnimator
                    running: false
                    duration: Kirigami.Units.longDuration
                    easing.type: Easing.OutQuad
                    to: gridItem.sourceX
                    onFinished: {
                        if (to != gridItem.sourceX) { // close tab
                            tabs.tabsModel.closeTab(index);
                        }
                    }
                }

                ScaleAnimator {
                    id: scaleAnimator
                    target: gridItem;
                    running: true
                    duration: Kirigami.Units.longDuration
                    easing.type: Easing.OutQuad
                    to: 1.0
                }

                contentItem: Column {
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.largeSpacing

                    clip: true

                    z: 2

                    Item {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width
                        height: Kirigami.Units.gridUnit * 2

                        RowLayout {
                            anchors.fill: parent
                            spacing: Kirigami.Units.smallSpacing

                            Image {
                                Layout.leftMargin: Kirigami.Units.largeSpacing
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
                                i18nc("@label", "Reader mode: %1", tabs.itemAt(index).readerTitle)
                                : tabs.itemAt(index).title
                                : ""
                                font.pointSize: Kirigami.Theme.defaultFont.pointSize
                                elide: Text.ElideRight
                            }

                            QQC2.ToolButton {
                                Layout.alignment: Qt.AlignVCenter
                                Layout.preferredHeight: parent.height
                                Layout.preferredWidth: height
                                onClicked: tabs.tabsModel.closeTab(index)
                                icon.name: 'tab-close-symbolic'

                                QQC2.ToolTip.visible: hovered
                                QQC2.ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
                                QQC2.ToolTip.text: i18nc("@info:tooltip", "Close tab")
                            }
                        }
                    }

                    Item {
                        id: tabItem
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: itemWidth
                        height: itemHeightClipped
                        clip: true

                        Image {
                            id: tabImage
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectCrop
                            verticalAlignment: Image.AlignTop
                        }

                        // ShaderEffectSource requires that corresponding WebEngineView is
                        // visible. Here, visibility is enabled while snapshot is taken and
                        // removed as soon as it is ready.
                        ShaderEffectSource {
                            id: shaderItem

                            live: false
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.top

                            width: itemWidth
                            height: itemHeight

                            sourceRect: Qt.rect(0, 0, tabs.width, tabs.height)
                            textureSize: Qt.size(itemWidth, itemHeight)

                            sourceItem: tabs.itemAt(index)

                            Component.onCompleted: {
                                sourceItem.readyForSnapshot = true;
                                scheduleUpdate();
                                shaderItem.grabToImage(function(result) {
                                    tabImage.source = result.url
                                    convertedImage.visible = true;
                                }, Qt.size(Math.round(applicationWindow().width / columns),
                                           Math.round(webHeight / columns)));
                            }

                            onScheduledUpdateCompleted: {
                                sourceItem.readyForSnapshot = false;
                            }
                        }
                    }
                }
            }
        }
    }
}
