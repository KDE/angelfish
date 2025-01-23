// SPDX-FileCopyrightText: 2020 Jonah Brüchert <jbb@kaidan.im>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

import QtWebEngine

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.delegates as Delegates
import org.kde.angelfish 1.0

Kirigami.ScrollablePage {
    title: i18nc("@title:window", "Downloads")
    Kirigami.ColumnView.fillWidth: false

    ListView {
        currentIndex: -1 // don't select anything at start
        model: DownloadsModel {
            id: downloadsModel
        }
        Kirigami.PlaceholderMessage {
            anchors.centerIn: parent
            width: parent.width - (Kirigami.Units.largeSpacing * 4)
            visible: parent.count === 0
            text: i18nc("@info:placeholder", "No running downloads")
        }
        delegate: Delegates.RoundedItemDelegate {
            id: downloadDelegate

            required property WebEngineDownloadRequest download
            required property var mimeTypeIcon
            required property string fileName
            required property url url
            required property url downloadedFilePath

            required property int index

            onClicked: Qt.openUrlExternally(downloadDelegate.downloadedFilePath)

            contentItem: RowLayout {
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Icon {
                    source: downloadDelegate.mimeTypeIcon
                    height: Kirigami.Units.iconSizes.medium
                    width: height
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Kirigami.Heading {
                        Layout.fillWidth: true
                        level: 3
                        elide: Qt.ElideRight
                        text: downloadDelegate.fileName
                    }
                    QQC2.Label {
                        Layout.fillWidth: true
                        elide: Qt.ElideRight
                        text: downloadDelegate.url
                    }
                    QQC2.ProgressBar {
                        Layout.fillWidth: true
                        visible: downloadDelegate.download.state === WebEngineDownloadRequest.DownloadInProgress
                        from: 0
                        value: downloadDelegate.download.receivedBytes
                        to: downloadDelegate.download.totalBytes
                    }
                    QQC2.Label {
                        visible: downloadDelegate.download.state !== WebEngineDownloadRequest.DownloadInProgress
                        text: {
                            switch (downloadDelegate.download.state) {
                            case WebEngineDownloadRequest.DownloadRequested:
                                return i18nc("@info:progress", "Starting…");
                            case WebEngineDownloadRequest.DownloadCompleted:
                                return i18nc("@info:progress", "Completed");
                            case WebEngineDownloadRequest.DownloadCancelled:
                                return i18nc("@info:progress", "Cancelled");
                            case WebEngineDownloadRequest.DownloadInterrupted:
                                return i18nc("@info:progress", "Interrupted");
                            case WebEngineDownloadRequest.DownloadInProgress:
                                return i18nc("@info:progress", "In progress…")
                            }
                        }
                    }
                }

                QQC2.ToolButton {
                    text: i18nc("@info:tooltip", "Cancel")
                    display: QQC2.ToolButton.IconOnly
                    icon.name: downloadDelegate.download.state === WebEngineDownloadRequest.DownloadInProgress ? "dialog-cancel" : "list-remove"
                    onClicked: downloadsModel.removeDownload(index)

                    hoverEnabled: true
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
                    QQC2.ToolTip.text: text
                }
                QQC2.ToolButton {
                    visible: !downloadDelegate.download.isPaused && downloadDelegate.download.state === WebEngineDownloadRequest.DownloadInProgress
                    display: QQC2.ToolButton.IconOnly
                    text: i18c("@info:tooltip", "Pause")
                    icon.name: "media-playback-pause"
                    onClicked: downloadDelegate.download.pause()

                    hoverEnabled: true
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
                    QQC2.ToolTip.text: text
                }
                QQC2.ToolButton {
                    visible: downloadDelegate.download.isPaused && downloadDelegate.download.state === WebEngineDownloadRequest.DownloadInProgress
                    display: QQC2.ToolButton.IconOnly
                    text: i18nc("@info:tooltip", "Continue")
                    icon.name: "media-playback-start"
                    onClicked: downloadDelegate.download.resume();

                    hoverEnabled: true
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
                    QQC2.ToolTip.text: text
                }
            }
        }
    }
}
