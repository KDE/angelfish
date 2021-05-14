/***************************************************************************
 *                                                                         *
 *   SPDX-FileCopyrightText: 2020 Jonah Brüchert <jbb@kaidan.im>           *
 *                                                                         *
 *   SPDX-License-Identifier: GPL-2.0-or-later                             *
 *                                                                         *
 ***************************************************************************/

#pragma once

#include <QObject>

#include <memory>

class QQmlEngine;
class WebAppManager;

class WebAppCreator : public QObject
{
    Q_OBJECT

public:
    explicit WebAppCreator(QQmlEngine *engine, QObject *parent = nullptr);
    ~WebAppCreator();

    Q_INVOKABLE void createDesktopFile(const QString &name, const QString &url, const QString &icon);
    Q_INVOKABLE bool desktopFileExists(const QString &name);

Q_SIGNALS:
    void applicationsChanged();

private:
    QImage fetchIcon(const QString &url);
    QQmlEngine *m_engine;
    WebAppManager &m_webAppMngr;
};
