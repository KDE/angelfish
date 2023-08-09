// SPDX-FileCopyrightText: 2020 Jonah Brüchert <jbb@kaidan.im>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.7
import QtQuick.Layouts 1.0
import QtQuick.Controls 2.5 as Controls
import org.kde.kirigami 2.12 as Kirigami
import org.kde.kirigamiaddons.labs.mobileform 0.1 as MobileForm


import org.kde.angelfish 1.0

Kirigami.ScrollablePage {
    id: adblockSettings

    title: i18n("Adblock settings")

    Kirigami.Theme.colorSet: Kirigami.Settings.isMobile ? Kirigami.Theme.View : Kirigami.Theme.Window

    actions {
        main: Kirigami.Action {
            icon.name: "list-add"
            onTriggered: addSheet.open()
            enabled: AdblockUrlInterceptor.adblockSupported
        }
        right: Kirigami.Action {
            text: i18n("Update lists")
            icon.name: "view-refresh"
            enabled: AdblockUrlInterceptor.adblockSupported
            onTriggered: {
                adblockSettings.refreshing = true
                filterlistModel.refreshLists()
            }
        }
    }

    supportsRefreshing: true
    onRefreshingChanged: {
        if (refreshing) {
            filterlistModel.refreshLists();
        }
    }

    Kirigami.PlaceholderMessage {
        anchors.centerIn: parent
        visible: !AdblockUrlInterceptor.adblockSupported
        width: parent.width - (Kirigami.Units.largeSpacing * 4)

        text: i18n("The adblock functionality isn't included in this build.")
    }

    Kirigami.OverlaySheet {
        id: addSheet

        header: Kirigami.Heading { text: i18n("Add filterlist") }
        contentItem: ColumnLayout {
            Layout.preferredWidth: adblockSettings.width
            Controls.Label {
                Layout.fillWidth: true
                text: i18n("Name")
            }
            Controls.TextField {
                id: nameInput
                Layout.fillWidth: true
            }

            Controls.Label {
                Layout.fillWidth: true
                text: i18n("Url")
            }
            Controls.TextField {
                id: urlInput
                Layout.fillWidth: true
                inputMethodHints: Qt.ImhUrlCharactersOnly
            }

            Controls.Button {
                Layout.alignment: Qt.AlignRight
                text: i18n("Add")
                onClicked: {
                    filterlistModel.addFilterList(nameInput.text, urlInput.text)
                    adblockSettings.refreshing = true
                    filterlistModel.refreshLists()
                    addSheet.close()
                }
            }
        }
    }
    ColumnLayout {
        spacing: 0

        MobileForm.FormCard {
            visible: AdblockUrlInterceptor.adblockSupported
            id: card
            Layout.fillWidth: true

            contentItem: ColumnLayout {
                spacing: 0
                MobileForm.FormCardHeader{
                    title:adblockSettings.title
                }
                Repeater {
                    id: listView
                    model: AdblockFilterListsModel {
                        id: filterlistModel
                        onRefreshFinished: adblockSettings.refreshing = false
                    }

                    delegate: MobileForm.AbstractFormDelegate {

                        required property string displayName
                        required property url url
                        required property int index


                        implicitHeight: layout.implicitHeight
                        implicitWidth: card.implicitWidth

                        RowLayout {
                            id: layout
                            anchors.fill: parent
                            spacing: Kirigami.Units.largeSpacing
                            ColumnLayout{
                                Layout.leftMargin: 20
                                Layout.margins: 10
                                Controls.Label {
                                    Layout.fillWidth: true
                                    text: displayName
                                    elide: Text.ElideRight
                                }
                                Controls.Label {
                                    Layout.fillWidth: true
                                    text: url
                                    elide: Text.ElideRight
                                    color: Kirigami.Theme.disabledTextColor
                                }
                            }

                            Controls.ToolButton {
                                Layout.margins: 10
                                icon.name: "list-remove"
                                display: Controls.AbstractButton.IconOnly
                                onClicked:  filterlistModel.removeFilterList(index)
                                text: i18n("Remove this filter list")

                            }
                        }
                    }
                }
                MobileForm.FormDelegateSeparator { above: addSource}

                MobileForm.FormButtonDelegate {
                    id: addSource
                    text: i18n("add Filterlist")
                    leading: Kirigami.Icon{
                        source: "list-add"
                        implicitHeight: Kirigami.Units.gridUnit
                    }
                    onClicked: addSheet.open()

                }
            }
        }
    }
}
