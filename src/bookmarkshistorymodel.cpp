#include "bookmarkshistorymodel.h"
#include "browsermanager.h"

#include <QDateTime>
#include <QDebug>
#include <QSqlError>

#define QUERY_LIMIT 1000

BookmarksHistoryModel::BookmarksHistoryModel()
{
    connect(BrowserManager::instance(), &BrowserManager::databaseTableChanged,
            this, &BookmarksHistoryModel::onDatabaseChanged);
}

void BookmarksHistoryModel::setActive(bool a)
{
    if (m_active == a) return;
    m_active = a;
    if (m_active)
        setQuery();
    else
        clear();
    emit activeChanged();
}

void BookmarksHistoryModel::setBookmarks(bool b)
{
    if (m_bookmarks == b) return;
    m_bookmarks = b;
    setQuery();
    emit bookmarksChanged();
}

void BookmarksHistoryModel::setHistory(bool h)
{
    if (m_history == h) return;
    m_history = h;
    setQuery();
    emit historyChanged();
}

void BookmarksHistoryModel::setFilter(const QString &f)
{
    if (m_filter == f) return;
    m_filter = f;
    setQuery();
    emit filterChanged();
}

void BookmarksHistoryModel::onDatabaseChanged(const QString &table)
{
    if ( (table == QLatin1String("bookmarks") && m_bookmarks) ||
            (table == QLatin1String("history") && m_history) )
        setQuery();
}

void BookmarksHistoryModel::setQuery()
{
    QString command;
    QString b = QStringLiteral("SELECT rowid AS id, url, title, icon, :now - lastVisited AS lastVisited, %1 AS bookmarked FROM %2 ");
    QLatin1String filter = m_filter.isEmpty() ? QLatin1String() : QLatin1String("WHERE url LIKE '%' || :filter || '%' OR title LIKE '%' || :filter || '%'");
    bool include_history = m_history && !(m_bookmarks && m_filter.isEmpty());
    if (m_bookmarks)
        command = b.arg(1).arg(QLatin1String("bookmarks")) + filter;
    if (m_bookmarks && include_history)
        command += QLatin1String("\n UNION \n");
    if (include_history)
        command += b.arg(0).arg(QLatin1String("history")) + filter;
    command += QLatin1String("\n ORDER BY bookmarked, lastVisited ASC");
    if (include_history)
        command += QStringLiteral("\n LIMIT %1").arg(QUERY_LIMIT);

    qint64 ref = QDateTime::currentSecsSinceEpoch();
    QSqlQuery query;
    if (!query.prepare(command)) {
        qWarning() << Q_FUNC_INFO << "Failed to prepare SQL statement";
        qWarning() << query.lastQuery();
        qWarning() << query.lastError();
        return;
    }

    if (!m_filter.isEmpty())
        query.bindValue(QStringLiteral(":filter"), m_filter);
    query.bindValue(QStringLiteral(":now"), ref);

    if (!query.exec()) {
        qWarning() << Q_FUNC_INFO << "Failed to execute SQL statement";
        qWarning() << query.lastQuery();
        qWarning() << query.lastError();
        return;
    }

    SqlQueryModel::setQuery(query);
}
