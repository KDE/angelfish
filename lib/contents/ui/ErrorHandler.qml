// SPDX-FileCopyrightText: 2014-2015 Sebastian Kügler <sebas@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import QtWebEngine

import org.kde.kirigami as Kirigami

// Shown in place of the website when it failed to load, or when its certificate is waiting for the user's decision.
Item {
    id: errorHandler

    signal refreshRequested

    property var webView

    readonly property var certError: webView?.certErrors[0] ?? null
    readonly property bool hasLoadError: webView !== null && webView !== undefined
                                         && webView.errorDomain !== null
                                         && webView.errorDomain !== WebEngineLoadingInfo.HttpStatusCodeDomain

    visible: certError !== null || hasLoadError

    Kirigami.Theme.inherit: false
    Kirigami.Theme.colorSet: Kirigami.Theme.View

    Rectangle {
        anchors.fill: parent
        Kirigami.Theme.inherit: true
        color: Kirigami.Theme.backgroundColor
    }

    // Load error
    ColumnLayout {
        visible: errorHandler.certError === null
        spacing: Kirigami.Units.gridUnit
        anchors {
            fill: parent
            margins: Kirigami.Units.gridUnit
        }
        Kirigami.Heading {
            opacity: 0.3
            text: errorHandler.webView?.errorCode ?? ""
        }
        Kirigami.Heading {
            level: 3
            Layout.fillHeight: false
            text: i18nc("@title", "Error Loading the Page")
        }
        Controls.Label {
            Layout.fillWidth: true
            Layout.fillHeight: false
            wrapMode: Text.Wrap
            text: errorHandler.webView?.errorString ?? ""
        }
        Item {
            Layout.fillHeight: true
        }
        Controls.ToolButton {
            Layout.alignment: Qt.AlignHCenter
            text: i18nc("@action:intoolbar", "Retry")
            icon.name: "view-refresh"
            onClicked: errorHandler.refreshRequested()
        }
    }

    // Certificate error
    Controls.ScrollView {
        id: certErrorPage
        visible: errorHandler.certError !== null
        anchors.fill: parent
        contentWidth: availableWidth

        readonly property string reason: errorHandler.certErrorReason(errorHandler.certError)

        ColumnLayout {
            width: certErrorPage.availableWidth
            spacing: 0

            // Vertically center the content when it fits
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.max(Kirigami.Units.gridUnit,
                                                 (certErrorPage.availableHeight - certErrorContent.implicitHeight) / 2)
            }

            ColumnLayout {
                id: certErrorContent
                spacing: Kirigami.Units.largeSpacing
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                Layout.maximumWidth: Kirigami.Units.gridUnit * 26
                Layout.leftMargin: Kirigami.Units.gridUnit
                Layout.rightMargin: Kirigami.Units.gridUnit
                Layout.bottomMargin: Kirigami.Units.gridUnit

                Kirigami.Icon {
                    source: "security-low"
                    implicitWidth: Kirigami.Units.iconSizes.huge
                    implicitHeight: Kirigami.Units.iconSizes.huge
                    Layout.bottomMargin: Kirigami.Units.largeSpacing
                }

                Kirigami.Heading {
                    Layout.fillWidth: true
                    level: 1
                    wrapMode: Text.Wrap
                    text: "Connection Not Secure"
                }

                Controls.Label {
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    font.bold: true
                    text: errorHandler.certError ? new URL(errorHandler.certError.url.toString()).host : ""
                }

                Controls.Label {
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    text: certErrorPage.reason
                }

                Controls.Label {
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    text: errorHandler.certError?.overridable
                        ? "Someone could be trying to impersonate this website or intercept your connection. Only continue if you trust this network and website."
                        : "This website requires a secure connection, so it cannot be opened."
                }

                Controls.Label {
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    font: Kirigami.Theme.smallFont
                    color: Kirigami.Theme.disabledTextColor
                    visible: text !== "" && text !== certErrorPage.reason
                    text: errorHandler.certError?.description ?? ""
                }

                Controls.Button {
                    Layout.fillWidth: true
                    Layout.topMargin: Kirigami.Units.gridUnit
                    highlighted: true
                    icon.name: errorHandler.webView?.canGoBack ? "go-previous" : "dialog-cancel"
                    text: errorHandler.webView?.canGoBack ? "Go Back"
                                                          : i18nc("@action:button", "Cancel")
                    onClicked: {
                        const webView = errorHandler.webView;
                        webView.resolveCertificateError(false);
                        if (webView.canGoBack) {
                            webView.goBack();
                        }
                    }
                }

                Controls.Button {
                    Layout.fillWidth: true
                    flat: true
                    visible: errorHandler.certError?.overridable ?? false
                    text: "Continue Anyway (Unsafe)"
                    onClicked: errorHandler.webView.resolveCertificateError(true)
                }
            }
        }
    }

    function certErrorReason(error) {
        if (!error) {
            return "";
        }
        switch (error.type) {
        case WebEngineCertificateError.CertificateDateInvalid:
            return "The website's certificate has expired or is not yet valid.";
        case WebEngineCertificateError.CertificateAuthorityInvalid:
            return "The website's certificate could not be verified, because it was not issued by a trusted authority. It may be self-signed.";
        case WebEngineCertificateError.CertificateCommonNameInvalid:
            return "The website's certificate belongs to a different website.";
        case WebEngineCertificateError.CertificateRevoked:
            return "The website's certificate has been revoked.";
        case WebEngineCertificateError.CertificateWeakSignatureAlgorithm:
        case WebEngineCertificateError.CertificateWeakKey:
            return "The website's certificate uses weak security.";
        default:
            return error.description;
        }
    }
}
