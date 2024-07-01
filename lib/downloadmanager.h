// SPDX-FileCopyrightText: 2020 Jonah Brüchert <jbb@kaidan.im>
//
// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

#include <QWebEngineDownloadRequest>

#include <memory>
#include <vector>

using DownloadItem = QWebEngineDownloadRequest;

class DownloadManager
{
public:
    static DownloadManager &instance();

    Q_INVOKABLE void addDownload(std::unique_ptr<DownloadItem> &&download);
    Q_INVOKABLE void removeDownload(const int index);
    const std::vector<std::unique_ptr<DownloadItem>> &downloads();

private:
    DownloadManager();

    std::vector<std::unique_ptr<DownloadItem>> m_downloads;
};
