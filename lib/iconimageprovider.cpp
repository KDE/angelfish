// SPDX-FileCopyrightText: 2020 Jonah Brüchert <jbb@kaidan.im>
// SPDX-FileCopyrightText: 2020 Rinigus <rinigus.git@gmail.com>
//
// SPDX-License-Identifier: GPL-2.0-or-later

#include "iconimageprovider.h"

#include <QBuffer>
#include <QByteArray>
#include <QImage>
#include <QPixmap>
#include <QQmlApplicationEngine>
#include <QString>

#include <QCoroFuture>
#include <QCoroSignal>
#include <QCoroTask>

#include "browsermanager.h"

IconImageProvider::IconImageProvider()
    : QCoro::ImageProvider()
{
}

QString IconImageProvider::providerId()
{
    return QStringLiteral("angelfish-favicon");
}

QCoro::Task<QImage> IconImageProvider::asyncRequestImage(const QString &id, const QSize & /*requestedSize*/)
{
    auto url = QStringLiteral("image://%1/%2%").arg(providerId(), id);
    auto icon = co_await BrowserManager::instance()
            ->databaseManager()
            ->database()
            ->getResult<SingleValue<QByteArray>>(QStringLiteral("SELECT icon FROM icons WHERE url LIKE ? LIMIT 1"), url);

    if (icon) {
        co_return QImage::fromData(icon->value);
    }

    qWarning() << "Failed to find icon for" << id;
    co_return {};
}

QCoro::Task<QString> storeIcon(QQmlEngine *engine, const QString &iconSource)
{
    if (iconSource.isEmpty()) {
        co_return {};
    }

    const QLatin1String prefix_favicon = QLatin1String("image://favicon/");
    if (!iconSource.startsWith(prefix_favicon)) {
        // don't know what to do with it, return as it is
        qWarning() << Q_FUNC_INFO << "Don't know how to store image" << iconSource;
        co_return iconSource;
    }

    // new uri for image
    QString url = QStringLiteral("image://%1/%2").arg(IconImageProvider::providerId(), iconSource.mid(prefix_favicon.size()));

    // check if we have that image already
    bool alreadyExists = (co_await BrowserManager::instance()
            ->databaseManager()
            ->database()
            ->getResult<SingleValue<bool>>(
                QStringLiteral("SELECT COUNT(url) > 0 FROM icons WHERE url = ? LIMIT 1"), url))
            .value()
            .value;

    if (alreadyExists) {
        co_return url;
    }

    // Store new icon
    QQuickAsyncImageProvider *provider = dynamic_cast<QQuickAsyncImageProvider *>(engine->imageProvider(QStringLiteral("favicon")));
    if (!provider) {
        qWarning() << Q_FUNC_INFO << "Failed to load image provider" << url;
        co_return iconSource; // as something is wrong
    }

    QByteArray data;
    QBuffer buffer(&data);
    buffer.open(QIODevice::WriteOnly);

    const QSize szRequested;
    const QString providerIconName = iconSource.mid(prefix_favicon.size());

    const QImage imageToSave = co_await [=]() -> QCoro::Task<QImage> {
        switch (provider->imageType()) {
        case QQmlImageProviderBase::Image: {
            co_return provider->requestImage(providerIconName, nullptr, szRequested);
        }
        case QQmlImageProviderBase::Pixmap: {
            const QPixmap image = provider->requestPixmap(providerIconName, nullptr, szRequested);
            co_return image.toImage();
        }
        case QQmlImageProviderBase::Texture: {
            co_return provider->requestTexture(providerIconName, nullptr, szRequested)->image();
        }
        case QQmlImageProviderBase::ImageResponse: {
            auto response = provider->requestImageResponse(providerIconName, szRequested);
            co_await qCoro(response, &QQuickImageResponse::finished);
            co_return response->textureFactory()->image();
        }
        default:
            qWarning() << Q_FUNC_INFO << "Unsupported image provider" << provider->imageType();
            co_return {}; // as something is wrong
        }
    }();

    if (!imageToSave.save(&buffer, "PNG")) {
        qWarning() << Q_FUNC_INFO << "Failed to save image" << url;
        co_return iconSource; // as something is wrong
    }

    co_await BrowserManager::instance()
            ->databaseManager()
            ->database()
            ->execute(QStringLiteral("INSERT INTO icons(url, icon) VALUES (?, ?)"), url, data);

    co_return url;
}
