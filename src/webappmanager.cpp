// SPDX-FileCopyrightText: 2021 Jonah Brüchert <jbb@kaidan.im>
//
// SPDX-License-Identifier: GPL-2.0-or-later

#include "webappmanager.h"

#include <QStandardPaths>
#include <QImage>

#include <KDesktopFile>
#include <KConfigGroup>

WebAppManager::WebAppManager(QObject *parent)
    : QObject(parent)
    , m_desktopFileDirectory(desktopFileDirectory())
{
    const auto fileInfos = m_desktopFileDirectory
            .entryInfoList(QDir::Files);

    // Likely almost all files in the directory are webapps, so this should be worth it
    m_webApps.reserve(fileInfos.size());

    for (const auto &file : fileInfos) {
        // Make sure to only parse desktop files
        if (file.fileName().contains(QStringView(u".desktop"))) {
            KDesktopFile desktopFile(file.filePath());

            // Only handle desktop files referencing angelfish-webapp
            if (desktopFile.group("Desktop Entry").readEntry("Exec").contains(QStringView(u"angelfish-webapp"))) {
                WebApp app {
                    desktopFile.readName(),
                    desktopFile.readIcon(),
                    desktopFile.readUrl()
                };

                m_webApps.push_back(std::move(app));
            }
        }
    }
}

QString WebAppManager::desktopFileDirectory()
{
    return QStandardPaths::writableLocation(QStandardPaths::ApplicationsLocation);
}

QString WebAppManager::iconDirectory()
{
    return QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation)
            + QStringLiteral("/icons/hicolor/16x16/apps/");
}

const std::vector<WebApp> &WebAppManager::applications() const
{
    return m_webApps;
}

void WebAppManager::addApp(const QString &name, const QString &url, const QImage &icon)
{
    const QString location = desktopFileDirectory();
    const QString iconLocation = iconDirectory();
    const QString filename = generateFileName(name);

    icon.save(QStringLiteral("%1/%2.png").arg(iconLocation, filename), "PNG");
    KConfig desktopFile(QStringLiteral("%1/%2.desktop").arg(location, filename), KConfig::SimpleConfig);

    auto desktopEntry = desktopFile.group("Desktop Entry");
    desktopEntry.writeEntry(QStringLiteral("URL"), url);
    desktopEntry.writeEntry(QStringLiteral("Name"), name);
    desktopEntry.writeEntry(QStringLiteral("Exec"), QStringLiteral("%1 %2.desktop").arg(webAppCommand(), filename));
    desktopEntry.writeEntry(QStringLiteral("Icon"), filename);

    m_webApps.push_back(WebApp {
        name,
        filename,
        url
    });

    desktopFile.sync();

    Q_EMIT applicationsChanged();
}

bool WebAppManager::exists(const QString &name)
{
    const QString location = desktopFileDirectory();
    const QString filename = generateFileName(name);

    auto exists = QFile::exists(QStringLiteral("%1/%2.desktop").arg(location, filename));
    return exists;
}

bool WebAppManager::removeApp(const QString &name)
{
    const QString location = desktopFileDirectory();
    const QString filename = generateFileName(name);

    auto it = std::remove_if(m_webApps.begin(), m_webApps.end(), [&name](const WebApp &app) {
        return app.name == name;
    });

    m_webApps.erase(it);

    Q_EMIT applicationsChanged();

    return QFile::remove(QStringLiteral("%1/%2.desktop").arg(location, filename));
}

WebAppManager &WebAppManager::instance()
{
    static WebAppManager instance;
    return instance;
}

QString WebAppManager::generateFileName(const QString &name)
{
    QString filename = name.toLower();
    filename.replace(QStringLiteral(" "), QStringLiteral("_"));
    filename.replace(QStringLiteral("'"), QLatin1String());
    filename.replace(QStringLiteral("\""), QLatin1String());
    return filename;
}

QString WebAppManager::webAppCommand()
{
    if (!QStandardPaths::locate(QStandardPaths::RuntimeLocation, QStringLiteral("flatpak-info")).isEmpty()) {
        return QStringLiteral(
                   "flatpak run "
                   "--command=angelfish-webapp "
                   "--filesystem=%1 "
                   "org.kde.mobile.angelfish")
            .arg(QStandardPaths::writableLocation(QStandardPaths::ApplicationsLocation));
    }

    return QStringLiteral("angelfish-webapp");
}
