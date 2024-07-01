configure_file(contents/ui/WebView.qml ${CMAKE_CURRENT_BINARY_DIR}/contents/ui/WebView.qml @ONLY)
configure_file(contents/ui/PrintPreview.qml ${CMAKE_CURRENT_BINARY_DIR}/contents/ui/PrintPreview.qml @ONLY)

configure_file(resources.qrc ${CMAKE_CURRENT_SOURCE_DIR}/resources-angelfish.generated.qrc)

add_library(AngelfishCore STATIC
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
    ${CMAKE_CURRENT_SOURCE_DIR}/resources-angelfish.generated.qrc
)

kconfig_add_kcfg_files(AngelfishCore GENERATE_MOC angelfishsettings.kcfgc)

target_include_directories(AngelfishCore PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
target_compile_definitions(AngelfishCore PRIVATE -DQT_NO_CAST_FROM_ASCII)
target_link_libraries(AngelfishCore PUBLIC
    Qt::Core
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
