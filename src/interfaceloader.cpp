/*
 *  SPDX-FileCopyrightText: 2025 Yelsin Sepulveda <yelsinsepulveda@gmail.com>
 *  SPDX-License-Identifier: LGPL-2.0-only
 */

#include <QWindow>
#include "interfaceloader.h"

using namespace Qt::StringLiterals;

void InterfaceLoader::loadInterface()
{

    const QString url(m_isMobile ? u"Mobile"_s : u"Desktop"_s);

    auto *engine = qobject_cast<QQmlApplicationEngine*>(qmlEngine(this));
    QList<QWindow*> oldWindows;
    for (QObject* obj : engine->rootObjects()) {
        if (QWindow* window = qobject_cast<QWindow*>(obj)) {
            oldWindows.append(window);
        }
    }

    engine->clearComponentCache();
    engine->loadFromModule("org.kde.angelfish"_L1, url);

    // CLOSE old windows
    for (QWindow* window : oldWindows) {
        window->close();
    }

}

InterfaceLoader::InterfaceLoader(QObject *parent)
    : QObject(parent)
    , m_isMobile(SettingsHelper::isMobile())
{}

bool InterfaceLoader::isMobile() const
{
    return m_isMobile;
}

void InterfaceLoader::setIsMobile(bool mobile)
{
    if (m_isMobile == mobile) {
        return;
    }
    m_isMobile = mobile;
    Q_EMIT isMobileChanged();
    loadInterface();
}
