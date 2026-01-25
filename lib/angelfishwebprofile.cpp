// SPDX-FileCopyrightText: 2020 Jonah Brüchert <jbb@kaidan.im>
//
// SPDX-License-Identifier: GPL-2.0-or-later

#include "angelfishwebprofile.h"

#include <KLocalizedString>
#include <QGuiApplication>
#include <QQuickItem>
#include <QQuickWindow>
#include <QWebEngineNotification>

#include <KNotification>

#include "downloadmanager.h"

using namespace Qt::StringLiterals;

class QQuickWebEngineDownloadRequest : public DownloadItem
{
};

AngelfishWebProfile::AngelfishWebProfile(QObject *parent)
    : QQuickWebEngineProfile(QString(), parent)
    , m_urlInterceptor(nullptr)
{
    connect(this, &QQuickWebEngineProfile::downloadRequested, this, &AngelfishWebProfile::handleDownload);
    connect(this, &QQuickWebEngineProfile::presentNotification, this, &AngelfishWebProfile::showNotification);
}

void AngelfishWebProfile::handleDownload(QQuickWebEngineDownloadRequest *downloadItem)
{
    DownloadItem *download = qobject_cast<DownloadItem *>(downloadItem);
    DownloadManager::instance().addDownload(std::unique_ptr<DownloadItem>(download));
}

void AngelfishWebProfile::showNotification(QWebEngineNotification *webNotification)
{
    auto *notification = new KNotification(QStringLiteral("web-notification"));
    notification->setComponentName(QStringLiteral("angelfish"));
    notification->setTitle(webNotification->title());
    notification->setText(webNotification->message());
    notification->setPixmap(QPixmap::fromImage(webNotification->icon()));

    connect(notification, &KNotification::closed, webNotification, &QWebEngineNotification::close);

    auto defaultAction = notification->addDefaultAction(i18n("Open"));
    connect(defaultAction, &KNotificationAction::activated, webNotification, &QWebEngineNotification::click);

    notification->sendEvent();
}

QWebEngineUrlRequestInterceptor *AngelfishWebProfile::urlInterceptor() const
{
    return m_urlInterceptor;
}

void AngelfishWebProfile::setUrlInterceptor(QWebEngineUrlRequestInterceptor *urlRequestInterceptor)
{
    setUrlRequestInterceptor(urlRequestInterceptor);
    m_urlInterceptor = urlRequestInterceptor;
    Q_EMIT urlInterceptorChanged();
}

#include "moc_angelfishwebprofile.cpp"
