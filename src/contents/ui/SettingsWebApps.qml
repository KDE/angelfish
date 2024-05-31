// SPDX-FileCopyrightText: 2021 Jonah Brüchert <jbb@kaidan.im>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.3
import QtQuick.Controls 2.4 as Controls
import QtQuick.Layouts 1.11

import org.kde.kirigami as Kirigami
import org.kde.angelfish 1.0

import org.kde.kirigamiaddons.formcard 1.0 as FormCard

Kirigami.ScrollablePage {
    id: root
    leftPadding: 0
    rightPadding: 0
    topPadding: Kirigami.Units.gridUnit
    bottomPadding: Kirigami.Units.gridUnit

    title: i18n("Web Apps")

    Kirigami.Theme.colorSet: Kirigami.Settings.isMobile ? Kirigami.Theme.View : Kirigami.Theme.Window

    ColumnLayout {
        spacing: 0

        FormCard.FormHeader {
            title: root.title
        }

        FormCard.FormCard {
            id: card
            Layout.fillWidth: true

            Repeater {
                id: listView
                model: WebAppManagerModel {
                    id: webAppModel
                }

                delegate: FormCard.AbstractFormDelegate {
                    required property int index;
                    required property string desktopIcon;
                    required property string name;
                    required property string url;

                    implicitHeight: layout.implicitHeight
                    implicitWidth: card.implicitWidth

                    RowLayout {
                        id: layout
                        anchors.fill: parent
                        spacing: Kirigami.Units.largeSpacing
                        Kirigami.Icon {
                            Layout.leftMargin: 20
                            Layout.margins: 10
                            source: desktopIcon
                        }
                        ColumnLayout{
                            Layout.margins: 10
                            Controls.Label {
                                Layout.fillWidth: true
                                text: name
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
                            icon.name: "delete"
                            display: Controls.AbstractButton.IconOnly
                            onClicked: webAppModel.removeApp(index)
                            text: i18n("Remove app")
                        }
                    }
                }
            }

            FormCard.AbstractFormDelegate {
                visible: listView.count === 0
                background: null
                contentItem: Kirigami.PlaceholderMessage {
                    text: i18nc("placeholder message", "No Web Apps installed")
                }
            }
        }
    }
}
