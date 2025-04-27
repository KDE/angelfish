/*
    SPDX-FileCopyrightText: 2019 Jonah Brüchert <jbb.prv@gmx.de>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

#include <QApplication>
#include <QCommandLineOption>
#include <QCommandLineParser>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QUrl>
#include <QtQml>
#include <QtWebEngineQuick>

#include <KAboutData>
#include <KDesktopFile>
#include <KLocalizedContext>
#include <KLocalizedString>

#include "angelfishsettings.h"
#include "browsermanager.h"
#include "iconimageprovider.h"

constexpr auto APPLICATION_ID = "org.kde.angelfish";

QString desktopFileDirectory()
{
    if (!QStandardPaths::locate(QStandardPaths::RuntimeLocation, QStringLiteral("flatpak-info")).isEmpty()) {
        return qEnvironmentVariable("HOME") % u"/.local/share/applications/";
    }
    return QStandardPaths::writableLocation(QStandardPaths::ApplicationsLocation);
}

Q_DECL_EXPORT int main(int argc, char *argv[])
{
    // set default style and icon theme
    QIcon::setFallbackThemeName(QStringLiteral("breeze"));
    if (qEnvironmentVariableIsEmpty("QT_QUICK_CONTROLS_STYLE") && QQuickStyle::name().isEmpty()) {
        QQuickStyle::setStyle(QStringLiteral("org.kde.desktop"));
    }
    QGuiApplication::setAttribute(Qt::AA_ShareOpenGLContexts);

    KLocalizedString::setApplicationDomain("angelfish");

    // Setup QtWebEngine
    qputenv("QTWEBENGINE_DIALOG_SET", "QtQuickControls2");
    QString chromiumFlags;
    if (AngelfishSettings::self()->webSmoothScrollingEnabled()) {
        chromiumFlags.append(QStringLiteral(" --enable-smooth-scrolling"));
    }
    if (AngelfishSettings::self()->webDarkModeEnabled()) {
        chromiumFlags.append(QStringLiteral(" --blink-settings=forceDarkModeEnabled=true"));
    }
    qputenv("QTWEBENGINE_CHROMIUM_FLAGS", chromiumFlags.toUtf8());
    QtWebEngineQuick::initialize();

    QApplication app(argc, argv);
    // QCoreApplication::setOrganizationName("KDE");
    // QCoreApplication::setOrganizationDomain("mobile.kde.org");
    // QCoreApplication::setApplicationName("angelfish");

    // Command line parser
    QCommandLineParser parser;
    parser.addPositionalArgument(QStringLiteral("desktopfile"), i18n("desktop file to open"), QStringLiteral("[file]"));
    parser.addHelpOption();
    parser.process(app);

    // QML loading
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextObject(new KLocalizedContext(&engine));

    engine.addImageProvider(IconImageProvider::providerId(), new IconImageProvider());

    if (parser.positionalArguments().isEmpty()) {
        return 1;
    }

    const QString fileName = parser.positionalArguments().constFirst();
    const QString path = desktopFileDirectory() % QDir::separator() % fileName;
    const KDesktopFile desktopFile(path);
    if (desktopFile.readUrl().isEmpty()) {
        qDebug() << "Failed to find url in" << path;
        return 2;
    }
    const QUrl initialUrl = QUrl::fromUserInput(desktopFile.readUrl());

    const QString appName = desktopFile.readName().toLower().replace(QLatin1Char(' '), QLatin1Char('-')) + QStringLiteral("-angelfish-webapp");
    KAboutData aboutData(appName.toLower(),
                         desktopFile.readName(),
                         QStringLiteral("0.1"),
                         i18n("Angelfish Web App runtime"),
                         KAboutLicense::GPL,
                         i18n("Copyright 2020 Angelfish developers"));
    QApplication::setWindowIcon(QIcon::fromTheme(desktopFile.readIcon()));
    aboutData.addAuthor(i18n("Marco Martin"), QString(), QStringLiteral("mart@kde.org"));

    KAboutData::setApplicationData(aboutData);

    BrowserManager::instance()->setInitialUrl(initialUrl);

    // Load QML
    engine.loadFromModule("org.kde.angelfish.webapp", "WebApp");

    // Error handling
    if (engine.rootObjects().isEmpty()) {
        return -1;
    }

    return app.exec();
}
