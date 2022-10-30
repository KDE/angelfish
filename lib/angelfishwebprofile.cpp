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

#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
#include "qquickwebenginedownloaditem.h"
#else
#include <private/qquickwebenginedownloadrequest_p.h>
#endif

AngelfishWebProfile::AngelfishWebProfile(QObject *parent)
    : QQuickWebEngineProfile(parent)
    , m_questionLoader(nullptr)
    , m_urlInterceptor(nullptr)
{
    connect(this, &QQuickWebEngineProfile::downloadRequested, this, &AngelfishWebProfile::handleDownload);
    connect(this, &QQuickWebEngineProfile::downloadFinished, this, &AngelfishWebProfile::handleDownloadFinished);
    connect(this, &QQuickWebEngineProfile::presentNotification, this, &AngelfishWebProfile::showNotification);
}

void AngelfishWebProfile::handleDownload(DownloadItem *downloadItem)
{
    // if we don't accept the request right away, it will be deleted
    downloadItem->accept();
    // therefore just stop the download again as quickly as possible,
    // and ask the user for confirmation
    downloadItem->pause();

    DownloadManager::instance().addDownload(std::unique_ptr<DownloadItem>(downloadItem));

    if (m_questionLoader) {
        m_questionLoader->setProperty("source", QStringLiteral("qrc:/DownloadQuestion.qml"));

        if (auto *question = m_questionLoader->property("item").value<QQuickItem *>()) {
            question->setProperty("download", QVariant::fromValue(downloadItem));
            question->setVisible(true);
        }
    }
}

void AngelfishWebProfile::handleDownloadFinished(DownloadItem *downloadItem)
{
    QQuickWindow *window = m_questionLoader->window();
    const auto passiveNotification = [window](const QString &text) {
        QMetaObject::invokeMethod(window, "showPassiveNotification", Q_ARG(QVariant, text), Q_ARG(QVariant, {}), Q_ARG(QVariant, {}), Q_ARG(QVariant, {}));
    };

    switch (downloadItem->state()) {
    case DownloadItem::DownloadCompleted:
        qDebug() << "download finished";
        passiveNotification(i18n("Download finished"));
        break;
    case DownloadItem::DownloadInterrupted:
        qDebug() << "Download failed";
        passiveNotification(i18n("Download failed"));
        qDebug() << "Download interrupt reason:" << downloadItem->interruptReasonString();
        break;
    case DownloadItem::DownloadCancelled:
        qDebug() << "Download cancelled by the user";
        break;
    default:
        break;
    }
}

void AngelfishWebProfile::showNotification(QWebEngineNotification *webNotification)
{
    auto *notification = new KNotification(QStringLiteral("web-notification"));
    notification->setComponentName(QStringLiteral("angelfish"));
    notification->setTitle(webNotification->title());
    notification->setText(webNotification->message());
    notification->setPixmap(QPixmap::fromImage(webNotification->icon()));

    connect(notification, &KNotification::closed, webNotification, &QWebEngineNotification::close);
    connect(notification, &KNotification::defaultActivated, webNotification, &QWebEngineNotification::click);

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
