// SPDX-FileCopyrightText: 2020 Jonah Brüchert <jbb@kaidan.im>
//
// SPDX-License-Identifier: GPL-2.0-or-later

#include "downloadmanager.h"

#include <QUrl>

DownloadManager::DownloadManager() = default;

DownloadManager &DownloadManager::instance()
{
    static DownloadManager instance;
    return instance;
}

void DownloadManager::addDownload(std::unique_ptr<DownloadItem> &&download)
{
    m_downloads.push_back(std::move(download));
}

void DownloadManager::removeDownload(const int index)
{
    m_downloads.at(index)->cancel();
    m_downloads.erase(m_downloads.begin() + index);
}

const std::vector<std::unique_ptr<DownloadItem>> &DownloadManager::downloads()
{
    return m_downloads;
}
