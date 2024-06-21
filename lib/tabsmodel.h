/*
 *  SPDX-FileCopyrightText: 2020 Jonah Brüchert <jbb@kaidan.im>
 *
 *  SPDX-License-Identifier: LGPL-2.0-only
 */

#ifndef TABSMODEL_H
#define TABSMODEL_H

#include <QAbstractListModel>
#include <QUrl>

class QJsonObject;

class TabState
{
public:
    static TabState fromJson(const QJsonObject &obj);
    QJsonObject toJson() const;

    TabState() = default;
    TabState(const QUrl &url, const bool isMobile);

    bool operator==(const TabState &other) const;

    bool isMobile() const;
    void setIsMobile(bool isMobile);

    bool isDeveloperToolsOpen() const;
    void setIsDeveloperToolsOpen(bool isDeveloperToolsOpen);

    QUrl url() const;
    void setUrl(const QUrl &url);

private:
    QUrl m_url;
    bool m_isMobile = true;
    bool m_isDeveloperToolsOpen = false;
};

class TabsModel : public QAbstractListModel
{
    Q_OBJECT

    Q_PROPERTY(int currentTab READ currentTab WRITE setCurrentTab NOTIFY currentTabChanged)
    Q_PROPERTY(bool isMobileDefault READ isMobileDefault WRITE setIsMobileDefault NOTIFY isMobileDefaultChanged)
    Q_PROPERTY(bool privateMode READ privateMode WRITE setPrivateMode NOTIFY privateModeChanged REQUIRED)

    enum RoleNames { UrlRole = Qt::UserRole + 1, IsMobileRole, IsDeveloperToolsOpen };

public:
    explicit TabsModel(QObject *parent = nullptr);

    QHash<int, QByteArray> roleNames() const override;
    QVariant data(const QModelIndex &index, int role) const override;
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;

    int currentTab() const;
    void setCurrentTab(int index);

    const std::vector<TabState> &tabs() const;

    Q_INVOKABLE TabState tab(int index);

    Q_INVOKABLE void loadInitialTabs();

    Q_INVOKABLE void newTab(const QUrl &url);
    Q_INVOKABLE void createEmptyTab();
    Q_INVOKABLE void setLatestTab();
    Q_INVOKABLE void closeTab(int index);

    Q_INVOKABLE void setUrl(int index, const QUrl &url);
    Q_INVOKABLE void setIsMobile(int index, bool isMobile);
    Q_INVOKABLE void toggleDeveloperTools(int index);

    Q_INVOKABLE bool isDeveloperToolsOpen(int index);
    bool isMobileDefault() const;
    void setIsMobileDefault(bool def);

    bool privateMode() const;
    void setPrivateMode(bool privateMode);

protected:
    bool loadTabs();
    bool saveTabs() const;

private:
    int m_currentTab = 0;
    std::vector<TabState> m_tabs{};
    bool m_privateMode = false;
    bool m_tabsReadOnly = false;
    bool m_isMobileDefault = false;
    bool m_initialTabsLoaded = false;

Q_SIGNALS:
    void currentTabChanged();
    void isMobileDefaultChanged();
    void privateModeChanged();
};

#endif // TABSMODEL_H
