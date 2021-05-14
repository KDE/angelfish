// SPDX-FileCopyrightText: 2020-2021 Jonah Brüchert <jbb.prv@gmx.de>
//
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "webappcreator.h"

#include <QDebug>
#include <QDir>
#include <QFile>
#include <QProcess>
#include <QQmlEngine>
#include <QQuickImageProvider>
#include <QStandardPaths>

#include <KConfigGroup>
#include <KDesktopFile>

#include "webappmanager.h"

WebAppCreator::WebAppCreator(QQmlEngine *engine, QObject *parent)
    : QObject(parent)
    , m_engine(engine)
    , m_webAppMngr(WebAppManager::instance())
{
    connect(&m_webAppMngr, &WebAppManager::applicationsChanged, this, &WebAppCreator::applicationsChanged);
}

WebAppCreator::~WebAppCreator() = default;

void WebAppCreator::createDesktopFile(const QString &name, const QString &url, const QString &iconUrl)
{
    m_webAppMngr.addApp(name, url, fetchIcon(iconUrl));

    // Refresh homescreen entries on Plasma Mobile
    QProcess buildsycoca;
    buildsycoca.setProgram(QStringLiteral("kbuildsycoca5"));
    buildsycoca.startDetached();
}

bool WebAppCreator::desktopFileExists(const QString &name)
{
    return m_webAppMngr.exists(name);
}

QImage WebAppCreator::fetchIcon(const QString &url)
{
    auto *provider = static_cast<QQuickImageProvider *>(m_engine->imageProvider(QStringLiteral("favicon")));

    const QStringView prefixFavicon = QStringView(u"image://favicon/");
    const QString providerIconName = url.mid(prefixFavicon.size());

    const QSize szRequested;

    switch (provider->imageType()) {
    case QQmlImageProviderBase::Image: {
        return provider->requestImage(providerIconName, nullptr, szRequested);
    }
    case QQmlImageProviderBase::Pixmap: {
        return provider->requestPixmap(providerIconName, nullptr, szRequested).toImage();
    }
    default:
        qDebug() << "Failed to save unhandled image type";
    }

    return QImage();
}
