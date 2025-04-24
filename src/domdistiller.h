// SPDX-FileCopyrightText: 2022 Alexey Andreyev <aa13q@ya.ru>
//
// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL

#pragma once

#include <QObject>
#include <QString>
#include <qqmlregistration.h>

class DomDistiller : public QObject
{
    Q_OBJECT
    QML_SINGLETON
    QML_ELEMENT

    Q_PROPERTY(QString script READ script)
    Q_PROPERTY(QString applyScript READ applyScript)

public:
    explicit DomDistiller(QObject *parent = nullptr);
    const QString &script() const;
    const QString &applyScript() const;

private:
    QString m_script;
    QString m_applyScript;
};
