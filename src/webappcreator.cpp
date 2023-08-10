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

WebAppCreator::WebAppCreator(QObject *parent)
    : QObject(parent)
    , m_webAppMngr(WebAppManager::instance())
{
    connect(this, &WebAppCreator::websiteNameChanged, this, &WebAppCreator::existsChanged);
    connect(&m_webAppMngr, &WebAppManager::applicationsChanged, this, &WebAppCreator::existsChanged);
}

bool WebAppCreator::exists() const
{
    return m_webAppMngr.exists(m_websiteName);
}

const QString &WebAppCreator::websiteName() const
{
    return m_websiteName;
}

void WebAppCreator::setWebsiteName(const QString &websiteName)
{
    m_websiteName = websiteName;
    Q_EMIT websiteNameChanged();
}

void WebAppCreator::createDesktopFile(const QString &name, const QString &url, const QString &iconUrl)
{
    m_webAppMngr.addApp(name, url, fetchIcon(iconUrl));

    // Refresh homescreen entries on Plasma Mobile
    QProcess buildsycoca;
    buildsycoca.setProgram(QStringLiteral("kbuildsycoca5"));
    buildsycoca.startDetached();
}

QImage WebAppCreator::fetchIcon(const QString &url)
{
    auto *provider = static_cast<QQuickImageProvider *>(qmlEngine(this)->imageProvider(QStringLiteral("favicon")));

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

#include "moc_webappcreator.cpp"
