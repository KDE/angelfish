/*
 *  SPDX-FileCopyrightText: 2020 Jonah Brüchert <jbb@kaidan.im>
 *
 *  SPDX-License-Identifier: LGPL-2.0-only
 */

#include "tabsmodel.h"

#include <QDebug>
#include <QDir>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QStandardPaths>
#include <QUrl>

#include <ranges>

#include "angelfishsettings.h"
#include "browsermanager.h"

namespace ranges = std::ranges;

TabsModel::TabsModel(QObject *parent)
    : QAbstractListModel(parent)
{
    connect(this, &TabsModel::currentTabChanged, [this] {
        qDebug() << "Current tab changed to" << m_currentTab;
    });

    // The fallback tab must not be saved, it would overwrite our actual data.
    m_tabsReadOnly = true;
    // Make sure model always contains at least one tab
    createEmptyTab();

    // Only load tabs after private mode is known
    connect(this, &TabsModel::privateModeChanged, [this] {
        loadInitialTabs();
    });
}

QHash<int, QByteArray> TabsModel::roleNames() const
{
    return {
        {RoleNames::UrlRole, QByteArrayLiteral("pageurl")},
        {RoleNames::IsMobileRole, QByteArrayLiteral("isMobile")},
        {RoleNames::IsDeveloperToolsOpen, QByteArrayLiteral("isDeveloperToolsOpen")},
    };
}

QVariant TabsModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || size_t(index.row()) >= m_tabs.size()) {
        return {};
    }

    switch (role) {
    case RoleNames::UrlRole:
        return m_tabs.at(index.row()).url();
    case RoleNames::IsMobileRole:
        return m_tabs.at(index.row()).isMobile();
    case RoleNames::IsDeveloperToolsOpen:
        return m_tabs.at(index.row()).isDeveloperToolsOpen();
    }

    return {};
}

int TabsModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_tabs.size();
}

/**
 * @brief TabsModel::tab returns the tab at the given index
 * @param index
 * @return tab at the index
 */
TabState TabsModel::tab(int index)
{
    if (index < 0 && size_t(index) >= m_tabs.size())
        return {}; // index out of bounds

    return m_tabs.at(index);
}

/**
 * @brief TabsModel::loadInitialTabs sets up the tabs that should already be open when starting the browser
 * This includes the configured homepage, an url passed on the command line (usually by another app) and tabs
 * which were still open when the browser was last closed.
 *
 * @warning It is impossible to save any new tabs until this function was called.
 */
void TabsModel::loadInitialTabs()
{
    if (m_initialTabsLoaded) {
        return;
    }

    if (!m_privateMode) {
        loadTabs();
    }

    m_tabsReadOnly = false;

    if (!m_privateMode) {
        if (BrowserManager::instance()->initialUrl().isEmpty()) {
            if (m_tabs.front().url() == QUrl(QStringLiteral("about:blank")))
                setUrl(0, AngelfishSettings::self()->homepage());
        } else {
            if (m_tabs.front().url() == QUrl(QStringLiteral("about:blank")))
                setUrl(0, BrowserManager::instance()->initialUrl());
            else
                newTab(BrowserManager::instance()->initialUrl());
        }
    }

    m_initialTabsLoaded = true;
}

/**
 * @brief TabsModel::currentTab returns the index of the tab that is currently visible to the user
 * @return index
 */
int TabsModel::currentTab() const
{
    return m_currentTab;
}

/**
 * @brief TabsModel::setCurrentTab sets the tab that is currently visible to the user
 * @param index
 */
void TabsModel::setCurrentTab(int index)
{
    if (size_t(index) >= m_tabs.size())
        return;

    m_currentTab = index;
    Q_EMIT currentTabChanged();
    saveTabs();
}

std::vector<TabState> TabsModel::tabs() const
{
    return m_tabs;
}

/**
 * @brief TabsModel::loadTabs restores tabs saved in tabs.json
 * @return whether any tabs were restored
 */
bool TabsModel::loadTabs()
{
    if (!m_privateMode) {
        beginResetModel();
        const QString input = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation) + QStringLiteral("/angelfish/tabs.json");

        QFile inputFile(input);
        if (!inputFile.exists()) {
            return false;
        }

        if (!inputFile.open(QIODevice::ReadOnly)) {
            qDebug() << "Failed to load tabs from disk";
        }

        const auto tabsStorage = QJsonDocument::fromJson(inputFile.readAll()).object();
        m_tabs.clear();

        const auto tabs = tabsStorage.value(QLatin1String("tabs")).toArray();

        ranges::transform(tabs, std::back_inserter(m_tabs), [](const QJsonValue &tab) {
            return TabState::fromJson(tab.toObject());
        });

        qDebug() << "loaded from file:" << m_tabs.size() << input;

        m_currentTab = tabsStorage.value(QLatin1String("currentTab")).toInt();

        // Make sure model always contains at least one tab
        if (m_tabs.size() == 0) {
            createEmptyTab();
        }

        endResetModel();
        Q_EMIT currentTabChanged();

        return true;
    }
    return false;
}

/**
 * @brief TabsModel::saveTabs saves the current state of the model to disk
 * @return whether the tabs could be saved
 */
bool TabsModel::saveTabs() const
{
    // only save if not in private mode
    if (!m_privateMode && !m_tabsReadOnly) {
        const QString outputDir = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation) + QStringLiteral("/angelfish/");

        QFile outputFile(outputDir + QStringLiteral("tabs.json"));
        if (!QDir(outputDir).mkpath(QStringLiteral("."))) {
            qDebug() << "Destdir doesn't exist and I can't create it: " << outputDir;
            return false;
        }
        if (!outputFile.open(QIODevice::WriteOnly)) {
            qDebug() << "Failed to write tabs to disk";
        }

        QJsonArray tabsArray;
        ranges::transform(m_tabs, std::back_inserter(tabsArray), [](const TabState &tab) {
            return tab.toJson();
        });

        qDebug() << "Wrote to file" << outputFile.fileName() << "(" << tabsArray.size() << "urls"
                 << ")";

        const QJsonDocument document({
            {QLatin1String("tabs"), tabsArray},
            {QLatin1String("currentTab"), m_currentTab},
        });

        outputFile.write(document.toJson());
        return true;
    }
    return false;
}

bool TabsModel::isMobileDefault() const
{
    return m_isMobileDefault;
}

void TabsModel::setIsMobileDefault(bool def)
{
    if (m_isMobileDefault != def) {
        m_isMobileDefault = def;
        Q_EMIT isMobileDefaultChanged();

        // used in initialization of the tab
        if (m_tabs.size() == 1) {
            setIsMobile(0, def);
        }
    }
}

bool TabsModel::privateMode() const
{
    return m_privateMode;
}

void TabsModel::setPrivateMode(bool privateMode)
{
    m_privateMode = privateMode;
    Q_EMIT privateModeChanged();
}

/**
 * @brief TabsModel::createEmptyTab convinience function for opening a tab containing "about:blank"
 */
void TabsModel::createEmptyTab()
{
    newTab(QUrl(QStringLiteral("about:blank")));
};

/**
 * @brief TabsModel::newTab
 * @param url
 * @param isMobile
 */
void TabsModel::newTab(const QUrl &url)
{
    beginInsertRows({}, m_tabs.size(), m_tabs.size());

    m_tabs.push_back(TabState(url, m_isMobileDefault));

    endInsertRows();

    // Switch to last tab
    if (AngelfishSettings::self()->switchToNewTab()) {
        m_currentTab = m_tabs.size() - 1;
        Q_EMIT currentTabChanged();
    }
    saveTabs();
}

/**
 * @brief TabsModel::closeTab removes the tab at the index, handles moving the tabs after it and sets a new currentTab
 * @param index
 */
void TabsModel::closeTab(int index)
{
    if (index < 0 && size_t(index) >= m_tabs.size())
        return; // index out of bounds

    if (m_tabs.size() <= 1) {
        // create new tab before removing the last one
        // to avoid linking all signals to null object
        createEmptyTab();

        // now we have (tab_to_remove, "about:blank)

        // 0 will be the correct current tab index after tab_to_remove is gone
        m_currentTab = 0;

        // index to remove
        index = 0;
    }

    if (m_currentTab > index) {
        // decrease index if it's after the removed tab
        m_currentTab--;
    }

    if (m_currentTab == index) {
        // handle the removal of current tab
        // Just reset to first tab
        if (index != 0) {
            m_currentTab = index - 1;
        } else {
            m_currentTab = 0;
        }
    }

    beginRemoveRows({}, index, index);
    m_tabs.erase(m_tabs.begin() + index);
    endRemoveRows();

    Q_EMIT currentTabChanged();
    saveTabs();
}

void TabsModel::setIsMobile(int index, bool isMobile)
{
    qDebug() << "Setting isMobile:" << index << isMobile << "tabs open" << m_tabs.size();
    if (index < 0 && size_t(index) >= m_tabs.size())
        return; // index out of bounds

    m_tabs[index].setIsMobile(isMobile);

    const QModelIndex mindex = createIndex(index, index);
    Q_EMIT dataChanged(mindex, mindex, {RoleNames::IsMobileRole});
    saveTabs();
}

void TabsModel::toggleDeveloperTools(int index)
{
    if (index < 0 && size_t(index) >= m_tabs.size())
        return; // index out of bounds

    auto &tab = m_tabs[index];
    tab.setIsDeveloperToolsOpen(!tab.isDeveloperToolsOpen());

    const QModelIndex mindex = createIndex(index, index);
    Q_EMIT dataChanged(mindex, mindex, {RoleNames::IsDeveloperToolsOpen});
    saveTabs();
}

bool TabsModel::isDeveloperToolsOpen(int index)
{
    if (index < 0 && size_t(index) >= m_tabs.size())
        return false;

    return m_tabs.at(index).isDeveloperToolsOpen();
}

void TabsModel::setUrl(int index, const QUrl &url)
{
    qDebug() << "Setting URL:" << index << url << "tabs open" << m_tabs.size();
    if (index < 0 && size_t(index) >= m_tabs.size())
        return; // index out of bounds

    m_tabs[index].setUrl(url);

    const QModelIndex mindex = createIndex(index, index);
    Q_EMIT dataChanged(mindex, mindex, {RoleNames::UrlRole});
    saveTabs();
}

QUrl TabState::url() const
{
    return m_url;
}

void TabState::setUrl(const QUrl &url)
{
    m_url = url;
}

bool TabState::isMobile() const
{
    return m_isMobile;
}

void TabState::setIsMobile(bool isMobile)
{
    m_isMobile = isMobile;
}

bool TabState::isDeveloperToolsOpen() const
{
    return m_isDeveloperToolsOpen;
}

void TabState::setIsDeveloperToolsOpen(bool isDeveloperToolsOpen)
{
    m_isDeveloperToolsOpen = isDeveloperToolsOpen;
}

TabState TabState::fromJson(const QJsonObject &obj)
{
    TabState tab;
    tab.setUrl(QUrl(obj.value(QStringLiteral("url")).toString()));
    tab.setIsMobile(obj.value(QStringLiteral("isMobile")).toBool());
    tab.setIsDeveloperToolsOpen(obj.value(QStringLiteral("isDeveloperToolsOpen")).toBool());
    return tab;
}

TabState::TabState(const QUrl &url, const bool isMobile)
{
    setIsMobile(isMobile);
    setUrl(url);
}

bool TabState::operator==(const TabState &other) const
{
    return (
        m_url == other.url() &&
        m_isMobile == other.isMobile() &&
        m_isDeveloperToolsOpen == other.isDeveloperToolsOpen()
    );
}

QJsonObject TabState::toJson() const
{
    return {
        {QStringLiteral("url"), m_url.toString()},
        {QStringLiteral("isMobile"), m_isMobile},
        {QStringLiteral("isDeveloperToolsOpen"), m_isDeveloperToolsOpen},
    };
}
