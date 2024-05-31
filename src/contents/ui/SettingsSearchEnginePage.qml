// SPDX-FileCopyrightText: 2020 Rinigus <rinigus.git@gmail.com>
// SPDX-FileCopyrightText: 2020 Jonah Brüchert  <jbb@kaidan.im>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard

import org.kde.angelfish

FormCard.FormCardPage {
    id: root

    title: i18n("Search Engine")

    property string baseUrl: Settings.searchBaseUrl
    property string customName: i18n("Custom")

    FormCard.FormHeader {
        title: root.title
    }

    FormCard.FormCard {
        Layout.fillWidth: true

        Repeater {
            model: ListModel {
                id: searchEngines

                ListElement {
                    title: "Bing"
                    url: "https://www.bing.com/search?q="
                }

                ListElement {
                    title: "DuckDuckGo"
                    url: "https://start.duckduckgo.com/?q="
                }

                ListElement {
                    title: "Ecosia"
                    url: "https://www.ecosia.org/search?q="
                }

                ListElement {
                    title: "Google"
                    url: "https://www.google.com/search?q="
                }

                ListElement {
                    title: "Lilo"
                    url: "https://search.lilo.org/searchweb.php?q="
                }

                ListElement {
                    title: "Peekier"
                    url: "https://peekier.com/#!"
                }

                ListElement {
                    title: "Qwant"
                    url: "https://www.qwant.com/?q="
                }

                ListElement {
                    title: "Qwant Junior"
                    url: "https://www.qwantjunior.com/?q="
                }

                ListElement {
                    title: "StartPage"
                    url: "https://www.startpage.com/do/dsearch?query="
                }

                ListElement {
                    title: "Swisscows"
                    url: "https://swisscows.com/web?query="
                }

                ListElement {
                    title: "Wikipedia"
                    url: "https://wikipedia.org/wiki/Special:Search?search="
                }
            }

            delegate: FormCard.FormRadioDelegate {
                checked: model.url === baseUrl
                text: model.title
                description: model.title === root.customName ? Settings.searchCustomUrl : model.url
                onClicked: {
                    if (model.title !== root.customName)
                        baseUrl = model.url;
                    else {
                        searchEnginePopup.open();
                    }
                    // restore property binding
                    checked = Qt.binding(() => {
                        return model.url === baseUrl;
                    });
                }
            }
        }
    }

    // custom search engine input sheet
    FormCard.FormCardDialog {
        id: searchEnginePopup

        title: i18n("Search Engine")
        parent: Controls.Overlay.overlay

        FormCard.FormTextFieldDelegate {
            id: urlInput
            label: i18n("Base URL of your preferred search engine")
            text: Settings.searchCustomUrl
            onAccepted: searchEnginePopup.accepted();
        }

        standardButtons: Controls.DialogButtonBox.Save

        onRejected: close();

        onAccepted: {
            const url = UrlUtils.urlFromUserInput(urlInput.text);
            Settings.searchCustomUrl = url;
            baseUrl = url;
            searchEngines.setProperty(searchEngines.count - 1, "url", url);
            close();
        }
    }

    onBaseUrlChanged: {
        Settings.searchBaseUrl = UrlUtils.urlFromUserInput(baseUrl);
    }

    Component.onCompleted: {
        searchEngines.append({ title: root.customName, url: Settings.searchCustomUrl });
    }
}
