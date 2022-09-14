// SPDX-FileCopyrightText: 2022 Alexey Andreyev <aa13q@ya.ru>
//
// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL

import QtFeedback 5.0
import org.kde.kirigami 2.5 as Kirigami

HapticsEffect {
    id: vibrate
    intensity: 0.5
    duration: Kirigami.Units.shortDuration
}
