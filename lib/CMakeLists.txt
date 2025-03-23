add_library(AngelfishCore STATIC)

ecm_add_qml_module(AngelfishCore
    URI org.kde.angelfish.core
    GENERATE_PLUGIN_SOURCE

    QML_FILES
        contents/ui/AuthSheet.qml
        contents/ui/DownloadQuestion.qml
        contents/ui/ErrorHandler.qml
        contents/ui/JavaScriptDialogSheet.qml
        contents/ui/ListWebView.qml
        contents/ui/PermissionQuestion.qml
        contents/ui/PrintPreview.qml
        contents/ui/Questions.qml
        contents/ui/WebDeveloperTools.qml
        contents/ui/WebView.qml

    SOURCES
        browsermanager.cpp
        bookmarkshistorymodel.cpp
        dbmanager.cpp
        iconimageprovider.cpp
        urlutils.cpp
        urlobserver.cpp
        useragent.cpp
        tabsmodel.cpp
        settingshelper.cpp
        angelfishwebprofile.cpp
        downloadmanager.cpp
)

qt_add_resources(AngelfishCore "resources"
    PREFIX "/"
    FILES
        contents/migrations/2022-08-14-223019_init/up.sql
)

kconfig_add_kcfg_files(AngelfishCore GENERATE_MOC angelfishsettings.kcfgc)

target_include_directories(AngelfishCore PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
target_compile_definitions(AngelfishCore PRIVATE -DQT_NO_CAST_FROM_ASCII)
target_link_libraries(AngelfishCore PUBLIC
    Qt::Core
    Qt::Qml
    Qt::Sql
    KF${QT_MAJOR_VERSION}::ConfigCore
    KF${QT_MAJOR_VERSION}::ConfigGui
    KF${QT_MAJOR_VERSION}::I18n
    KF${QT_MAJOR_VERSION}::Notifications
    FutureSQL${QT_MAJOR_VERSION}::FutureSQL
    QCoro${QT_MAJOR_VERSION}::Core
    QCoro${QT_MAJOR_VERSION}::Quick
)

if(QT_MAJOR_VERSION STREQUAL "6")
    target_link_libraries(AngelfishCore PRIVATE Qt::WebEngineCore Qt::WebEngineQuick)
else()
    target_link_libraries(AngelfishCore PRIVATE Qt::WebEngine)
endif()

install(FILES angelfishsettings.kcfg DESTINATION ${KDE_INSTALL_KCFGDIR})
install(FILES angelfish.notifyrc DESTINATION ${KDE_INSTALL_KNOTIFYRCDIR})
