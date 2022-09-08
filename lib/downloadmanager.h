// SPDX-FileCopyrightText: 2020 Jonah Brüchert <jbb@kaidan.im>
//
// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

#include <QObject>

#include <memory>
#include <vector>

class QQuickWebEngineDownloadItem;

class DownloadManager
{
public:
    static DownloadManager &instance();

    Q_INVOKABLE void addDownload(std::unique_ptr<QQuickWebEngineDownloadItem> &&download);
    Q_INVOKABLE void removeDownload(const int index);
    const std::vector<std::unique_ptr<QQuickWebEngineDownloadItem>> &downloads();

private:
    DownloadManager();

    std::vector<std::unique_ptr<QQuickWebEngineDownloadItem>> m_downloads;
};
