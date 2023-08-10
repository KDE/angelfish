// SPDX-FileCopyrightText: 2022 Alexey Andreyev <aa13q@ya.ru>
//
// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL

#include "domdistiller.h"

#include <QFile>
#include <QTextStream>

DomDistiller::DomDistiller(QObject *parent)
    : QObject{parent}
    , m_applyScript(QStringLiteral("org.chromium.distiller.DomDistiller.apply()"))
{
    QFile domDistillerFile(QStringLiteral(":/domdistiller.js"));

    if (domDistillerFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QTextStream textStream(&domDistillerFile);
        m_script = textStream.readAll();
        domDistillerFile.close();
    }
}

const QString &DomDistiller::script() const
{
    return m_script;
}

const QString &DomDistiller::applyScript() const
{
    return m_applyScript;
}

#include "moc_domdistiller.cpp"
