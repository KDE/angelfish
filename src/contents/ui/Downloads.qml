// SPDX-FileCopyrightText: 2020 Jonah Brüchert <jbb@kaidan.im>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.0
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.4 as Controls

import QtWebEngine 1.7

import org.kde.kirigami 2.14 as Kirigami
import org.kde.angelfish 1.0

Kirigami.ScrollablePage {
    title: i18n("Downloads")
    Kirigami.ColumnView.fillWidth: false

    ListView {
        model: DownloadsModel {
            id: downloadsModel
        }
        Kirigami.PlaceholderMessage {
            anchors.centerIn: parent
            width: parent.width - (Kirigami.Units.largeSpacing * 4)
            visible: parent.count === 0
            text: i18n("No running downloads")
        }
        delegate: Kirigami.SwipeListItem {
            id: downloadDelegate
            required property WebEngineDownloadRequest download
            required property var mimeTypeIcon
            required property string fileName
            required property url url
            required property url downloadedFilePath

            required property int index

            onClicked: Qt.openUrlExternally(downloadDelegate.downloadedFilePath)
            actions: [
                Kirigami.Action {
                    text: i18n("Cancel")
                    icon.name: downloadDelegate.download.state === WebEngineDownloadRequest.DownloadInProgress ? "dialog-cancel" : "list-remove"
                    onTriggered: downloadsModel.removeDownload(index)
                },
                Kirigami.Action {
                    visible: !downloadDelegate.download.isPaused && downloadDelegate.download.state === WebEngineDownloadRequest.DownloadInProgress
                    text: i18n("Pause")
                    icon.name: "media-playback-pause"
                    onTriggered: downloadDelegate.download.pause()
                },
                Kirigami.Action {
                    visible: downloadDelegate.download.isPaused && downloadDelegate.download.state === WebEngineDownloadRequest.DownloadInProgress
                    text: i18n("Continue")
                    icon.name: "media-playback-start"
                    onTriggered: downloadDelegate.download.resume();
                }
            ]

            contentItem: RowLayout {
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
                    Controls.Label {
                        Layout.fillWidth: true
                        elide: Qt.ElideRight
                        text: downloadDelegate.url
                    }
                    Controls.ProgressBar {
                        Layout.fillWidth: true
                        visible: downloadDelegate.download.state === WebEngineDownloadRequest.DownloadInProgress
                        from: 0
                        value: downloadDelegate.download.receivedBytes
                        to: downloadDelegate.download.totalBytes
                    }
                    Controls.Label {
                        visible: downloadDelegate.download.state !== WebEngineDownloadRequest.DownloadInProgress
                        text: {
                            switch (downloadDelegate.download.state) {
                            case WebEngineDownloadRequest.DownloadRequested:
                                return i18nc("download state", "Starting…");
                            case WebEngineDownloadRequest.DownloadCompleted:
                                return i18n("Completed");
                            case WebEngineDownloadRequest.DownloadCancelled:
                                return i18n("Cancelled");
                            case WebEngineDownloadRequest.DownloadInterrupted:
                                return i18nc("download state", "Interrupted");
                            case WebEngineDownloadRequest.DownloadInProgress:
                                return i18nc("download state", "In progress")
                            }
                        }
                    }
                }
            }
        }
    }
}
