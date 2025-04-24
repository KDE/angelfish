// SPDX-FileCopyrightText: 2019 Simon Schmeisser <s.schmeisser@gmx.net>
// SPDX-FileCopyrightText: 2019 Jonah Brüchert <jbb@kaidan.im>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.angelfish
import org.kde.angelfish.core as Core

import "RegexWebUrl.js" as RegexWebUrl

Controls.Drawer {
    id: overlay
    dragMargin: 0
    edge: Qt.BottomEdge
    width: parent.width

    bottomPadding: 0
    topPadding: 0
    rightPadding: 0
    leftPadding: 0

    property int buttonSize: Kirigami.Units.gridUnit * 2
    property int fullHeight: 0.9 * rootPage.height
    property bool openedState: false

    contentHeight: fullHeight - topPadding - bottomPadding
    contentWidth: parent.width - rightPadding - leftPadding
    contentItem: Item {
        width: parent.width
        height: parent.height

        RowLayout {
            id: editRow
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            height: Kirigami.Units.gridUnit * 3
            width: parent.width - Kirigami.Units.gridUnit

            Controls.ToolButton {
                Layout.preferredWidth: buttonSize
                Layout.preferredHeight: buttonSize

                icon.name: "window-minimize"

                Kirigami.Theme.inherit: true

                onClicked: overlay.close()
            }

            Controls.TextField {
                id: urlInput

                Layout.fillWidth: true
                clip: true
                focus: false
                inputMethodHints: Qt.ImhUrlCharactersOnly | (rootPage.privateMode ? Qt.ImhNoPredictiveText : Qt.ImhNone)
                Kirigami.Theme.inherit: true

                onActiveFocusChanged: if (activeFocus) selectAll()
                onAccepted: applyUrl()
                onDisplayTextChanged: {
                    if (!openedState) return; // avoid filtering
                    if (displayText === "" || displayText.length > 2) {
                        urlFilter.filter = displayText;
                        timer.running = false;
                    }
                    else timer.running = true;
                }
                Keys.onEscapePressed: if (overlay.sheetOpen) overlay.close()

                Timer {
                    id: timer
                    repeat: false
                    interval: Math.max(1000, 3000 - urlInput.displayText.length * 1000)
                    onTriggered: urlFilter.filter = urlInput.displayText
                }

                function applyUrl() {
                    if (text.match(RegexWebUrl.re_weburl) || text.startsWith("chrome://")) {
                        currentWebView.url = Core.UrlUtils.urlFromUserInput(text);
                    } else {
                        currentWebView.url = Core.UrlUtils.urlFromUserInput(Core.AngelfishSettings.searchBaseUrl + text);
                    }
                    overlay.close();
                }
            }

            Controls.ToolButton {
                Layout.preferredWidth: buttonSize
                Layout.preferredHeight: buttonSize

                icon.name: "go-next"

                Kirigami.Theme.inherit: true

                onClicked: urlInput.applyUrl();
            }
        }

        ListView {
            id: listView

            anchors {
                bottom: parent.bottom
                left: parent.left
                right: parent.right
                top: editRow.bottom
            }

            boundsBehavior: Flickable.StopAtBounds
            clip: true

            delegate: UrlDelegate {
                highlightText: urlFilter.filter
                
                title: model.title
                subtitle: model.url
                
                showRemove: false

                icon {
                    name: model.iconName.length > 0 ? model.iconName : "internet-services"
                    width: Kirigami.Units.largeSpacing * 3
                    height: Kirigami.Units.largeSpacing * 3
                }

                onClicked: {
                    currentWebView.url = model.url;
                    overlay.close();
                }
            }

            model: Core.BookmarksHistoryModel {
                id: urlFilter
                active: openedState
                history: true
            }
        }
    }

    onOpened: {
        // check if the drawer was just slightly slided
        if (openedState) return;
        urlInput.text = currentWebView.requestedUrl;
        urlInput.forceActiveFocus();
        urlInput.selectAll();
        urlFilter.filter = "";
        openedState = true;
        listView.positionViewAtBeginning();
    }

    onClosed: {
        openedState = false;
        currentWebView.forceActiveFocus();
    }
}
