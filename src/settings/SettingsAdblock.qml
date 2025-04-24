// SPDX-FileCopyrightText: 2020 Jonah Brüchert <jbb@kaidan.im>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard

import org.kde.angelfish

FormCard.FormCardPage {
    id: adblockSettings

    title: i18nc("@title:window", "Adblock Settings")

    actions: [
        Kirigami.Action {
            icon.name: "list-add"
            onTriggered: addDialog.open()
            enabled: AdblockUrlInterceptor.adblockSupported
            text: i18nc("@info:tooltip", "Add filter list")
            displayHint: Kirigami.DisplayHint.IconOnly
        },
        Kirigami.Action {
            text: i18nc("@action:intoolbar", "Update Lists")
            icon.name: "view-refresh"
            enabled: AdblockUrlInterceptor.adblockSupported
            onTriggered: {
                adblockSettings.refreshing = true
                filterlistModel.refreshLists()
            }
        }
    ]

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

    FormCard.FormHeader {
        title: adblockSettings.title
    }

    FormCard.FormCard {
        id: card
        visible: AdblockUrlInterceptor.adblockSupported
        Layout.fillWidth: true

        Repeater {
            id: listView
            model: AdblockFilterListsModel {
                id: filterlistModel
                onRefreshFinished: adblockSettings.refreshing = false
                onResetAdblock: AdblockUrlInterceptor.resetAdblock()
            }

            delegate: FormCard.AbstractFormDelegate {
                id: delegate

                required property string displayName
                required property url url
                required property int index

                background: null
                contentItem: RowLayout {
                    spacing: Kirigami.Units.largeSpacing

                    ColumnLayout {
                        spacing: Kirigami.Units.smallSpacing

                        Controls.Label {
                            Layout.fillWidth: true
                            text: delegate.displayName
                            elide: Text.ElideRight
                        }

                        Controls.Label {
                            Layout.fillWidth: true
                            text: delegate.url
                            elide: Text.ElideRight
                            color: Kirigami.Theme.disabledTextColor
                        }
                    }

                    Controls.ToolButton {
                        icon.name: "list-remove"
                        display: Controls.AbstractButton.IconOnly
                        onClicked:  filterlistModel.removeFilterList(delegate.index)
                        text: i18nc("@info:tooltip", "Remove this filter list")

                        Layout.leftMargin: Kirigami.Units.smallSpacing
                    }
                }
            }
        }

        FormCard.FormDelegateSeparator { above: addSource; below: listView.itemAt(listView.count - 1) }

        FormCard.FormButtonDelegate {
            id: addSource
            text: i18nc("@action:button", "Add Filter List")
            leading: Kirigami.Icon{
                source: "list-add"
                implicitHeight: Kirigami.Units.gridUnit
            }
            onClicked: addDialog.open()

            FormCard.FormCardDialog {
                id: addDialog

                parent: adblockSettings.Controls.Overlay.overlay

                title: i18nc("@title:group", "Add Filter List")

                FormCard.FormTextFieldDelegate {
                    id: nameInput

                    label: i18nc("@label", "Name")
                    onAccepted: urlInput.accepted()
                }

                FormCard.FormDelegateSeparator {}

                FormCard.FormTextFieldDelegate {
                    id: urlInput

                    label: i18nc("@label", "URL")
                    inputMethodHints: Qt.ImhUrlCharactersOnly
                    onAccepted: addDialog.accepted()
                }

                standardButtons: Controls.DialogButtonBox.Save

                onAccepted: {
                    filterlistModel.addFilterList(nameInput.text, urlInput.text);
                    adblockSettings.refreshing = true;
                    filterlistModel.refreshLists();
                    addDialog.close();
                }
            }
        }
    }
}
