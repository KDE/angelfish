/****************************************************************************
**
** Copyright (C) 2011 Nokia Corporation and/or its subsidiary(-ies).
** All rights reserved.
** Contact: Nokia Corporation (qt-info@nokia.com)
**
** This file is part of the QtDeclarative module of the Qt Toolkit.
**
** $QT_BEGIN_LICENSE:LGPL$
** No Commercial Usage
** This file contains pre-release code and may not be distributed.
** You may use this file in accordance with the terms and conditions
** contained in the Technology Preview License Agreement accompanying
** this package.
**
** GNU Lesser General Public License Usage
** Alternatively, this file may be used under the terms of the GNU Lesser
** General Public License version 2.1 as published by the Free Software
** Foundation and appearing in the file LICENSE.LGPL included in the
** packaging of this file.  Please review the following information to
** ensure the GNU Lesser General Public License version 2.1 requirements
** will be met: http://www.gnu.org/licenses/old-licenses/lgpl-2.1.html.
**
** In addition, as a special exception, Nokia gives you certain additional
** rights.  These rights are described in the Nokia Qt LGPL Exception
** version 1.1, included in the file LGPL_EXCEPTION.txt in this package.
**
** If you have questions regarding the use of this file, please contact
** Nokia at qt-info@nokia.com.
**
**
**
**
**
**
**
**
** $QT_END_LICENSE$
**
****************************************************************************/

import QtQuick 1.0
import org.kde.kdewebkit 0.1
import org.kde.plasma.components 0.1 as PlasmaComponents
import "LinkPopup.js" as LinkPopupHelper


Flickable {
    property alias title: webView.title
    property alias icon: webView.icon
    property alias progress: webView.progress
    property alias url: webView.url
    property alias rssFeeds: webView.rssFeeds
    property alias back: webView.back
    property alias stop: webView.stop
    property alias reload: webView.reload
    property alias forward: webView.forward

    signal newWindowRequested(string url)

    id: flickable
    width: parent.width
    contentWidth: Math.max(parent.width,webView.width)
    contentHeight: Math.max(parent.height,webView.height)
    interactive: (webView.flickingEnabled && ((webView.height > height) || (webView.width > width)))
    anchors.top: headerSpace.bottom
    anchors.bottom: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    pressDelay: 200

    onWidthChanged : {
        // Expand (but not above 1:1) if otherwise would be smaller that available width.
        if (width > webView.width*webView.contentsScale && webView.contentsScale < 1.0)
            webView.contentsScale = width / webView.width * webView.contentsScale;
    }


    WebView {
        id: webView
        objectName: "webViewImplementation"
        transformOrigin: Item.TopLeft
        //settings.pluginsEnabled: true

        //FIXME: glorious hack just to obtain a signal of the url of the new requested page
        newWindowComponent: Component {
            Item {
                id: newPageComponent

                WebView {
                    id: newWindow
                    onUrlChanged: {
                        if (url != "") {
                            flickable.newWindowRequested(url)

                            var newObject = Qt.createQmlObject('import QtQuick 1.0; Item {}', webView);
                            newPageComponent.parent = newObject
                            newObject.destroy()
                        }
                    }
                }
            }
        }

        newWindowParent: webView

        function fixUrl(url)
        {
            if (url == "") return url
            if (url[0] == "/") return "file://"+url
            if (url.indexOf(":")<0) {
                if (url.indexOf(".")<0 || url.indexOf(" ")>=0) {
                    // Fall back to a search engine; hard-code Wikipedia
                    return "http://en.wikipedia.org/w/index.php?search="+url
                } else {
                    return "http://"+url
                }
            }
            return url
        }

        url: fixUrl(webBrowser.urlString)
        smooth: false // We don't want smooth scaling, since we only scale during (fast) transitions
        focus: true

        onAlert: {
            console.log(message);
            alertDialog.text = message;
            alertDialog.open();
        }

        function doZoom(zoom,centerX,centerY)
        {
            if (centerX) {
                var sc = zoom*contentsScale;
                scaleAnim.to = sc;
                flickVX.from = flickable.contentX
                flickVX.to = Math.max(0,Math.min(centerX-flickable.width/2,webView.width*sc-flickable.width))
                finalX.value = flickVX.to
                flickVY.from = flickable.contentY
                flickVY.to = Math.max(0,Math.min(centerY-flickable.height/2,webView.height*sc-flickable.height))
                finalY.value = flickVY.to
                quickZoom.start()
            }
        }

        function handleLinkPressed(linkUrl, linkRect)
        {
            print("link pressed: " + linkUrl + " | " + linkRect.x + " " + linkRect.y + " " + linkRect.width + " " + linkRect.height);
            highlightRect.x = linkRect.x;
            highlightRect.y = linkRect.y;
            highlightRect.width = linkRect.width;
            highlightRect.height = linkRect.height;
        }

        function handleLinkPressAndHold(linkUrl, linkRect)
        {
            print("... and hold: " + linkUrl + " | " + linkRect.x + " " + linkRect.y + " " + linkRect.width + " " + linkRect.height);
//             highlightRect.x = linkRect.x;
//             highlightRect.y = linkRect.y;
//             highlightRect.width = linkRect.width;
//             highlightRect.height = linkRect.height;
            linkPopupLoader.source = "LinkPopup.qml";
            var linkPopup = linkPopupLoader.item;
            linkPopup.url = linkUrl
            linkPopup.linkRect.x = linkRect.x
            linkPopup.linkRect.y = linkRect.y
            linkPopup.linkRect.width = linkRect.width
            linkPopup.linkRect.height = linkRect.height
            linkPopup.state  = "expanded";
            print(" type: " + typeof(linkRect));
        }

        Rectangle {
            id: highlightRect
            color: "orange"
            opacity: 0.5
        }

        Loader { id: linkPopupLoader }

        Keys.onLeftPressed: webView.contentsScale -= 0.1
        Keys.onRightPressed: webView.contentsScale += 0.1

        preferredWidth: flickable.width
        preferredHeight: flickable.height
        contentsScale: 1
        onContentsSizeChanged: {
            // zoom out
            contentsScale = Math.min(1,flickable.width / contentsSize.width)
        }
        onUrlChanged: {
            // got to topleft
            flickable.contentX = 0
            flickable.contentY = 0
            if (url != null) {
                header.editUrl = url.toString();
            }
            //settings.pluginsEnabled = true;
            print(" XXX Plugins on? " + settings.pluginsEnabled);
        }
        onTitleChanged: {
            //print("title changed in flickable " + title);
            webBrowser.titleChanged();
        }
        onDoubleClick: {
            preferredWidth = flickable.width - 50;
            if (!heuristicZoom(clickX,clickY,2.0)) {
                var zf = flickable.width / contentsSize.width
                if (zf >= contentsScale)
                    zf = 2.0*contentsScale // zoom in (else zooming out)
                doZoom(zf,clickX*zf,clickY*zf)
            }
        }

        SequentialAnimation {
            id: quickZoom

            PropertyAction {
                target: webView
                property: "renderingEnabled"
                value: false
            }
            PropertyAction {
                target: flickable
                property: "smooth"
                value: false
            }
            ParallelAnimation {
                NumberAnimation {
                    id: scaleAnim
                    target: webView
                    property: "contentsScale"
                    // the to property is set before calling
                    easing.type: Easing.Linear
                    duration: 200
                }
                NumberAnimation {
                    id: flickVX
                    target: flickable
                    property: "contentX"
                    easing.type: Easing.Linear
                    duration: 200
                    from: 0 // set before calling
                    to: 0 // set before calling
                }
                NumberAnimation {
                    id: flickVY
                    target: flickable
                    property: "contentY"
                    easing.type: Easing.Linear
                    duration: 200
                    from: 0 // set before calling
                    to: 0 // set before calling
                }
            }
            // Have to set the contentXY, since the above 2
            // size changes may have started a correction if
            // contentsScale < 1.0.
            PropertyAction {
                id: finalX
                target: flickable
                property: "contentX"
                value: 0 // set before calling
            }
            PropertyAction {
                id: finalY
                target: flickable
                property: "contentY"
                value: 0 // set before calling
            }
            PropertyAction {
                target: webView
                property: "renderingEnabled"
                value: true
            }
            PropertyAction {
                target: flickable
                property: "smooth"
                value: true
            }
        }
        onZoomTo: doZoom(zoom,centerX,centerY)
        onClick: {
            if (linkPopupLoader.status == Loader.Ready) linkPopupLoader.item.state = "collapsed";
        }
        onLinkPressed: handleLinkPressed(linkUrl, linkRect)
        onLinkPressAndHold: handleLinkPressAndHold(linkUrl, linkRect)
    }

    PlasmaComponents.CommonDialog {
        id: alertDialog
        titleText: i18n("JavaScript Alert")
        buttonTexts: [i18n("Close")]
        onButtonClicked: close()

        property alias text: alertLabel.text

        content: PlasmaComponents.Label {
            anchors.margins: 12
            id: alertLabel
        }
    }

    Component.onCompleted: {
        back.enabled = false
        forward.enabled = false
        reload.enabled = false
        stop.enabled = false
    }
}
