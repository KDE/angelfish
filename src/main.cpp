/*
    SPDX-FileCopyrightText: 2019 Jonah Brüchert <jbb.prv@gmx.de>
    SPDX-FileCopyrightText: 2021 Carson Black <uhhadd@gmail.com>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

#include <QApplication>
#include <QCommandLineOption>
#include <QCommandLineParser>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QUrl>
#include <QtQml>
#include <QtWebEngineQuick>

#include <KAboutData>
#include <KCrash>
#include <KDBusService>
#include <KLocalizedContext>
#include <KLocalizedString>
#include <KWindowSystem>

#include <csignal>

#include "angelfishsettings.h"
#include "browsermanager.h"
#include "version.h"
#include "tabsmodel.h"

namespace ranges = std::ranges;

constexpr auto APPLICATION_ID = "org.kde.angelfish";

using namespace Qt::StringLiterals;

Q_DECL_EXPORT int main(int argc, char *argv[])
{
    // set default style and icon theme
    QIcon::setFallbackThemeName(QStringLiteral("breeze"));
    if (qEnvironmentVariableIsEmpty("QT_QUICK_CONTROLS_STYLE") && QQuickStyle::name().isEmpty()) {
        QQuickStyle::setStyle(QStringLiteral("org.kde.desktop"));
    }

    QGuiApplication::setAttribute(Qt::AA_ShareOpenGLContexts);

    // Setup QtWebEngine
    qputenv("QTWEBENGINE_DIALOG_SET", "QtQuickControls2");
    QString chromiumFlags = qEnvironmentVariable("QTWEBENGINE_CHROMIUM_FLAGS");
    if (AngelfishSettings::self()->webSmoothScrollingEnabled()) {
        chromiumFlags.append(QStringLiteral(" --enable-smooth-scrolling"));
    }
    if (AngelfishSettings::self()->webDarkModeEnabled()) {
        chromiumFlags.append(QStringLiteral(" --blink-settings=forceDarkModeEnabled=true"));
    }
    qputenv("QTWEBENGINE_CHROMIUM_FLAGS", chromiumFlags.toUtf8());

    QtWebEngineQuick::initialize();

    QApplication app(argc, argv);
    app.setWindowIcon(QIcon::fromTheme(QStringLiteral("org.kde.angelfish"), app.windowIcon()));
    QCoreApplication::setOrganizationName(QStringLiteral("KDE"));
    QCoreApplication::setOrganizationDomain(QStringLiteral("kde.org"));
    QCoreApplication::setApplicationName(QStringLiteral("angelfish"));
    QCoreApplication::setApplicationVersion(QStringLiteral(ANGELFISH_VERSION_STRING));
    QGuiApplication::setDesktopFileName(QStringLiteral("org.kde.angelfish"));
    KLocalizedString::setApplicationDomain("angelfish");

    // Command line parser
    QCommandLineParser parser;
    parser.addPositionalArgument(QStringLiteral("url"), i18n("URL to open"), QStringLiteral("[url]"));
    parser.addHelpOption();
    parser.addVersionOption();
    parser.process(app);

    // QML loading
    QQmlApplicationEngine engine;

    // Define your about data
    KAboutData aboutData(
        QStringLiteral("angelfish"),
        i18n("Angelfish"),
        QStringLiteral(ANGELFISH_VERSION_STRING),
        i18n("Web browser for Plasma Mobile"),
        KAboutLicense::GPL_V3,
        i18n("© 2015-2024 KDE Community")
    );

    aboutData.addAuthor(i18n("Jonah Brüchert"), i18n("Maintainer"), QStringLiteral("jbb@kaidan.im"));
    aboutData.setTranslator(i18nc("NAME OF TRANSLATORS", "Your names"), i18nc("EMAIL OF TRANSLATORS", "Your emails"));
    aboutData.setOrganizationDomain("kde.org");
    aboutData.setBugAddress("https://bugs.kde.org/describecomponents.cgi?product=angelfish");
    KAboutData::setApplicationData(aboutData);

    // Crash Handling
    KCrash::initialize();

    // Open links in the already running window when e.g clicked on in another application.
    KDBusService service(KDBusService::Unique, &app);
    QObject::connect(&service, &KDBusService::activateRequested, &app, [&parser, &engine](const QStringList &arguments) {
        parser.parse(arguments);

        auto *webbrowserWindow = qobject_cast<QQuickWindow *>(engine.rootObjects().constFirst());
        if (!webbrowserWindow) {
            qWarning() << "No webbrowser window is open, can't activate";
            return;
        }

        if (!parser.positionalArguments().isEmpty()) {
            const QUrl initialUrl = QUrl::fromUserInput(parser.positionalArguments().constFirst());
            const auto *pageStack = webbrowserWindow->property("pageStack").value<QObject *>();
            const auto *initialPage = pageStack->property("initialPage").value<QObject *>();

            // This should be initialPage->findChild<TabsModel *>(QStringLiteral("regularTabsObject")), for some reason
            // it doesn't find our tabsModel.
            const auto children = initialPage->children();
            const auto *regularTabs = *ranges::find_if(children, [](const QObject *child) {
                return child->objectName() == QStringLiteral("regularTabsObject");
            });

            auto *tabsModel = regularTabs->property("tabsModel").value<TabsModel *>();
            // Open new tab with requested url
            tabsModel->newTab(initialUrl);
        }

        // Move window to the front
        KWindowSystem::updateStartupId(webbrowserWindow);
        KWindowSystem::activateWindow(webbrowserWindow);
    });

    engine.rootContext()->setContextObject(new KLocalizedContext(&engine));

    // initial url command line parameter
    if (!parser.positionalArguments().isEmpty()) {
        const auto initialUrl = QUrl::fromUserInput(parser.positionalArguments().constFirst());
        if (initialUrl.isValid()) {
            BrowserManager::instance()->setInitialUrl(initialUrl);
        }
        BrowserManager::instance()->setInitialUrl(initialUrl);
    }

    QObject::connect(QApplication::instance(), &QCoreApplication::aboutToQuit, QApplication::instance(), [] {
        AngelfishSettings::self()->save();
    });

    // Setup Unix signal handlers
    const auto unixExitHandler = [](int /*sig*/) -> void {
        QCoreApplication::quit();
    };

    const std::array<int, 4> quitSignals = {SIGQUIT, SIGINT, SIGTERM, SIGHUP};

    sigset_t blockingMask;
    sigemptyset(&blockingMask);
    for (const auto sig : quitSignals) {
        sigaddset(&blockingMask, sig);
    }

    struct sigaction sa;
    sa.sa_handler = unixExitHandler;
    sa.sa_mask = blockingMask;
    sa.sa_flags = 0;

    for (auto sig : quitSignals) {
        sigaction(sig, &sa, nullptr);
    }

    // Load QML

    const QString url(SettingsHelper::isMobile() ? u"Mobile"_s : u"Desktop"_s);

    engine.loadFromModule("org.kde.angelfish"_L1, url);

    // Error handling
    if (engine.rootObjects().isEmpty()) {
        return -1;
    }

    return app.exec();
}
