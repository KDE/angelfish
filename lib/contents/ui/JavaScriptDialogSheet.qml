// SPDX-FileCopyrightText: 2020 Jonah Brüchert <jbb@kaidan.im>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.7
import QtQuick.Controls 2.2 as Controls
import org.kde.kirigami 2.20 as Kirigami
import QtQuick.Layouts 1.2

import QtWebEngine 1.4

Kirigami.PromptDialog {
    id: root
    property JavaScriptDialogRequest request
    
    onAccepted: root.request.dialogAccept()
    onRejected: root.request.dialogReject()

    onVisibleChanged: {
        if (root.visible) {
            switch(request.type) {
            case JavaScriptDialogRequest.DialogTypeAlert:
                root.standardButtons = Kirigami.Dialog.Close;
                root.customFooterActions = [];
                inputField.visible = false;
                break;
            case JavaScriptDialogRequest.DialogTypeConfirm:
                root.standardButtons = Kirigami.Dialog.Ok | Kirigami.Dialog.Cancel;
                root.customFooterActions = [];
                inputField.visible = false;
                break;
            case JavaScriptDialogRequest.DialogTypePrompt:
                root.standardButtons = Kirigami.Dialog.Cancel;
                root.customFooterActions = [root.submitAction];
                inputField.text = "";
                inputField.visible = true;
                break;
            case JavaScriptDialogRequest.DialogTypeBeforeUnload:
                root.standardButtons = Kirigami.Dialog.NoButton
                root.customFooterActions = [root.leavePageAction];
                inputField.visible = false;
                break;
            }
        } else {
            root.request.dialogReject()
        }
    }
    
    title: i18n("This page says")
    
    ColumnLayout {
        spacing: Kirigami.Units.smallSpacing
        
        Controls.Label {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            text: {
                if (request) {
                    if (request.message) {
                        return request.message
                    }

                    if (request.type == JavaScriptDialogRequest.DialogTypeBeforeUnload) {
                        return i18n("The website asks for confirmation that you want to leave. Unsaved information might not be saved.")
                    }
                }

                return ""
            }
        }
        
        Controls.TextField {
            id: inputField
            Layout.fillWidth: true
        }
    }

    property var leavePageAction: Kirigami.Action {
        text: i18n("Leave page")
        onTriggered: {
            root.request.dialogAccept()
            root.close()
        }
    }
    
    property var submitAction: Kirigami.Action {
        text: i18n("Submit")
        icon.name: "dialog-ok"
        onTriggered: {
            root.request.dialogAccept(inputField.text)
            root.close()
        }
    }
}
