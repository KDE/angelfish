// SPDX-FileCopyrightText: 2020 Jonah Brüchert <jbb@kaidan.im>
//
// SPDX-License-Identifier: GPL-2.0-or-later

#include "downloadsmodel.h"

#include <QUrl>
#include <QMimeType>
#include <QMimeDatabase>

#include "downloadmanager.h"

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
        return QVariant::fromValue(downloads.at(index.row()));
    case Role::MimeTypeIconRole: {
        static auto mimeDB = QMimeDatabase();
        return mimeDB.mimeTypeForName(downloads.at(index.row())->mimeType()).iconName();
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
        {MimeTypeIconRole, "mimeTypeIcon"}
    };
}

void DownloadsModel::removeDownload(const int index)
{
    beginRemoveRows({}, index, index);
    DownloadManager::instance().removeDownload(index);
    endRemoveRows();
}