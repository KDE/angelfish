// SPDX-FileCopyrightText: 2020 Jonah Brüchert <jbb@kaidan.im>
//
// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

#include <QObject>
#include <QQuickItem>
#include <QQuickWebEngineProfile>
#include <QWebEngineDownloadRequest>
#include <QWebEngineUrlRequestInterceptor>

using DownloadItem = QWebEngineDownloadRequest;

class QWebEngineNotification;
class QQuickItem;
class QWebEngineUrlRequestInterceptor;

class AngelfishWebProfile : public QQuickWebEngineProfile
{
    Q_OBJECT

    Q_PROPERTY(QQuickItem *questionLoader MEMBER m_questionLoader NOTIFY questionLoaderChanged)
    Q_PROPERTY(QWebEngineUrlRequestInterceptor *urlInterceptor WRITE setUrlInterceptor READ urlInterceptor NOTIFY urlInterceptorChanged)

public:
    explicit AngelfishWebProfile(QObject *parent = nullptr);

    Q_SIGNAL void questionLoaderChanged();
    Q_SIGNAL void urlInterceptorChanged();

    QWebEngineUrlRequestInterceptor *urlInterceptor() const;
    void setUrlInterceptor(QWebEngineUrlRequestInterceptor *urlRequestInterceptor);

private:
    void handleDownload(QQuickWebEngineDownloadRequest *downloadItem);
    void handleDownloadFinished(DownloadItem *downloadItem);
    void showNotification(QWebEngineNotification *webNotification);

    QQuickItem *m_questionLoader;

    // A valid property needs a read function, and there is no getter in QQuickWebEngineProfile
    // so store a pointer ourselves
    QWebEngineUrlRequestInterceptor *m_urlInterceptor;
};
