// SPDX-FileCopyrightText: 2020 Jonah Brüchert <jbb@kaidan.im>
// SPDX-FileCopyrightText: 2020 Rinigus <rinigus.git@gmail.com>
//
// SPDX-License-Identifier: GPL-2.0-or-later

#ifndef DBMANAGER_H
#define DBMANAGER_H

#include <QObject>
#include <QString>
#include <QSqlDatabase>
#include <QtQml/qqmlregistration.h>

#include <ThreadedDatabase>

#include <QCoro/QCoroTask>

class QQmlEngine;

/**
 * @class DBManager
 * @short Class for database initialization and applying changes in its records
 */
class DBManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT

public:
    explicit DBManager(QObject *parent = nullptr);

Q_SIGNALS:
    // emitted with the name of the table that has been changed
    void databaseTableChanged(QString table);

public:
    QCoro::Task<> addBookmark(const QVariantMap bookmarkdata);
    QCoro::Task<> removeBookmark(const QString url);
    QCoro::Task<bool> isBookmarked(const QString url) const;

    QCoro::Task<> addToHistory(const QVariantMap pagedata);
    QCoro::Task<> removeFromHistory(const QString url);
    QCoro::Task<> clearHistory();

    QCoro::Task<> updateIcon(QQmlEngine *engine, const QString url, const QString iconSource);
    QCoro::Task<> updateLastVisited(const QString url);

    inline std::shared_ptr<ThreadedDatabase> database() {
        return m_database;
    }

private:
    // limit the size of history table
    QCoro::Task<> trimHistory();
    // drop unused icons
    QCoro::Task<> trimIcons();

    // execute SQL statement
    QCoro::Task<> execute(const QString command);

    // methods for manipulation of bookmarks or history tables
    QCoro::Task<> addRecord(const QString table, const QVariantMap pagedata);
    QCoro::Task<> removeRecord(const QString table, const QString url);
    QCoro::Task<> removeAllRecords(const QString table);
    QCoro::Task<> updateIconRecord(const QString table, const QString url, const QString iconSource);
    QCoro::Task<> setLastVisitedRecord(const QString table, const QString url);
    QCoro::Task<bool> hasRecord(const QString table, const QString url) const;

    std::shared_ptr<ThreadedDatabase> m_database;
};

#endif // DBMANAGER_H
