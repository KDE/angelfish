// SPDX-FileCopyrightText: 2014-2015 Sebastian Kügler <sebas@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.3
import QtQuick.Controls 2.0 as Controls
import QtQuick.Layouts 1.0
import QtWebEngine 1.1

import org.kde.kirigami 2.17 as Kirigami


Item {
    id: errorHandler

    signal refreshRequested
    signal certificateIgnored

    property var errorCode
    property alias errorString: errorDescription.text
    property var certErrors: []

    Kirigami.Theme.inherit: false
    Kirigami.Theme.colorSet: Kirigami.Theme.View

    Behavior on height { NumberAnimation { duration: Kirigami.Units.longDuration; easing.type: Easing.InOutQuad} }

    Rectangle {
        anchors.fill: parent
        Kirigami.Theme.inherit: true
        color: Kirigami.Theme.backgroundColor
    }

    ColumnLayout {
        spacing: Kirigami.Units.gridUnit
        anchors {
            fill: parent
            margins: Kirigami.Units.gridUnit
        }
        Kirigami.Heading {
            opacity: 0.3
            text: errorHandler.errorCode ?? ""
        }
        Kirigami.Heading {
            level: 3
            Layout.fillHeight: false
            text: i18nc("@title", "Error Loading the Page")
        }
        Controls.Label {
            id: errorDescription
            Layout.fillHeight: false
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
    Kirigami.OverlayDrawer {
        id: sslErrorDrawer
        edge: Qt.BottomEdge
        parent: applicationWindow().overlay

        ColumnLayout {
            width: parent.width
            Controls.Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: i18n( 
"Do you wish to continue?\n\n \
If you wish so, you may continue with an unverified certificate.\n \
Accepting an unverified certificate means you may not be connected with the host you tried to connect to.\n\n \
Do you wish to override the security check and continue?")
            }
            Controls.Button {
                Layout.alignment: Qt.AlignRight
                text: i18nc("@action:button", "Yes")
                onClicked: {
                    errorHandler.certErrors.shift().acceptCertificate();
                    errorHandler.certificateIgnored();
                    sslErrorDrawer.close();
                }
            }
            Controls.Button {
                Layout.alignment: Qt.AlignRight
                text: i18nc("@action:button", "No")
                onClicked: {
                    errorHandler.certErrors.shift().rejectCertificate();
                    sslErrorDrawer.close();
                }
            }
        }
    }

    function open(error) {
        certErrors.push(error);
        sslErrorDrawer.open();
    }

    function clear() {
        certErrors.certErrors = []
    }
}
