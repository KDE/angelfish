// SPDX-FileCopyrightText: 2020 Jonah Brüchert <jbb@kaidan.im>
// SPDX-FileCopyrightText: 2020 Rinigus <rinigus.git@gmail.com>
//
// SPDX-License-Identifier: GPL-2.0-or-later

#include "bookmarkshistorymodel.h"
#include "browsermanager.h"

#include <QDateTime>
#include <QDebug>
#include <QSqlError>

#include <QCoroFuture>
#include <QCoroTask>

constexpr int QUERY_LIMIT = 1000;

BookmarksHistoryModel::BookmarksHistoryModel(QObject *parent)
    : QAbstractListModel(parent)
{
    connect(BrowserManager::instance(), &BrowserManager::databaseTableChanged, this, &BookmarksHistoryModel::onDatabaseChanged);
}

QHash<int, QByteArray> BookmarksHistoryModel::roleNames() const {
    return {
        {Id, "id"},
        {Url, "url"},
        {Title, "title"},
        {Icon, "iconName"},
        {LastVisitedDelta, "lastVisitedDelte"}
    };
}

QVariant BookmarksHistoryModel::data(const QModelIndex &index, int role) const
{
    auto &item = m_entries.at(index.row());
    switch (role) {
    case Role::Id:
        return item.id;
    case Role::Title:
        return item.title;
    case Role::Url:
        return item.url;
    case Role::Icon:
        return item.icon;
    case Role::LastVisitedDelta:
        return item.lastVisitedDelta;
    }

    Q_UNREACHABLE();
}

void BookmarksHistoryModel::setActive(bool a)
{
    if (m_active == a)
        return;
    m_active = a;
    if (m_active)
        fetchData();
    else
        clear();

    Q_EMIT activeChanged();
}

void BookmarksHistoryModel::setBookmarks(bool b)
{
    if (m_bookmarks == b)
        return;
    m_bookmarks = b;
    fetchData();
    Q_EMIT bookmarksChanged();
}

void BookmarksHistoryModel::setHistory(bool h)
{
    if (m_history == h)
        return;
    m_history = h;
    fetchData();
    Q_EMIT historyChanged();
}

void BookmarksHistoryModel::setFilter(const QString &f)
{
    if (m_filter == f)
        return;
    m_filter = f;
    fetchData();
    Q_EMIT filterChanged();
}

void BookmarksHistoryModel::onDatabaseChanged(const QString &table)
{
    if ((table == QLatin1String("bookmarks") && m_bookmarks) || (table == QLatin1String("history") && m_history))
        fetchData();
}

void BookmarksHistoryModel::fetchData()
{
    if (!m_active)
        return;

    auto future = [history = m_history, bookmarks = m_bookmarks, filter = m_filter]() mutable -> QCoro::Task<std::vector<BookmarksHistoryRecord>> {
        auto db = BrowserManager::instance()
                ->databaseManager()
                ->database();

        const qint64 currentTimeInUnix = QDateTime::currentSecsSinceEpoch();

        if (filter.isEmpty()) {
            // No clue why this works
            filter = QStringLiteral("");
        }

        if (bookmarks && history) {
            co_return co_await db->getResults<BookmarksHistoryRecord>(
                QStringLiteral("SELECT rowid AS id, url, title, icon, ? - lastVisited AS lastVisitedDelta "
                               "FROM (SELECT * FROM bookmarks UNION SELECT * FROM history) "
                               "WHERE url LIKE '%' || ? || '%' OR title LIKE '%' || ? || '%' "
                               "ORDER BY CASE WHEN rowid IN (SELECT rowid FROM history) THEN lastVisited END DESC, "
                               "rowid "
                               "LIMIT %1").arg(QUERY_LIMIT),
                    currentTimeInUnix, filter, filter);
        } else if (bookmarks) {
            co_return co_await db->getResults<BookmarksHistoryRecord>(
                QStringLiteral("SELECT rowid AS id, url, title, icon, ? - lastVisited AS lastVisitedDelta "
                               "FROM bookmarks "
                               "WHERE url LIKE '%' || ? || '%' OR title LIKE '%' || ? || '%'"),
                    currentTimeInUnix, filter, filter);
        } else if (history) {
            co_return co_await db->getResults<BookmarksHistoryRecord>(
                QStringLiteral("SELECT rowid AS id, url, title, icon, ? - lastVisited AS lastVisitedDelta "
                               "FROM history "
                               "WHERE url LIKE '%' || ? || '%' OR title LIKE '%' || ? || '%'"
                               "ORDER BY lastvisited DESC "
                               "LIMIT  %1").arg(QUERY_LIMIT),
                    currentTimeInUnix, filter, filter);
        }

        co_return {};
    }();

    QCoro::connect(std::move(future), this, [this](auto result) {
        if (m_entries == result) {
            return;
        }

        beginResetModel();
        m_entries = std::move(result);
        endResetModel();
    });
}

void BookmarksHistoryModel::clear()
{
    beginResetModel();
    m_entries.clear();
    endResetModel();
}

#include "moc_bookmarkshistorymodel.cpp"
