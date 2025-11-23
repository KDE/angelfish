// SPDX-FileCopyrightText: 2022 Abraham Soeyler <kde@soeyler.com>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.3
import QtQuick.Layouts

ColumnLayout {
    id: questions

    Component {
        id: permissionQuestion

        PermissionQuestion {
            Layout.fillWidth: true
        }
    }

    function newPermissionQuestion() {
        return permissionQuestion.createObject(questions)
    }
}
