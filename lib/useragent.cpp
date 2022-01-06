// SPDX-FileCopyrightText: 2021 Jonah Brüchert <jbb@kaidan.im>
// SPDX-FileCopyrightText: 2020 Rinigus <rinigus.git@gmail.com>
//
// SPDX-License-Identifier: GPL-2.0-or-later

#include "useragent.h"

#include <QQuickWebEngineProfile>
#include <QtWebEngineVersion>

#include "settingshelper.h"

UserAgent::UserAgent(QObject *parent)
    : QObject(parent)
    , m_defaultProfile(QQuickWebEngineProfile::defaultProfile())
    , m_defaultUserAgent(m_defaultProfile->httpUserAgent())
    , m_chromeVersion(extractValueFromAgent(u"Chrome"))
    , m_appleWebKitVersion(extractValueFromAgent(u"AppleWebKit"))
    , m_webEngineVersion(extractValueFromAgent(u"QtWebEngine"))
    , m_safariVersion(extractValueFromAgent(u"Safari"))
    , m_isMobile(SettingsHelper::isMobile())
{
}

QString UserAgent::userAgent() const
{
    return QStringView(
               u"Mozilla/5.0 (%1) AppleWebKit/%2 (KHTML, like Gecko) QtWebEngine/%3 "
               u"Chrome/%4 %5 Safari/%6")
        .arg(m_isMobile ? u"Linux; Plasma Mobile, like Android 9.0" : u"X11; Linux x86_64",
             m_appleWebKitVersion,
             m_webEngineVersion,
             m_chromeVersion,
             m_isMobile ? u"Mobile" : u"Desktop",
             m_safariVersion);
}

bool UserAgent::isMobile() const
{
    return m_isMobile;
}

void UserAgent::setIsMobile(bool value)
{
    if (m_isMobile != value) {
        m_isMobile = value;

        Q_EMIT isMobileChanged();
        Q_EMIT userAgentChanged();
    }
}

QStringView UserAgent::extractValueFromAgent(const QStringView key)
{
    const int index = m_defaultUserAgent.indexOf(key) + key.length() + 1;
    const int endIndex = m_defaultUserAgent.indexOf(u' ', index);
    return m_defaultUserAgent.midRef(index, endIndex - index);
}
