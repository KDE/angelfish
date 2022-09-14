// SPDX-FileCopyrightText: 2022 Alexey Andreyev <aa13q@ya.ru>
//
// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL

import QtQuick 2.0

// see also: QTBUG-16854
Loader {
    source: "qrc:/HapticsEffectWrapper.qml"
    property bool valid: item !== null
    function start() {
        if (valid) item.start()
    }
}
