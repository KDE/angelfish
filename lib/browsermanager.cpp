// SPDX-FileCopyrightText: 2014 Sebastian Kügler <sebas@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

#include "browsermanager.h"

#include <QDebug>
#include <QSettings>
#include <QStandardPaths>
#include <QUrl>
#include <QQmlEngine>

#include <QCoro/QCoroTask>

#include "angelfishsettings.h"

BrowserManager *BrowserManager::s_instance = nullptr;

BrowserManager::BrowserManager(QObject *parent)
    : QObject(parent)
    , m_dbmanager(new DBManager(this))
{
    connect(m_dbmanager, &DBManager::databaseTableChanged, this, &BrowserManager::databaseTableChanged);
}

void BrowserManager::addBookmark(const QVariantMap &bookmarkdata)
{
    qDebug() << "Add bookmark";
    qDebug() << "      data: " << bookmarkdata;
    m_dbmanager->addBookmark(bookmarkdata);
}

void BrowserManager::removeBookmark(const QString &url)
{
    m_dbmanager->removeBookmark(url);
}

void BrowserManager::addToHistory(const QVariantMap &pagedata)
{
    // qDebug() << "Add History";
    // qDebug() << "      data: " << pagedata;
    m_dbmanager->addToHistory(pagedata);
}

void BrowserManager::removeFromHistory(const QString &url)
{
    m_dbmanager->removeFromHistory(url);
}

void BrowserManager::clearHistory()
{
    m_dbmanager->clearHistory();
}

void BrowserManager::updateLastVisited(const QString &url)
{
    m_dbmanager->updateLastVisited(url);
}

void BrowserManager::updateIcon(const QString &url, const QString &iconSource)
{
    auto *engine = qmlEngine(this);
    Q_ASSERT(engine);
    m_dbmanager->updateIcon(engine, url, iconSource);
}

QUrl BrowserManager::initialUrl() const
{
    return m_initialUrl;
}

QString BrowserManager::tempDirectory() const
{
    return QStandardPaths::writableLocation(QStandardPaths::TempLocation);
}

QString BrowserManager::downloadDirectory() const
{
    return QStandardPaths::writableLocation(QStandardPaths::DownloadLocation);
}

void BrowserManager::setInitialUrl(const QUrl &initialUrl)
{
    m_initialUrl = initialUrl;
    Q_EMIT initialUrlChanged();
}

BrowserManager *BrowserManager::instance()
{
    if (!s_instance)
        s_instance = new BrowserManager();

    return s_instance;
}

#include "moc_browsermanager.cpp"
