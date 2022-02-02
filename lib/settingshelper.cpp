/*
 *  SPDX-FileCopyrightText: 2020 Jonah Brüchert <jbb@kaidan.im>
 *
 *  SPDX-License-Identifier: LGPL-2.0-only
 */

#include <QByteArray>
#include <QString>
#include <QtGlobal>

#include "settingshelper.h"

inline bool parseQuickControlsMobile()
{
    if (qEnvironmentVariableIsSet("QT_QUICK_CONTROLS_MOBILE")) {
        const QByteArray str = qgetenv("QT_QUICK_CONTROLS_MOBILE");
        return str == "1" || str == "true";
    }

    if (qEnvironmentVariable("XDG_CURRENT_DESKTOP").contains(QStringLiteral("Phosh"), Qt::CaseInsensitive)) {
        return true;
    }

    return false;
}

bool SettingsHelper::isMobile()
{
    static bool mobile = parseQuickControlsMobile();
    return mobile;
}
