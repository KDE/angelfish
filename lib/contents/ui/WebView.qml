// SPDX-FileCopyrightText: 2014-2015 Sebastian Kügler <sebas@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import QtWebEngine

import org.kde.kirigami 2.19 as Kirigami

import org.kde.angelfish 1.0

WebEngineView {
    id: webEngineView

    property string errorCode: ""
    property string errorString: ""

    property bool privateMode: false

    property alias userAgent: userAgent

    // loadingActive property is set to true when loading is started
    // and turned to false only after succesful or failed loading. It
    // is possible to set it to false by calling stopLoading method.
    //
    // The property was introduced as it triggers visibility of the webEngineView
    // in the other parts of the code. When using loading that is linked
    // to visibility, stop/start loading was observed in some conditions. It looked as if
    // there is an internal optimization of webengine in the case of parallel
    // loading of several pages that could use visibility as one of the decision
    // making parameters.
    property bool loadingActive: false

    // reloadOnVisible property ensures that the view has been always
    // loaded at least once while it is visible. When the view is loaded
    // while visible is set to false, there, what appears to be Chromium
    // optimizations that can disturb the loading.
    property bool reloadOnVisible: true

    // Profiles of WebViews are shared among all views of the same type (regular or
    // private). However, within each group of tabs, we can have some tabs that are
    // using mobile or desktop user agent. To avoid loading a page with the wrong
    // user agent, the agent is checked in the beginning of the loading at onLoadingChanged
    // handler. If the user agent is wrong, loading is stopped and reloadOnMatchingAgents
    // property is set to true. As soon as the agent is correct, the page is loaded.
    property bool reloadOnMatchingAgents: false

    // Used to follow whether agents match
    property bool agentsMatch: profile.httpUserAgent === userAgent.userAgent

    // URL that was requested and should be used
    // as a base for user interaction. It reflects
    // last request (successful or failed)
    property url requestedUrl: url

    property int findInPageResultIndex
    property int findInPageResultCount

    // Used to hide certain context menu items
    property bool isAppView: false

    // Used to track reader mode switch
    property bool readerMode: false

    // url to keep last url to return from reader mode
    property url readerSourceUrl

    // string to keep last title to return from reader mode
    property string readerTitle

    // Used for pdf generated to preview before print
    property url printPreviewUrl: ""
    property bool generatingPdf: false
    property int printedPageOrientation: WebEngineView.Portrait
    property int printedPageSizeId: WebEngineView.A4

    Shortcut {
        enabled: webEngineView.isFullScreen
        sequence: "Esc"
        onActivated: webEngineView.fullScreenCancelled();
    }

    // helper function to apply DomDistiller
    function readerDistillerRun() {
        readerSourceUrl = url
        runJavaScript(DomDistiller.script, function() {
                runJavaScript(DomDistiller.applyScript, function(result) {
                    loadHtml(result[2][1])
                    readerTitle = result[1]
                })
        })
    }

    // method to switch reader mode
    function readerModeSwitch() {
        if (readerMode) {
            url = readerSourceUrl
        } else {
            readerDistillerRun()
        }
    }

    UserAgentGenerator {
        id: userAgent
        onUserAgentChanged: webEngineView.reload()
    }

    settings {
        autoLoadImages: Settings.webAutoLoadImages
        javascriptEnabled: Settings.webJavaScriptEnabled
        // Disable builtin error pages in favor of our own
        errorPageEnabled: false
        // Load larger touch icons
        touchIconsEnabled: true
        // Disable scrollbars on mobile
        showScrollBars: !Kirigami.Settings.isMobile
        // Generally allow screen sharing, still needs permission from the user
        screenCaptureEnabled: true
        // Enables a web page to request that one of its HTML elements be made to occupy the user's entire screen
        fullScreenSupportEnabled: true
        // Turns on printing of CSS backgrounds when printing a web page
        printElementBackgrounds: false
    }

    focus: true
    onLoadingChanged: loadRequest => {
        //print("Loading: " + loading);
        print("    url: " + loadRequest.url + " " + loadRequest.status)
        //print("   icon: " + webEngineView.icon)
        //print("  title: " + webEngineView.title)

        /* Handle
        *  - WebEngineView::LoadStartedStatus,
        *  - WebEngineView::LoadStoppedStatus,
        *  - WebEngineView::LoadSucceededStatus and
        *  - WebEngineView::LoadFailedStatus
        */
        var ec = "";
        var es = "";
        if (loadRequest.status === WebEngineView.LoadStartedStatus) {
            if (profile.httpUserAgent !== userAgent.userAgent) {
                //print("Mismatch of user agents, will load later " + loadRequest.url);
                reloadOnMatchingAgents = true;
                stopLoading();
            } else {
                loadingActive = true;
            }
        }
        if (loadRequest.status === WebEngineView.LoadSucceededStatus) {
            if (!privateMode) {
                const request = {
                    url: currentWebView.url,
                    title: currentWebView.title,
                    icon: currentWebView.icon
                }

                BrowserManager.addToHistory(request);
                BrowserManager.updateLastVisited(currentWebView.url);
            }

            if (typeof AdblockUrlInterceptor === "undefined" || !AdblockUrlInterceptor.adblockSupported) {
                return;
            }

            let script = AdblockUrlInterceptor.getInjectedScript(webEngineView.url)
            if (script !== "") {
                webEngineView.runJavaScript(script)
            }

            webEngineView.runJavaScript(
`var elements = document.querySelectorAll("*[id]");
var ids = [];
for (var i in elements) {
    if (elements[i].id) {
        ids.push(elements[i].id)
    }
}
ids
`, (ids) => {
                webEngineView.runJavaScript(
`var elements = document.querySelectorAll("*[class]");
var classes = [];
for (var i in elements) {
    if (elements[i].className) {
        classes.push(elements[i].className);
    }
}
classes
`, (classes) => {
                    let selectors = AdblockUrlInterceptor.getCosmeticFilters(webEngineView.url, classes, ids)

                    for (var i = 0; i < selectors.length; i++) {
                        webEngineView.runJavaScript(
`{
    let adblockStyleElement = document.createElement("style")
    adblockStyleElement.type = "text/css"
    adblockStyleElement.textContent = '${selectors[i]} { display: none !important; }'
    document.head.appendChild(adblockStyleElement);
}`)
                    }
                })
            })
            loadingActive = false;
        }
        if (loadRequest.status === WebEngineView.LoadFailedStatus) {
            print("Load failed: " + loadRequest.errorCode + " " + loadRequest.errorString);
            print("Load failed url: " + loadRequest.url + " " + url);
            ec = loadRequest.errorCode;
            es = loadRequest.errorString;
            loadingActive = false;

            // update requested URL only after its clear that it fails.
            // Otherwise, its updated as a part of url property update.
            if (requestedUrl !== loadRequest.url)
                requestedUrl = loadRequest.url;
        }
        errorCode = ec;
        errorString = es;
    }

    Component.onCompleted: {
        print("WebView completed.");
        print("Settings: " + webEngineView.settings);
    }

    onIconChanged: {
        if (icon && !privateMode) {
            BrowserManager.updateIcon(url, icon)
        }
    }
    onNewWindowRequested: request => {
        if (request.userInitiated) {
            tabsModel.newTab(request.requestedUrl.toString())
            showPassiveNotification(i18n("Website was opened in a new tab"))
        } else {
            questionLoader.setSource("NewTabQuestion.qml")
            questionLoader.item.url = request.requestedUrl
            questionLoader.item.visible = true
        }
    }
    onUrlChanged: {
        if (requestedUrl !== url) {
            requestedUrl = url;
            // poor heuristics to update readerMode accordingly:
            readerMode = url.toString().startsWith("data:text/html")
        }
    }

    onFullScreenRequested: request => {
        if (request.toggleOn) {
            webBrowser.showFullScreen()
            const message = i18n("Entered Full Screen Mode")
            const actionText = i18n("Exit Full Screen (Esc)")
            showPassiveNotification(message, "short", actionText, function() { webEngineView.fullScreenCancelled() });
        } else {
            webBrowser.showNormal()
        }

        request.accept()
    }

    onContextMenuRequested: request => {
        request.accepted = true // Make sure QtWebEngine doesn't show its own context menu.
        contextMenu.request = request
        contextMenu.x = request.x
        contextMenu.y = request.y
        contextMenu.open()
    }

    onAuthenticationDialogRequested: request => {
        request.accepted = true
        sheetLoader.setSource("AuthSheet.qml")
        sheetLoader.item.request = request
        sheetLoader.item.open()
    }

    onFeaturePermissionRequested: (securityOrigin, feature) => {
        let newQuestion = rootPage.questions.newPermissionQuestion()
        newQuestion.permission = feature
        newQuestion.origin = securityOrigin
        newQuestion.visible = true
    }

    onJavaScriptDialogRequested: request => {
        request.accepted = true;
        sheetLoader.setSource("JavaScriptDialogSheet.qml");
        sheetLoader.item.request = request;
        sheetLoader.item.open();
    }

    onFindTextFinished: result => {
        findInPageResultIndex = result.activeMatch;
        findInPageResultCount = result.numberOfMatches;
    }

    onVisibleChanged: {
        if (visible && reloadOnVisible) {
            // see description of reloadOnVisible above for reasoning
            reloadOnVisible = false;
            reload();
        }
    }

    onAgentsMatchChanged: {
        if (agentsMatch && reloadOnMatchingAgents) {
            // see description of reloadOnMatchingAgents above for reasoning
            reloadOnMatchingAgents = false;
            reload();
        }
    }

    onCertificateError: error => {
        error.defer();
        errorHandler.enqueue(error);
    }

    function findInPageForward(text) {
        findText(text);
    }

    function stopLoading() {
        loadingActive = false;
        stop();
    }

    onPrintRequested: {
        printPreviewUrl = "";
        generatingPdf = true;
        const filePath = BrowserManager.tempDirectory() + "/print-preview.pdf";
        printToPdf(filePath, printedPageSizeId, printedPageOrientation);

        if (!printPreview.sheetOpen) {
            printPreview.open();
        }
    }

    onPdfPrintingFinished: (filePath, success) => {
        generatingPdf = false;
        printPreviewUrl = "file://" + filePath + "#toolbar=0&view=Fit";
    }

    PrintPreview {
        id: printPreview
    }

    onLinkHovered: hoveredUrl => hoveredLink.text = hoveredUrl

    QQC2.Label {
        id: hoveredLink
        visible: text.length > 0
        z: 2
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        leftPadding: Kirigami.Units.smallSpacing
        rightPadding: Kirigami.Units.smallSpacing
        color: Kirigami.Theme.textColor
        font.pointSize: Kirigami.Theme.defaultFont.pointSize - 1

        background: Rectangle {
            anchors.fill: parent
            color: Kirigami.Theme.backgroundColor
        }
    }

    QQC2.Menu {
        id: contextMenu
        property ContextMenuRequest request
        property bool isValidUrl: contextMenu.request && contextMenu.request.linkUrl != "" // not strict equality
        property bool isAudio: contextMenu.request && contextMenu.request.mediaType === ContextMenuRequest.MediaTypeAudio
        property bool isImage: contextMenu.request && contextMenu.request.mediaType === ContextMenuRequest.MediaTypeImage
        property bool isVideo: contextMenu.request && contextMenu.request.mediaType === ContextMenuRequest.MediaTypeVideo
        property real playbackRate: 100

        onAboutToShow: {
            if (webEngineView.settings.javascriptEnabled && (contextMenu.isAudio || contextMenu.isVideo)) {
                const point = contextMenu.request.x + ', ' + contextMenu.request.y
                const js = 'document.elementFromPoint(' + point + ').playbackRate * 100;'
                webEngineView.runJavaScript(js, function(result) { contextMenu.playbackRate = result })
            }
        }

        QQC2.MenuItem {
            visible: contextMenu.isAudio || contextMenu.isVideo
            height: visible ? implicitHeight : 0
            text: contextMenu.request && contextMenu.request.mediaFlags & ContextMenuRequest.MediaPaused
            ? i18n("Play")
            : i18n("Pause")
            onTriggered: webEngineView.triggerWebAction(WebEngineView.ToggleMediaPlayPause)
        }
        QQC2.MenuItem {
            visible: contextMenu.request && contextMenu.request.mediaFlags & ContextMenuRequest.MediaHasAudio
            height: visible ? implicitHeight : 0
            text:  contextMenu.request && contextMenu.request.mediaFlags & ContextMenuRequest.MediaMuted
            ? i18n("Unmute")
            : i18n("Mute")
            onTriggered: webEngineView.triggerWebAction(WebEngineView.ToggleMediaMute)
        }
        QQC2.MenuItem {
            visible: webEngineView.settings.javascriptEnabled && (contextMenu.isAudio || contextMenu.isVideo)
            height: visible ? implicitHeight : 0
            contentItem: RowLayout {
                QQC2.Label {
                    Layout.leftMargin: Kirigami.Units.largeSpacing
                    Layout.fillWidth: true
                    text: i18n("Speed")
                }
                QQC2.SpinBox {
                    Layout.rightMargin: Kirigami.Units.largeSpacing
                    value: contextMenu.playbackRate
                    from: 25
                    to: 1000
                    stepSize: 25
                    onValueModified: {
                        contextMenu.playbackRate = value
                        const point = contextMenu.request.x + ', ' + contextMenu.request.y
                        const js = 'document.elementFromPoint(' + point + ').playbackRate = ' + contextMenu.playbackRate / 100 + ';'
                        webEngineView.runJavaScript(js)
                    }
                    textFromValue: function(value, locale) {
                        return Number(value / 100).toLocaleString(locale, 'f', 2)
                    }
                }
            }
        }
        QQC2.MenuItem {
            visible: contextMenu.isAudio || contextMenu.isVideo
            height: visible ? implicitHeight : 0
            text: i18n("Loop")
            checked: contextMenu.request && contextMenu.request.mediaFlags & ContextMenuRequest.MediaLoop
            onTriggered: webEngineView.triggerWebAction(WebEngineView.ToggleMediaLoop)
        }
        QQC2.MenuItem {
            visible: webEngineView.settings.javascriptEnabled && contextMenu.isVideo
            height: visible ? implicitHeight : 0
            text: webEngineView.isFullScreen ? i18n("Exit fullscreen") : i18n("Fullscreen")
            onTriggered: {
                const point = contextMenu.request.x + ', ' + contextMenu.request.y
                const js = webEngineView.isFullScreen
                    ? 'document.exitFullscreen()'
                    : 'document.elementFromPoint(' + point + ').requestFullscreen()'
                webEngineView.runJavaScript(js)
            }
        }
        QQC2.MenuItem {
            visible: webEngineView.settings.javascriptEnabled && (contextMenu.isAudio || contextMenu.isVideo)
            height: visible ? implicitHeight : 0
            text: contextMenu.request && contextMenu.request.mediaFlags & ContextMenuRequest.MediaControls
            ? i18n("Hide controls")
            : i18n("Show controls")
            onTriggered: webEngineView.triggerWebAction(WebEngineView.ToggleMediaControls)
        }
        QQC2.MenuSeparator { visible: contextMenu.isAudio || contextMenu.isVideo }
        QQC2.MenuItem {
            visible: (contextMenu.isAudio || contextMenu.isVideo) && contextMenu.request.mediaUrl !== currentWebView.url
            height: visible ? implicitHeight : 0
            text: webEngineView.isAppView
                ? contextMenu.isVideo ? i18n("Open video") : i18n("Open audio")
                : contextMenu.isVideo ? i18n("Open video in new Tab") : i18n("Open audio in new Tab")
            onTriggered: {
                if (webEngineView.isAppView) {
                    Qt.openUrlExternally(contextMenu.request.mediaUrl);
                } else {
                    tabsModel.newTab(contextMenu.request.mediaUrl)
                }
            }
        }
        QQC2.MenuItem {
            visible: contextMenu.isVideo
            height: visible ? implicitHeight : 0
            text: i18n("Save video")
            onTriggered: webEngineView.triggerWebAction(WebEngineView.DownloadMediaToDisk)
        }
        QQC2.MenuItem {
            visible: contextMenu.isVideo
            height: visible ? implicitHeight : 0
            text: i18n("Copy video Link")
            onTriggered: webEngineView.triggerWebAction(WebEngineView.CopyMediaUrlToClipboard)
        }
        QQC2.MenuItem {
            visible: contextMenu.isImage && contextMenu.request.mediaUrl !== currentWebView.url
            height: visible ? implicitHeight : 0
            text: webEngineView.isAppView ? i18n("Open image") : i18n("Open image in new Tab")
            onTriggered: {
                if (webEngineView.isAppView) {
                    Qt.openUrlExternally(contextMenu.request.mediaUrl);
                } else {
                    tabsModel.newTab(contextMenu.request.mediaUrl)
                }
            }
        }
        QQC2.MenuItem {
            visible: contextMenu.isImage
            height: visible ? implicitHeight : 0
            text: i18n("Save image")
            onTriggered: webEngineView.triggerWebAction(WebEngineView.DownloadImageToDisk)
        }
        QQC2.MenuItem {
            visible: contextMenu.isImage
            height: visible ? implicitHeight : 0
            text: i18n("Copy image")
            onTriggered: webEngineView.triggerWebAction(WebEngineView.CopyImageToClipboard)
        }
        QQC2.MenuItem {
            visible: contextMenu.isImage
            height: visible ? implicitHeight : 0
            text: i18n("Copy image link")
            onTriggered: webEngineView.triggerWebAction(WebEngineView.CopyImageUrlToClipboard)
        }
        QQC2.MenuItem {
            visible: contextMenu.request && contextMenu.isValidUrl
            height: visible ? implicitHeight : 0
            text: webEngineView.isAppView ? i18n("Open link") : i18n("Open link in new Tab")
            onTriggered: {
                if (webEngineView.isAppView) {
                    Qt.openUrlExternally(contextMenu.request.linkUrl);
                } else {
                    webEngineView.triggerWebAction(WebEngineView.OpenLinkInNewTab)
                }
            }
        }
        QQC2.MenuItem {
            visible: contextMenu.request && contextMenu.isValidUrl
            height: visible ? implicitHeight : 0
            text: i18n("Bookmark link")
            onTriggered: {
                const bookmark = {
                    url: contextMenu.request.linkUrl,
                    title: contextMenu.request.linkText
                }
                BrowserManager.addBookmark(bookmark)
            }
        }
        QQC2.MenuItem {
            visible: contextMenu.request && contextMenu.isValidUrl
            height: visible ? implicitHeight : 0
            text: i18n("Save link")
            onTriggered: webEngineView.triggerWebAction(WebEngineView.DownloadLinkToDisk)
        }
        QQC2.MenuItem {
            visible: contextMenu.request && contextMenu.isValidUrl
            height: visible ? implicitHeight : 0
            text: i18n("Copy link")
            onTriggered: webEngineView.triggerWebAction(WebEngineView.CopyLinkToClipboard)
        }
        QQC2.MenuSeparator { visible: contextMenu.request && contextMenu.isValidUrl }
        QQC2.MenuItem {
            visible: contextMenu.request && (contextMenu.request.editFlags & ContextMenuRequest.CanCopy) && contextMenu.request.mediaUrl == ""
            height: visible ? implicitHeight : 0
            text: i18n("Copy")
            onTriggered: webEngineView.triggerWebAction(WebEngineView.Copy)
        }
        QQC2.MenuItem {
            visible: contextMenu.request && (contextMenu.request.editFlags & ContextMenuRequest.CanCut)
            height: visible ? implicitHeight : 0
            text: i18n("Cut")
            onTriggered: webEngineView.triggerWebAction(WebEngineView.Cut)
        }
        QQC2.MenuItem {
            visible: contextMenu.request && (contextMenu.request.editFlags & ContextMenuRequest.CanPaste)
            height: visible ? implicitHeight : 0
            text: i18n("Paste")
            onTriggered: webEngineView.triggerWebAction(WebEngineView.Paste)
        }
        QQC2.MenuItem {
            property string fullText: contextMenu.request ? contextMenu.request.selectedText || contextMenu.request.linkText : ""
            property string elidedText: fullText.length > 25 ? fullText.slice(0, 25) + "..." : fullText
            visible: contextMenu.request && fullText
            height: visible ? implicitHeight : 0
            text: contextMenu.request && fullText ? i18n('Search for "%1"', elidedText) : ""
            onTriggered: {
                if (webEngineView.isAppView) {
                    Qt.openUrlExternally(UrlUtils.urlFromUserInput(Settings.searchBaseUrl + fullText));
                } else {
                    tabsModel.newTab(UrlUtils.urlFromUserInput(Settings.searchBaseUrl + fullText));
                }
            }
        }
        QQC2.MenuSeparator { visible: !webEngineView.isAppView && contextMenu.request && contextMenu.request.mediaUrl != "" && !contextMenu.isValidUrl }
        QQC2.MenuItem {
            visible: !webEngineView.isAppView && contextMenu.request && contextMenu.request.selectedText === ""
            height: visible ? implicitHeight : 0
            text: i18n("Share page")
            onTriggered: {
                sheetLoader.setSource("ShareSheet.qml")
                sheetLoader.item.url = currentWebView.url
                sheetLoader.item.inputTitle = currentWebView.title
                Qt.callLater(sheetLoader.item.open)
            }
        }
        QQC2.MenuSeparator { visible: !webEngineView.isAppView }
        QQC2.MenuItem {
            visible: !webEngineView.isAppView
            height: visible ? implicitHeight : 0
            text: i18n("View page source")
            onTriggered: tabsModel.newTab("view-source:" + webEngineView.url)
        }
    }
}
