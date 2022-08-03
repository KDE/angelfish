// SPDX-FileCopyrightText: 2022 Abraham Soeyler <kde@soeyler.com>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.3

Item {
    id: questions

    Component {
        id: permissionQuestion

        PermissionQuestion {
            anchors.left: questions.left
            anchors.right: questions.right
        }
    }

    function newPermissionQuestion() {
        return permissionQuestion.createObject(questions)
    }
}
