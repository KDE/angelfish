// SPDX-FileCopyrightText: 2014-2015 Sebastian Kügler <sebas@kde.org>
// SPDX-FileCopyrightText: 2021 Devin Lin <espidev@gmail.com>
// SPDX-FileCopyrightText: 2023 Michael Lang <criticaltemp@protonmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

import org.kde.kirigami as Kirigami

import org.kde.angelfish

Kirigami.Page {
    id: tabsRoot

    property int columns: width > 800 ? 4 : width > 600 ? 3 : 2
    property real ratio: applicationWindow().height / applicationWindow().width
    readonly property double itemWidth: applicationWindow().width / columns - Kirigami.Units.smallSpacing * 2
    readonly property double itemHeight: (itemWidth * ratio + Kirigami.Units.gridUnit) * columns / 4.0
    property int borderWidth: 2
    readonly property double fullZoomScale: (itemWidth - (borderWidth * 2)) / applicationWindow().width
    property double zoomValue: 1
    property double zoomScale: fullZoomScale + (zoomValue * (1 - fullZoomScale))
    readonly property int zoomSourceX: {
        let zoomGridX = tabs.currentIndex % (((applicationWindow().width - (Kirigami.Units.largeSpacing * 2)) / ((applicationWindow().width - (Kirigami.Units.largeSpacing * 2)) / (columns))));
        let oneMinusFullZoom = (1 - fullZoomScale);
        return (zoomGridX * ((itemWidth + Kirigami.Units.largeSpacing) / oneMinusFullZoom)) + (((Kirigami.Units.smallSpacing + borderWidth)) / oneMinusFullZoom);
    }
    readonly property int zoomSourceY: {
        let zoomGridY = Math.floor(tabs.currentIndex / (((applicationWindow().width - (Kirigami.Units.largeSpacing * 2)) / ((applicationWindow().width - (Kirigami.Units.largeSpacing * 2)) / (columns)))));
        let oneMinusFullZoom = (1 - fullZoomScale);
        return (zoomGridY * ((itemHeight + Kirigami.Units.largeSpacing) / oneMinusFullZoom)) + (((Kirigami.Units.gridUnit * 1.5) + (Kirigami.Units.smallSpacing + borderWidth) - grid.contentY) / oneMinusFullZoom);
    }
    readonly property int webHeight: (applicationWindow().height - rootPage.navHeight)
    readonly property int zoomTabHeight: {
        let fullItemHeight = (itemHeight - Kirigami.Units.gridUnit * 1.5)
        let zoomFromZero = (zoomScale - fullZoomScale)
        let zoomFactor = (zoomFromZero * (1 / (1 - fullZoomScale)))
        return webHeight * zoomFactor + (applicationWindow().width * (fullItemHeight / itemWidth)) * (1 - zoomFactor)

    }
    readonly property int zoomY: ((webHeight - (webHeight - zoomSourceY)) / webHeight) * (((webHeight - zoomTabHeight) / 2))

    property var tabsSheet
    property var sheet

    height: applicationWindow().height
    width: applicationWindow().width
    padding: 0

    Component.onCompleted: {
        tabs.itemAt(tabs.currentIndex).grabToImage(function(result) {convertedImage.source = result.url}, Qt.size(applicationWindow().width, webHeight))
    }

    Item {
        id: zoomTabImage
        width: applicationWindow().width
        height: zoomTabHeight

        y: zoomY

        transform: Scale { origin.x: zoomSourceX; origin.y: zoomSourceY - zoomY / (1 - fullZoomScale); xScale: zoomScale; yScale: zoomScale }
        z: 3
        visible: zoomAnimator.running ? true : false

        ShaderEffectSource {
            id: shaderTab
            live: false
            anchors.fill: parent
            sourceItem: tabs.itemAt(tabs.currentIndex)
        }

        Image {
            id: convertedImage
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            verticalAlignment: Image.AlignTop
        }
    }

    NumberAnimation on zoomValue {
        id: zoomAnimator
        running: true
        duration: Kirigami.Units.longDuration
        easing.type: Easing.OutCirc
        to: 0
        onFinished: {
            if (to == 1) {tabsSheet.close()}
        }
    }

    function openTab() {
        zoomAnimator.stop()
        shaderTab.visible = false;
        zoomAnimator.to = 1;
        zoomAnimator.start()
    }


    Flickable {
        id: flickable
        height: applicationWindow().height - (Kirigami.Units.largeSpacing * 7)
        width: applicationWindow().width
        scale: 1 - (zoomValue * 0.15)

        boundsMovement: Flickable.StopAtBounds
        boundsBehavior: Flickable.DragOverBounds
        flickDeceleration: 8000
        clip: true

        GridView {
            anchors.fill: parent
            id: grid
            currentIndex: tabs.currentIndex
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

                z: mouseArea.pressed || scaleAnimator.running ? 1 : 0

                property double sourceX: (index % (applicationWindow().width / grid.cellWidth)) * grid.cellWidth

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
                        scaleAnimator.to = 1.15;
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
                            convertedImage.visible = false
                            shaderItem.grabToImage(function(result) {convertedImage.source = result.url; convertedImage.visible = true;}, Qt.size(applicationWindow().width, webHeight))
                            tabsSheet.toggle();
                        }
                    }
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

                    z: 2

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
                                i18nc("@label", "Reader mode: %1", tabs.itemAt(index).readerTitle)
                                : tabs.itemAt(index).title
                                : ""
                                font.pointSize: Kirigami.Theme.defaultFont.pointSize - 2
                                elide: Text.ElideRight
                            }

                            QQC2.ToolButton {
                                Layout.alignment: Qt.AlignVCenter
                                Layout.preferredHeight: Kirigami.Units.gridUnit * 1.5
                                Layout.preferredWidth: height
                                onClicked: tabs.tabsModel.closeTab(index)
                                icon.name: 'tab-close-symbolic'

                                QQC2.ToolTip.visible: hoverHandler.hovered
                                QQC2.ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
                                QQC2.ToolTip.text: i18nc("@info:tooltip", "Close tab")

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
                            anchors.fill: parent
                            sourceRect: Qt.rect(0, 0, applicationWindow().width, webHeight)
                            visible: false

                            transform: Scale {yScale: webHeight / (applicationWindow().width * ((itemHeight - Kirigami.Units.gridUnit * 1.5) / itemWidth))}

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
