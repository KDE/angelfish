/*
 *  SPDX-FileCopyrightText: 2020 Jonah Brüchert <jbb@kaidan.im>
 *
 *  SPDX-License-Identifier: LGPL-2.0-only
 */

#include <QtTest/QTest>
#include <QSignalSpy>
#include <QCoreApplication>
#include <QStandardPaths>
#include <QSqlQuery>

#include "dbmanager.h"

class DbManagerTest : public QObject
{
    Q_OBJECT

private Q_SLOTS:
    void initTestCase()
    {
        QCoreApplication::setOrganizationName(QStringLiteral("autotests"));
        QCoreApplication::setApplicationName(QStringLiteral("angelfish_dbmanagertest"));
        QDir dir(QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation));
        dir.mkpath(QStringLiteral("."));

        m_dbmanager = new DBManager();
    }

    void testAddBookmark()
    {
        QSignalSpy spy(m_dbmanager, &DBManager::databaseTableChanged);
        auto future = m_dbmanager->addBookmark({
            {QStringLiteral("url"), QStringLiteral("https://kde.org")},
            {QStringLiteral("title"), QStringLiteral("KDE")}
        });

        QCoro::waitFor(future);
        QCOMPARE(spy.count(), 1);
    }

    void testAddToHistory()
    {
        QSignalSpy spy(m_dbmanager, &DBManager::databaseTableChanged);
        auto future = m_dbmanager->addToHistory({
            {QStringLiteral("url"), QStringLiteral("https://kde.org")},
            {QStringLiteral("title"), QStringLiteral("KDE")}
        });

        QCoro::waitFor(future);
        QCOMPARE(spy.count(), 1);
    }

    void testLastVisited()
    {
        QSignalSpy spy(m_dbmanager, &DBManager::databaseTableChanged);
        auto future = m_dbmanager->updateLastVisited(QStringLiteral("https://kde.org"));

        // Will be updated in both tables
        QCoro::waitFor(future);
        QCOMPARE(spy.count(), 2);
    }

    void testRemoveBookmark()
    {
        QSignalSpy spy(m_dbmanager, &DBManager::databaseTableChanged);
        auto future = m_dbmanager->removeBookmark(QStringLiteral("https://kde.org"));

        QCoro::waitFor(future);
        QCOMPARE(spy.count(), 1);
    }

    void testRemoveFromHistory()
    {
        QSignalSpy spy(m_dbmanager, &DBManager::databaseTableChanged);
        auto future = m_dbmanager->removeBookmark(QStringLiteral("https://kde.org"));

        QCoro::waitFor(future);
        QCOMPARE(spy.count(), 1);
    }

private:
    DBManager *m_dbmanager;
};

QTEST_GUILESS_MAIN(DbManagerTest);

#include "dbmanagertest.moc"
