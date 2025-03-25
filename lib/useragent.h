// SPDX-FileCopyrightText: 2020 Jonah Brüchert <jbb@kaidan.im>
// SPDX-FileCopyrightText: 2020 Rinigus <rinigus.git@gmail.com>
//
// SPDX-License-Identifier: GPL-2.0-or-later

#ifndef USERAGENT_H
#define USERAGENT_H

#include <QObject>
#include <QtQml/qqmlregistration.h>

class QQuickWebEngineProfile;

class UserAgent : public QObject
{
    Q_PROPERTY(QString userAgent READ userAgent NOTIFY userAgentChanged)
    Q_PROPERTY(bool isMobile READ isMobile WRITE setIsMobile NOTIFY isMobileChanged)

    Q_OBJECT
    QML_ELEMENT

public:
    explicit UserAgent(QObject *parent = nullptr);

    QString userAgent() const;

    bool isMobile() const;
    void setIsMobile(bool value);

Q_SIGNALS:
    void isMobileChanged();
    void userAgentChanged();

private:
    QStringView extractValueFromAgent(const QStringView key);

    const QQuickWebEngineProfile *m_defaultProfile;
    const QString m_defaultUserAgent;
    const QStringView m_chromeVersion;
    const QStringView m_appleWebKitVersion;
    const QStringView m_webEngineVersion;
    const QStringView m_safariVersion;

    bool m_isMobile;
};

#endif // USERAGENT_H
