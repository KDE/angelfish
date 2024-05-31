// SPDX-FileCopyrightText: 2021 Jonah Brüchert <jbb@kaidan.im>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.angelfish
import org.kde.kirigamiaddons.formcard as FormCard

FormCard.FormCardPage {
    id: root

    title: i18n("Web Apps")

    FormCard.FormHeader {
        title: root.title
    }

    FormCard.FormCard {
        id: card

        Repeater {
            id: listView
            model: WebAppManagerModel {
                id: webAppModel
            }

            delegate: FormCard.AbstractFormDelegate {
                id: delegate

                required property int index;
                required property string desktopIcon;
                required property string name;
                required property string url;

                background: null
                contentItem: RowLayout {
                    id: layout

                    spacing: Kirigami.Units.largeSpacing

                    Kirigami.Icon {
                        Layout.rightMargin: Kirigami.Units.largeSpacing + Kirigami.Units.smallSpacing
                        source: delegate.desktopIcon
                        implicitWidth: Kirigami.Units.iconSizes.small
                        implicitHeight: Kirigami.Units.iconSizes.small
                    }

                    ColumnLayout{
                        spacing: Kirigami.Units.smallSpacing

                        Controls.Label {
                            Layout.fillWidth: true
                            text: delegate.name
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
                        icon.name: "delete"
                        display: Controls.AbstractButton.IconOnly
                        onClicked: webAppModel.removeApp(delegate.index)
                        text: i18n("Remove app")

                        Layout.leftMargin: Kirigami.Units.smallSpacing
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
