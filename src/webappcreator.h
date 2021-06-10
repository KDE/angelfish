// SPDX-FileCopyrightText: 2020 Jonah Brüchert <jbb@kaidan.im>
//
// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

#include <QObject>

class QQmlEngine;
class WebAppManager;

class WebAppCreator : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString websiteName READ websiteName WRITE setWebsiteName NOTIFY websiteNameChanged)
    Q_PROPERTY(bool exists READ exists NOTIFY existsChanged)

public:
    explicit WebAppCreator(QObject *parent = nullptr);

    const QString &websiteName() const;
    void setWebsiteName(const QString &websiteName);
    Q_SIGNAL void websiteNameChanged();

    bool exists() const;
    Q_SIGNAL void existsChanged();

    Q_INVOKABLE void createDesktopFile(const QString &name, const QString &url, const QString &icon);

private:
    QString m_websiteName;
    QImage fetchIcon(const QString &url);
    WebAppManager &m_webAppMngr;
};
