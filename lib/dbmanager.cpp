// SPDX-FileCopyrightText: 2020 Jonah Brüchert <jbb@kaidan.im>
// SPDX-FileCopyrightText: 2020 Rinigus <rinigus.git@gmail.com>
//
// SPDX-License-Identifier: GPL-2.0-or-later

#include "dbmanager.h"

#include <QDateTime>
#include <QDebug>
#include <QDir>
#include <QSqlDatabase>
#include <QStandardPaths>
#include <QVariant>

#include <QCoroFuture>

constexpr int MAX_BROWSER_HISTORY_SIZE = 3000;

DBManager::DBManager(QObject *parent)
    : QObject(parent)
{
    const QString dbpath = QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation);
    const QString dbname = dbpath + QStringLiteral("/angelfish.sqlite");

    if (!QDir().mkpath(dbpath)) {
        qCritical() << "Database directory does not exist and cannot be created: " << dbpath;
        throw std::runtime_error("Database directory does not exist and cannot be created: " + dbpath.toStdString());
    }

    DatabaseConfiguration config;
    config.setDatabaseName(dbname);
    config.setType(DatabaseType::SQLite);

    m_database = ThreadedDatabase::establishConnection(config);
    m_database->runMigrations(QStringLiteral(":/contents/migrations/"));

    if (!m_database) {
        qCritical() << "Failed to open database" << dbname;
        throw std::runtime_error("Failed to open database " + dbname.toStdString());
    }

    // TODO DB: Add back migrations

    trimHistory();
    trimIcons();
}

QCoro::Task<> DBManager::execute(const QString command)
{
    co_await m_database->execute(command);
}

QCoro::Task<> DBManager::trimHistory()
{
    co_await m_database->execute(
        QStringLiteral("DELETE FROM history WHERE rowid NOT IN (SELECT rowid FROM history "
                       "ORDER BY lastVisited DESC LIMIT ?)"),
                MAX_BROWSER_HISTORY_SIZE);
}

QCoro::Task<> DBManager::trimIcons()
{
    co_await m_database->execute(
        QStringLiteral("DELETE FROM icons WHERE url NOT IN "
                       "(SELECT icon FROM history UNION SELECT icon FROM bookmarks)"));
}

QCoro::Task<> DBManager::addRecord(const QString table, const QVariantMap pagedata)
{
    const QString url = pagedata.value(QStringLiteral("url")).toString();
    const QString title = pagedata.value(QStringLiteral("title")).toString();
    const QString icon = pagedata.value(QStringLiteral("icon")).toString();
    const qint64 lastVisited = QDateTime::currentSecsSinceEpoch();

    if (url.isEmpty() || url == QStringLiteral("about:blank"))
        co_return;

    co_await m_database->execute(QStringLiteral(
                                "INSERT OR REPLACE INTO %1 (url, title, icon, lastVisited) "
                                "VALUES (?, ?, ?, ?)").arg(table),
                                url, title, icon, lastVisited);

    Q_EMIT databaseTableChanged(table);
}

QCoro::Task<> DBManager::removeRecord(const QString table, const QString url)
{
    if (url.isEmpty())
        co_return;

    co_await m_database->execute(QStringLiteral("DELETE FROM %1 WHERE url = ?").arg(table), url);

    Q_EMIT databaseTableChanged(table);
}

QCoro::Task<> DBManager::removeAllRecords(const QString table)
{
    co_await m_database->execute(QStringLiteral("DELETE FROM %1").arg(table));
    Q_EMIT databaseTableChanged(table);
}

QCoro::Task<bool> DBManager::hasRecord(const QString table, const QString url) const
{
    auto maybeExists = co_await m_database
            ->getResult<SingleValue<bool>>(QStringLiteral("SELECT COUNT(url) > 0 FROM %1 WHERE url = ?").arg(table), url);

    if (maybeExists.has_value()) {
        co_return maybeExists->value;
    }

    co_return false;
}

QCoro::Task<> DBManager::setLastVisitedRecord(const QString table, const QString url)
{
    if (url.isEmpty())
        co_return;

    const qint64 lastVisited = QDateTime::currentSecsSinceEpoch();
    co_await m_database->execute(QStringLiteral("UPDATE %1 SET lastVisited = ? WHERE url = ?").arg(table), url, lastVisited);

    Q_EMIT databaseTableChanged(table);
}

QCoro::Task<> DBManager::addBookmark(const QVariantMap bookmarkdata)
{
    co_await addRecord(QStringLiteral("bookmarks"), bookmarkdata);
}

QCoro::Task<> DBManager::removeBookmark(const QString url)
{
    co_await removeRecord(QStringLiteral("bookmarks"), url);
}

QCoro::Task<bool> DBManager::isBookmarked(const QString url) const
{
    co_return co_await hasRecord(QStringLiteral("bookmarks"), url);
}

QCoro::Task<> DBManager::addToHistory(const QVariantMap pagedata)
{
    co_await addRecord(QStringLiteral("history"), pagedata);
}

QCoro::Task<> DBManager::removeFromHistory(const QString url)
{
    co_await removeRecord(QStringLiteral("history"), url);
}

QCoro::Task<> DBManager::clearHistory()
{
    co_await removeAllRecords(QStringLiteral("history"));
}

QCoro::Task<> DBManager::updateLastVisited(const QString url)
{
    co_await setLastVisitedRecord(QStringLiteral("bookmarks"), url);
    co_await setLastVisitedRecord(QStringLiteral("history"), url);
}

#include "moc_dbmanager.cpp"
