// SPDX-FileCopyrightText: 2020 Jonah Brüchert <jbb@kaidan.im>
//
// SPDX-License-Identifier: GPL-2.0-or-later

#include "downloadsmodel.h"

#include <QDir>
#include <QMimeDatabase>
#include <QMimeType>
#include <QUrl>

#include "downloadmanager.h"

#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
#include "qquickwebenginedownloaditem.h"
using DownloadItem = QQuickWebEngineDownloadItem;
#else
#include <private/qquickwebenginedownloadrequest_p.h>
using DownloadItem = QQuickWebEngineDownloadRequest;
#endif

DownloadsModel::DownloadsModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

QVariant DownloadsModel::data(const QModelIndex &index, int role) const
{
    const auto &downloads = DownloadManager::instance().downloads();

    switch (role) {
    case Role::FileNameRole:
        return downloads.at(index.row())->downloadFileName();
    case Role::UrlRole:
        return downloads.at(index.row())->url();
    case Role::DownloadRole:
        return QVariant::fromValue(downloads.at(index.row()).get());
    case Role::MimeTypeIconRole: {
        static auto mimeDB = QMimeDatabase();
        return mimeDB.mimeTypeForName(downloads.at(index.row())->mimeType()).iconName();
    }
    case Role::DownloadedFilePathRole: {
        const auto &download = downloads.at(index.row());
        return QUrl::fromLocalFile(download->downloadDirectory() + QDir::separator() + download->downloadFileName());
    }
    }

    return {};
}

int DownloadsModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : DownloadManager::instance().downloads().size();
}

QHash<int, QByteArray> DownloadsModel::roleNames() const
{
    return {
        {UrlRole, "url"},
        {FileNameRole, "fileName"},
        {DownloadRole, "download"},
        {MimeTypeIconRole, "mimeTypeIcon"},
        {DownloadedFilePathRole, "downloadedFilePath"},
    };
}

void DownloadsModel::removeDownload(const int index)
{
    beginRemoveRows({}, index, index);
    DownloadManager::instance().removeDownload(index);
    endRemoveRows();
}
