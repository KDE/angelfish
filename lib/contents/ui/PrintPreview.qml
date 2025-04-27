// SPDX-FileCopyrightText: 2023 Michael Lang <criticaltemp@protonmail.com>
//
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Effects
import QtWebEngine

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard

import org.kde.angelfish.core as Core

QQC2.Dialog {
    id: printPreview

    required property WebView webView

    parent: webView

    anchors.centerIn: parent
    width: Math.min(parent.width - Kirigami.Units.gridUnit * 4, Kirigami.Units.gridUnit * 60)
    height: Math.min(parent.height - Kirigami.Units.gridUnit * 4, Kirigami.Units.gridUnit * 40)

    leftPadding: 0
    topPadding: 0
    rightPadding: 0
    bottomPadding: 0

    modal: true

    title: i18nc("@title:window", "Print")

    header: null

    contentItem: Loader {
        active: printPreview.opened
        sourceComponent: RowLayout {
            spacing: 0

            Rectangle {
                Layout.preferredWidth: webView.width / 2
                Layout.fillHeight: true
                Layout.fillWidth: true

                Kirigami.Theme.colorSet: Kirigami.Theme.Window
                Kirigami.Theme.inherit: false

                color: Kirigami.Theme.backgroundColor

                WebEngineView {
                    id: webEnginePreview
                    visible: !webView.generatingPdf
                    anchors.fill: parent
                    url: webView.printPreviewUrl
                    onContextMenuRequested: request => request.accepted = true // disable context menu
                    onPdfPrintingFinished: printPreview.close()

                    settings {
                        pluginsEnabled: true
                        pdfViewerEnabled: true
                        javascriptEnabled: false
                    }
                }

                QQC2.BusyIndicator {
                    visible: webView.generatingPdf
                    anchors.centerIn: parent
                }
            }

            Kirigami.Separator {
                Layout.fillHeight: true
            }

            ColumnLayout {
                spacing: 0

                Layout.preferredWidth:  Kirigami.Units.gridUnit * 14
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignTop

                FormCard.FormHeader {
                    title: i18nc("@title:group", "Destination")
                }

                FormCard.FormTextDelegate {
                    text: i18nc("@title:group", "Save to PDF")
                }

                FormCard.FormDelegateSeparator {
                    above: Item {}
                    below: Item {}
                }

                FormCard.FormHeader {
                    title: i18nc("@title:group", "Orientation")
                }

                FormCard.FormRadioDelegate {
                    text: "Portrait"
                    checked: webView.printedPageOrientation === WebEngineView.Portrait
                    onClicked: {
                        webView.printedPageOrientation = WebEngineView.Portrait;
                        webView.printRequested();
                    }
                }
                FormCard.FormRadioDelegate {
                    text: "Landscape"
                    checked: webView.printedPageOrientation === WebEngineView.Landscape
                    onClicked: {
                        webView.printedPageOrientation = WebEngineView.Landscape;
                        webView.printRequested();
                    }
                }

                FormCard.FormDelegateSeparator {
                    above: Item {}
                }

                FormCard.FormComboBoxDelegate {
                    text: i18nc("@label:combobox", "Paper Size")
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
                        webView.printedPageSizeId = currentValue;
                        webView.printRequested();
                    }

                    Component.onCompleted: currentIndex = indexOfValue(webView.printedPageSizeId)
                }

                FormCard.FormDelegateSeparator {}

                FormCard.FormHeader {
                    title: i18nc("@title:group", "Options")
                }

                FormCard.FormCheckDelegate {
                    text: i18nc("@label:checkbox", "Print backgrounds")
                    checked: webView.settings.printElementBackgrounds
                    onClicked: {
                        webView.settings.printElementBackgrounds = checked;
                        webView.printRequested();
                    }
                }

                Item { Layout.fillHeight: true }

                QQC2.ToolBar {
                    Layout.fillWidth: true
                    position: QQC2.ToolBar.Footer
                    contentItem: QQC2.DialogButtonBox {
                        standardButtons: QQC2.DialogButtonBox.Cancel | QQC2.DialogButtonBox.Save

                        onRejected: printPreview.close()
                        onAccepted: {
                            const filePath = Core.BrowserManager.downloadDirectory() + "/" + webView.title + ".pdf";
                            webEnginePreview.printToPdf(filePath, webEnginePreview.printedPageSizeId, webEnginePreview.printedPageOrientation);
                        }
                    }
                }
            }
        }
    }
}
