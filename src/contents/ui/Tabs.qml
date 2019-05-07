/***************************************************************************
 *                                                                         *
 *   Copyright 2014-2015 Sebastian Kügler <sebas@kde.org>                  *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA .        *
 *                                                                         *
 ***************************************************************************/

import QtQuick 2.3
import QtQuick.Controls 2.0 as Controls

//import QtWebEngine 1.0

import QtQuick.Layouts 1.0

import org.kde.kirigami 2.0 as Kirigami
// import org.kde.plasma.components 2.0 as PlasmaComponents
// import org.kde.plasma.extras 2.0 as PlasmaExtras


Kirigami.ScrollablePage {

    id: tabsRoot

    title: i18n("Tabs")

    property int itemHeight: Math.round(itemWidth/ 3 * 2)
    property int itemWidth: Kirigami.Units.gridUnit * 9

    //Rectangle { anchors.fill: parent; color: "brown"; opacity: 0.5; }

    GridView {
        anchors.fill: parent
        model: tabs.model
        cellWidth: itemWidth
        cellHeight: itemHeight

        delegate: Item {
            id: tabItem
            width: itemWidth
            height: itemHeight
            ShaderEffectSource {
                id: shaderItem

                //live: true
                anchors.fill: parent
                anchors.margins: Kirigami.Units.gridUnit / 2

                sourceRect: Qt.rect(0, 0, width * 2, height * 2)

                sourceItem: {
                    tabs.itemAt(tabs.pageWidth * index, 0);
                }
                //opacity: tabs.currentIndex == index ? 1 : 0.0


                Behavior on height {
                    SequentialAnimation {
                        ScriptAction {
                            script: {
                                print("Animation start");
                                // switch to tabs
                            }
                        }
                        NumberAnimation { duration: Kirigami.Units.longDuration; easing.type: Easing.InOutQuad }
                        NumberAnimation { duration: Kirigami.Units.longDuration; easing.type: Easing.InOutQuad; target: contentView; property: opacity }
                        ScriptAction {
                            script: {
                                print("Animation done");
                                contentView.state = "hidden"
                            }
                        }
                    }
                }

                Behavior on width {
                    NumberAnimation { duration: Kirigami.Units.longDuration; easing.type: Easing.InOutQuad}

                }

            }
            Rectangle {
                anchors.fill: parent;
                anchors.margins: Kirigami.Units.gridUnit / 4;
                border.color: Kirigami.Theme.textColor;
                border.width: webBrowser.borderWidth
                color: "transparent"
                opacity: 0.3;
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    print("Switch from " + tabs.currentIndex + "  to tab " + index);

                    tabs.currentIndex = index;
                    tabs.positionViewAtIndex(index, ListView.Beginning);
                    //tabs.positionViewAtEnd();
                    pageStack.layers.pop()
                    return;

                    if (tabItem.width < tabsRoot.width) {
//                         tabItem.width = currentWebView.width
//                         tabItem.height = currentWebView.height
                    } else {
                        tabItem.width = itemWidth
                        tabItem.height = itemHeight
                    }
                }

            }

            Controls.ToolButton {
                icon.name: "window-close"
                height: Kirigami.gridUnit
                width: height
                anchors.right: parent.right
                anchors.rightMargin: Kirigami.Units.smallSpacing
                anchors.top: parent.top
                anchors.topMargin: Kirigami.Units.smallSpacing
                onClicked: tabs.closeTab(index)
            }
        }

        footer: Item {
            width: itemWidth
            height: itemHeight
            Kirigami.Icon {
                anchors.fill: parent
                anchors.margins: Math.round(itemHeight / 4)
                source: "list-add"
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    tabs.newTab(browserManager.homepage)
                    //addressBar.forceActiveFocus();
                    //addressBar.selectAll();
                    tabs.currentIndex = tabs.count - 1;
                    pageStack.layers.pop()
                }
            }
        }
    }
}
