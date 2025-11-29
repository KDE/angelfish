# SPDX-FileCopyrightText: 2020 Jonah Brüchert <jbb@kaidan.im>
# SPDX-FileCopyrightText: 2020 Rinigus <rinigus.git@gmail.com>
#
# SPDX-License-Identifier: LGPL-2.0-or-later

add_subdirectory(settings)

add_executable(angelfish
    main.cpp
    adblockfilterlistsmodel.cpp
    adblockfilterlistsmanager.cpp
    adblockurlinterceptor.cpp
    downloadsmodel.cpp
    webappcreator.cpp
    webappmanager.cpp
    webappmanagermodel.cpp
    interfaceloader.cpp
)

ecm_add_qml_module(angelfish
    GENERATE_PLUGIN_SOURCE
    URI org.kde.angelfish
)

ecm_target_qml_sources(angelfish
    SOURCES
        qml/AdblockFilterDownloadQuestion.qml
        qml/Bookmarks.qml
        qml/Downloads.qml
        qml/FindInPageBar.qml
        qml/HapticsEffectLoader.qml
        qml/HapticsEffectWrapper.qml
        qml/History.qml
        qml/HistorySheet.qml
        qml/InputSheet.qml
        qml/Mobile.qml
        qml/Navigation.qml
        qml/NavigationEntrySheet.qml
        qml/ShareSheet.qml
        qml/Tabs.qml
        qml/UrlDelegate.qml

        qml/desktop/BookmarksPage.qml
        qml/desktop/Desktop.qml
        qml/desktop/HistoryPage.qml
        qml/desktop/TabHistory.qml
        qml/desktop/DesktopTabs.qml

        regex-weburl/RegexWebUrl.js
)

if (Corrosion_FOUND)
    add_custom_target(adblock
        SOURCES
        rs/adblock/Cargo.toml
        rs/adblock/build.rs
        rs/adblock/src/lib.rs
        rs/adblock/src/adblock.rs
        rs/adblock/src/domainresolver.rs
        rs/adblock/src/logging.rs)

    corrosion_import_crate(MANIFEST_PATH ${CMAKE_CURRENT_SOURCE_DIR}/rs/adblock/Cargo.toml)
    if (Corrosion_VERSION VERSION_LESS 0.5.0)
        target_link_libraries(angelfish PRIVATE angelfish-adblock)
    else()
        target_link_libraries(angelfish PRIVATE angelfish_adblock)
    endif()
    target_compile_definitions(angelfish PRIVATE -DBUILD_ADBLOCK)

    if(Corrosion_VERSION VERSION_LESS 0.6.0)
        set(corrosion_build_dir "build")
    else()
        string(SHA1 cargo_path_hash ${CMAKE_CURRENT_SOURCE_DIR}/rs/adblock/Cargo.toml)
        string(SUBSTRING "${cargo_path_hash}" 0 5 cargo_path_hash)
        set(corrosion_build_dir "adblock_${cargo_path_hash}")
    endif()

    target_include_directories(angelfish PRIVATE
        ${CMAKE_BINARY_DIR}/cargo/${corrosion_build_dir}/${Rust_CARGO_TARGET}/cxxbridge/angelfish-adblock/src/)
endif()

target_include_directories(angelfish PRIVATE ${CMAKE_BINARY_DIR})
target_compile_definitions(angelfish PRIVATE -DQT_NO_CAST_FROM_ASCII)
target_link_libraries(angelfish PRIVATE
    Qt::Core
    Qt::Qml
    Qt::Quick
    Qt::QuickControls2
    Qt::Sql
    Qt::Svg
    Qt::Widgets
    Qt::WebEngineCore
    Qt::WebEngineQuick
    KF6::I18n
    KF6::CoreAddons
    KF6::ConfigCore
    KF6::ConfigGui
    KF6::DBusAddons
    KF6::WindowSystem
    KF6::Crash
    QCoro6::Qml
    AngelfishCore
    AngelfishCoreplugin
    angelfish_settingsplugin
)

install(TARGETS angelfish ${KDE_INSTALL_TARGETS_DEFAULT_ARGS})
