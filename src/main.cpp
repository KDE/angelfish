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
#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
#include <QtWebEngine>
#else
#include <QtWebEngineQuick>
#endif

#include <KDBusService>
#include <KLocalizedContext>
#include <KLocalizedString>
#include <KWindowSystem>

#include <csignal>
#include <ranges>

#include "adblockfilterlistsmanager.h"
#include "adblockfilterlistsmodel.h"
#include "adblockurlinterceptor.h"
#include "angelfishsettings.h"
#include "angelfishwebprofile.h"
#include "bookmarkshistorymodel.h"
#include "browsermanager.h"
#include "domdistiller.h"
#include "downloadsmodel.h"
#include "iconimageprovider.h"
#include "tabsmodel.h"
#include "urlobserver.h"
#include "urlutils.h"
#include "useragent.h"
#include "version.h"
#include "webappcreator.h"
#include "webappmanagermodel.h"

namespace ranges = std::ranges;

constexpr auto APPLICATION_ID = "org.kde.angelfish";

Q_DECL_EXPORT int main(int argc, char *argv[])
{
    // set default style and icon theme
    QIcon::setFallbackThemeName(QStringLiteral("breeze"));
    if (qEnvironmentVariableIsEmpty("QT_QUICK_CONTROLS_STYLE") && QQuickStyle::name().isEmpty()) {
        QQuickStyle::setStyle(QStringLiteral("org.kde.desktop"));
    }

    QGuiApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QGuiApplication::setAttribute(Qt::AA_ShareOpenGLContexts);

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
#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
    QtWebEngine::initialize();
#else
    QtWebEngineQuick::initialize();
#endif

    QApplication app(argc, argv);
    QCoreApplication::setOrganizationName(QStringLiteral("KDE"));
    QCoreApplication::setOrganizationDomain(QStringLiteral("kde.org"));
    QCoreApplication::setApplicationName(QStringLiteral("angelfish"));
    QCoreApplication::setApplicationVersion(QStringLiteral(ANGELFISH_VERSION_STRING));
    QGuiApplication::setDesktopFileName(QStringLiteral("org.kde.angelfish"));
    KLocalizedString::setApplicationDomain("angelfish");

#if QT_VERSION <= QT_VERSION_CHECK(5, 14, 0)
    QtWebEngine::initialize();
#endif

    // Command line parser
    QCommandLineParser parser;
    parser.addPositionalArgument(QStringLiteral("url"), i18n("URL to open"), QStringLiteral("[url]"));
    parser.addHelpOption();
    parser.addVersionOption();
    parser.process(app);

    // QML loading
    QQmlApplicationEngine engine;

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

    // register as early possible so it has time to load, constructor doesn't block
    qmlRegisterSingletonInstance<AdblockUrlInterceptor>(APPLICATION_ID, 1, 0, "AdblockUrlInterceptor", &AdblockUrlInterceptor::instance());

    engine.rootContext()->setContextObject(new KLocalizedContext(&engine));

    engine.addImageProvider(IconImageProvider::providerId(), new IconImageProvider());

    // initial url command line parameter
    if (!parser.positionalArguments().isEmpty()) {
        const auto initialUrl = QUrl::fromUserInput(parser.positionalArguments().constFirst());
        if (initialUrl.isValid()) {
            BrowserManager::instance()->setInitialUrl(initialUrl);
        }
        BrowserManager::instance()->setInitialUrl(initialUrl);
    }

    // Exported types
    qmlRegisterType<BookmarksHistoryModel>(APPLICATION_ID, 1, 0, "BookmarksHistoryModel");
    qmlRegisterType<UrlObserver>(APPLICATION_ID, 1, 0, "UrlObserver");
    qmlRegisterType<UserAgent>(APPLICATION_ID, 1, 0, "UserAgentGenerator");
    qmlRegisterType<TabsModel>(APPLICATION_ID, 1, 0, "TabsModel");
    qmlRegisterType<AngelfishWebProfile>(APPLICATION_ID, 1, 0, "AngelfishWebProfile");
    qmlRegisterSingletonInstance<AngelfishSettings>(APPLICATION_ID, 1, 0, "Settings", AngelfishSettings::self());
    qmlRegisterType<AdblockFilterListsModel>(APPLICATION_ID, 1, 0, "AdblockFilterListsModel");
    qmlRegisterType<DownloadsModel>(APPLICATION_ID, 1, 0, "DownloadsModel");
    qmlRegisterType<WebAppManagerModel>(APPLICATION_ID, 1, 0, "WebAppManagerModel");
    qmlRegisterType<WebAppCreator>(APPLICATION_ID, 1, 0, "WebAppCreator");
    qmlRegisterAnonymousType<QWebEngineUrlRequestInterceptor>(APPLICATION_ID, 1);

    // Dom Distiller
    qmlRegisterSingletonType<DomDistiller>(APPLICATION_ID, 1, 0, "DomDistiller", [](QQmlEngine *, QJSEngine *) -> QObject * {
        return new DomDistiller();
    });

    // URL utils
    qmlRegisterSingletonType<UrlUtils>(APPLICATION_ID, 1, 0, "UrlUtils", [](QQmlEngine *, QJSEngine *) -> QObject * {
        return new UrlUtils();
    });

    // Browser Manager
    qmlRegisterSingletonType<BrowserManager>(APPLICATION_ID, 1, 0, "BrowserManager", [](QQmlEngine *, QJSEngine *) -> QObject * {
        return BrowserManager::instance();
    });

    Q_INIT_RESOURCE(resources);

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

    const QUrl url(SettingsHelper::isMobile()
                   ? QStringLiteral("qrc:/mobile.qml")
                   : QStringLiteral("qrc:/desktop.qml"));
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreated,
        &app,
        [url](QObject* obj, const QUrl& objUrl) {
            if ((obj == nullptr) && url == objUrl) {
                QCoreApplication::exit(-1);
            }
        },
        Qt::QueuedConnection);
    engine.load(url);

    // Error handling
    if (engine.rootObjects().isEmpty()) {
        return -1;
    }

    const auto window = qobject_cast<QQuickWindow *>(engine.rootObjects().constFirst());
    QObject::connect(window, &QQuickWindow::widthChanged, AngelfishSettings::self(), [window] {
        AngelfishSettings::setWindowWidth(window->width());
    });
    QObject::connect(window, &QQuickWindow::heightChanged, AngelfishSettings::self(), [window] {
        AngelfishSettings::setWindowHeight(window->height());
    });
    QObject::connect(window, &QQuickWindow::xChanged, AngelfishSettings::self(), [window] {
        AngelfishSettings::setWindowX(window->x());
    });
    QObject::connect(window, &QQuickWindow::yChanged, AngelfishSettings::self(), [window] {
        AngelfishSettings::setWindowY(window->y());
    });

    return app.exec();
}
