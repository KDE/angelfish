// SPDX-FileCopyrightText: 2020 Rinigus <rinigus.git@gmail.com>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.3
import QtQuick.Layouts 1.0
import QtQuick.Controls 2.0 as Controls
import QtWebEngine 1.5

import org.kde.kirigami 2.5 as Kirigami
import org.kde.angelfish 1.0

Item {
    id: findInPage

    anchors {
        top: parent.bottom
        left: parent.left
        right: parent.right
    }
    height: Kirigami.Units.gridUnit * 3

    property bool active: false
    property int  buttonSize: Kirigami.Units.gridUnit * 2

    Rectangle { anchors.fill: parent; color: Kirigami.Theme.backgroundColor; }

    RowLayout {
        id: layout
        anchors.fill: parent
        anchors.leftMargin: Kirigami.Units.gridUnit / 2
        anchors.rightMargin: Kirigami.Units.gridUnit / 2

        spacing: Kirigami.Units.smallSpacing
        Kirigami.Theme.inherit: true

        Controls.TextField {
            id: input

            Kirigami.Theme.inherit: true
            Layout.fillWidth: true
            leftPadding: index.anchors.rightMargin
            rightPadding: index.width + 2 * index.anchors.rightMargin
            inputMethodHints: rootPage.privateMode ? Qt.ImhNoPredictiveText : Qt.ImhNone
            placeholderText: i18nc("@info:placeholder", "Search…")

            onAccepted: currentWebView.findText(displayText)
            onDisplayTextChanged: currentWebView.findText(displayText)
            Keys.onEscapePressed: findInPage.active = false

            color: currentWebView.findInPageResultCount == 0 ? Kirigami.Theme.neutralTextColor : Kirigami.Theme.textColor

            Controls.Label {
                id: index
                anchors.right: parent.right
                anchors.rightMargin: Kirigami.Units.gridUnit / 2
                anchors.verticalCenter: parent.verticalCenter
                text: "%1 / %2".arg(currentWebView.findInPageResultIndex).arg(currentWebView.findInPageResultCount)
                verticalAlignment: Text.AlignVCenter
                Kirigami.Theme.inherit: true
                color: Kirigami.Theme.disabledTextColor
                visible: input.displayText
            }
        }

        Controls.ToolButton {
            Kirigami.Theme.inherit: true
            Layout.preferredWidth: buttonSize
            Layout.preferredHeight: buttonSize

            icon.name: "go-up"

            onClicked: currentWebView.findText(input.displayText, WebEngineView.FindBackward)
        }

        Controls.ToolButton {
            Kirigami.Theme.inherit: true
            Layout.preferredWidth: buttonSize
            Layout.preferredHeight: buttonSize

            icon.name: "go-down"

            onClicked: currentWebView.findText(input.displayText)
        }

        Controls.ToolButton {
            Kirigami.Theme.inherit: true
            Layout.preferredWidth: buttonSize
            Layout.preferredHeight: buttonSize

            icon.name: "window-close"
            onClicked: findInPage.active = false
        }
    }

    states: [
        State {
            name: "shown"
            when: findInPage.active
            AnchorChanges {
                target: findInPage
                anchors.bottom: findInPage.parent.bottom
                anchors.top: undefined
            }
        },
        State {
            name: "hidden"
            AnchorChanges {
                target: findInPage
                anchors.bottom: undefined
                anchors.top: findInPage.parent.bottom
            }
        }
    ]

    onActiveChanged: {
        if (!active)
            input.text = '';
        else
            input.forceActiveFocus();
    }

    function activate() {
        active = true;
        input.forceActiveFocus()
    }
}
