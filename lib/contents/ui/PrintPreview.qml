// SPDX-FileCopyrightText: 2023 Michael Lang <criticaltemp@protonmail.com>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtWebEngine

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard

import org.kde.angelfish.core as Core

Kirigami.OverlaySheet {
    id: printPreview
    parent: webEngineView
    topPadding: 0
    bottomPadding: 0
    leftPadding: 0
    rightPadding: 0

    header: Kirigami.Heading {
        text: i18nc("@title:window", "Print")
    }

    contentItem: Loader {
        active: printPreview.opened
        sourceComponent: RowLayout {
            height: webEngineView.height - printPreview.header.height - Kirigami.Units.largeSpacing * 4
            spacing: 1

            Item {
                Layout.preferredWidth: webEngineView.width / 2
                Layout.fillHeight: true

                WebEngineView {
                    id: webEnginePreview
                    visible: !webEngineView.generatingPdf
                    anchors.fill: parent
                    url: webEngineView.printPreviewUrl
                    settings.pluginsEnabled: true
                    settings.pdfViewerEnabled: true
                    settings.javascriptEnabled: false
                    onContextMenuRequested: request.accepted = true // disable context menu
                    onPdfPrintingFinished: printPreview.close()
                }

                QQC2.BusyIndicator {
                    visible: webEngineView.generatingPdf
                    anchors.centerIn: parent
                }
            }

            ColumnLayout {
                Layout.preferredWidth:  Kirigami.Units.gridUnit * 12
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignTop

                FormCard.FormCard {
                    Layout.fillWidth: true

                    FormCard.FormHeader {
                        title: i18nc("@title:group", "Destination")
                    }

                    FormCard.FormTextDelegate {
                        text: i18nc("@title:group", "Save to PDF")
                    }

                    FormCard.FormDelegateSeparator {}

                    FormCard.FormHeader {
                        title: i18nc("@title:group", "Orientation")
                    }

                    ColumnLayout {
                        FormCard.FormRadioDelegate {
                            text: "Portrait"
                            checked: webEngineView.printedPageOrientation === WebEngineView.Portrait
                            onClicked: {
                                webEngineView.printedPageOrientation = WebEngineView.Portrait;
                                webEngineView.printRequested();
                            }
                        }
                        FormCard.FormRadioDelegate {
                            text: "Landscape"
                            checked: webEngineView.printedPageOrientation === WebEngineView.Landscape
                            onClicked: {
                                webEngineView.printedPageOrientation = WebEngineView.Landscape;
                                webEngineView.printRequested();
                            }
                        }
                    }

                    FormCard.FormDelegateSeparator {}

                    FormCard.FormHeader {
                        title: i18nc("@title:group", "Paper Size")
                    }

                    FormCard.FormComboBoxDelegate {
                        textRole: "text"
                        valueRole: "value"
                        model: ListModel {
                            ListElement { text: "Executive"; value: WebEngineView.Executive }
                            ListElement { text: "Folio"; value: WebEngineView.Folio }
                            ListElement { text: "Ledger"; value: WebEngineView.Ledger }
                            ListElement { text: "Legal"; value: WebEngineView.Legal }
                            ListElement { text: "Letter"; value: WebEngineView.Letter }
                            ListElement { text: "Tabloid"; value: WebEngineView.Tabloid }
                            ListElement { text: "A0"; value: WebEngineView.A0 }
                            ListElement { text: "A1"; value: WebEngineView.A1 }
                            ListElement { text: "A2"; value: WebEngineView.A2 }
                            ListElement { text: "A3"; value: WebEngineView.A3 }
                            ListElement { text: "A4"; value: WebEngineView.A4 }
                            ListElement { text: "A5"; value: WebEngineView.A5 }
                            ListElement { text: "A6"; value: WebEngineView.A6 }
                            ListElement { text: "A7"; value: WebEngineView.A7 }
                            ListElement { text: "A8"; value: WebEngineView.A8 }
                            ListElement { text: "A9"; value: WebEngineView.A9 }
                            ListElement { text: "B0"; value: WebEngineView.B0 }
                            ListElement { text: "B1"; value: WebEngineView.B1 }
                            ListElement { text: "B2"; value: WebEngineView.B2 }
                            ListElement { text: "B3"; value: WebEngineView.B3 }
                            ListElement { text: "B4"; value: WebEngineView.B4 }
                            ListElement { text: "B5"; value: WebEngineView.B5 }
                            ListElement { text: "B6"; value: WebEngineView.B6 }
                            ListElement { text: "B7"; value: WebEngineView.B7 }
                            ListElement { text: "B8"; value: WebEngineView.B8 }
                            ListElement { text: "B9"; value: WebEngineView.B9 }
                            ListElement { text: "B10"; value: WebEngineView.B10 }
                        }
                        onActivated: {
                            webEngineView.printedPageSizeId = currentValue;
                            webEngineView.printRequested();
                        }

                        Component.onCompleted: currentIndex = indexOfValue(webEngineView.printedPageSizeId)
                    }

                    FormCard.FormDelegateSeparator {}

                    FormCard.FormHeader {
                        title: i18nc("@title:group", "Options")
                    }

                    FormCard.FormCheckDelegate {
                        text: i18nc("@label:checkbox", "Print backgrounds")
                        checked: webEngineView.settings.printElementBackgrounds
                        onClicked: {
                            webEngineView.settings.printElementBackgrounds = checked;
                            webEngineView.printRequested();
                        }
                    }
                }

                Item { Layout.fillHeight: true }

                Row {
                    spacing: Kirigami.Units.largeSpacing
                    QQC2.Button {
                        text: i18nc("@action:button", "Cancel")
                        onClicked: printPreview.close()
                    }

                    QQC2.Button {
                        text: i18nc("@action:button", "Save")
                        onClicked: {
                            const filePath = Core.BrowserManager.downloadDirectory() + "/" + webEngineView.title + ".pdf";
                            webEnginePreview.printToPdf(filePath, webEnginePreview.printedPageSizeId, webEnginePreview.printedPageOrientation);
                        }
                    }
                }
            }
        }
    }
}
