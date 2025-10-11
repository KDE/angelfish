// SPDX-FileCopyrightText: 2025 Yelsin Sepulveda <yelsin.sepulveda@kdemail.net>
// SPDX-License-Identifier: LGPL-2.0-only

#pragma once

#include <QQmlApplicationEngine>
#include <QObject>
#include <QUrl>

#include <settingshelper.h>

class InterfaceLoader : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(bool isMobile READ isMobile WRITE setIsMobile NOTIFY isMobileChanged)

private:
    bool m_isMobile;

public:
    explicit InterfaceLoader(QObject *parent = nullptr);

    void setIsMobile(bool mobile);
    bool isMobile() const;
    Q_SLOT void loadInterface();

Q_SIGNALS:
    void isMobileChanged();
};
