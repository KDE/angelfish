// SPDX-FileCopyrightText: 2014-2015 Sebastian Kügler <sebas@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.1
import QtQuick.Window 2.3
import QtQuick.Layouts 1.2
import Qt5Compat.GraphicalEffects
import Qt.labs.settings 1.0 as QtSettings
import QtWebEngine

import org.kde.kirigami 2.7 as Kirigami
import org.kde.angelfish 1.0

Kirigami.ApplicationWindow {
    id: webBrowser
    title: currentWebView.title

    minimumWidth: Kirigami.Units.gridUnit * 15
    minimumHeight: Kirigami.Units.gridUnit * 15

    pageStack.globalToolBar.showNavigationButtons: Kirigami.ApplicationHeaderStyle.NoNavigationButtons

    // Main Page
    pageStack.initialPage: Kirigami.Page {
        id: rootPage
        leftPadding: 0
        rightPadding: 0
        topPadding: 0
        bottomPadding: 0
        globalToolBarStyle: Kirigami.ApplicationHeaderStyle.None
        Kirigami.ColumnView.fillWidth: true
        Kirigami.ColumnView.pinned: true
        Kirigami.ColumnView.preventStealing: true

        property alias questions: questions

        WebAppView {
            // ID for compatibility with angelfish components
            id: currentWebView
            anchors.fill: parent
            url: BrowserManager.initialUrl
        }
        ErrorHandler {
            id: errorHandler

            errorString: currentWebView.errorString
            errorCode: currentWebView.errorCode

            anchors.fill: parent
            visible: currentWebView.errorDomain !== null
                     && currentWebView.errorDomain !== WebEngineLoadingInfo.HttpStatusCodeDomain
            onRefreshRequested: currentWebView.reload()
        }

        Loader {
            id: questionLoader

            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
        }

        Questions {
            id: questions

            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
        }

        // Container for the progress bar
        Item {
            id: progressItem

            height: Math.round(Kirigami.Units.gridUnit / 6)
            z: 99
            anchors {
                bottom: parent.bottom
                bottomMargin: -Math.round(height / 2)
                left: webBrowser.left
                right: webBrowser.right
            }

            opacity: currentWebView.loading ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Kirigami.Units.longDuration; easing.type: Easing.InOutQuad; } }

            Rectangle {
                color: Kirigami.Theme.highlightColor

                width: Math.round((currentWebView.loadProgress / 100) * parent.width)
                anchors {
                    top: parent.top
                    left: parent.left
                    bottom: parent.bottom
                }
            }
        }

        Loader {
            id: sheetLoader
        }
    }
}
