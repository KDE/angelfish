# SPDX-FileCopyrightText: 2020 Jonah Brüchert <jbb@kaidan.im>
# SPDX-FileCopyrightText: 2020 Rinigus <rinigus.git@gmail.com>
#
# SPDX-License-Identifier: LGPL-2.0-or-later

configure_file(contents/ui/desktop/desktop.qml ${CMAKE_CURRENT_BINARY_DIR}/contents/ui/desktop/desktop.qml)
configure_file(contents/ui/mobile.qml ${CMAKE_CURRENT_BINARY_DIR}/contents/ui/mobile.qml)
configure_file(contents/ui/SettingsAdblock.qml ${CMAKE_CURRENT_BINARY_DIR}/contents/ui/SettingsAdblock.qml)

configure_file(angelfish.qrc ${CMAKE_CURRENT_SOURCE_DIR}/angelfish.generated.qrc)

set(angelfish_SRCS
    main.cpp
    adblockfilterlistsmodel.cpp
    adblockfilterlistsmanager.cpp
    adblockurlinterceptor.cpp
    domdistiller.cpp
    downloadsmodel.cpp
    webappcreator.cpp
    webappmanager.cpp
    webappmanagermodel.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/angelfish.generated.qrc
)

add_executable(angelfish ${angelfish_SRCS})

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
    target_link_libraries(angelfish PRIVATE angelfish-adblock)
    target_compile_definitions(angelfish PRIVATE -DBUILD_ADBLOCK)

    target_include_directories(angelfish PRIVATE
        ${CMAKE_BINARY_DIR}/cargo/build/${Rust_CARGO_TARGET}/cxxbridge/angelfish-adblock/src/)
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
    KF${QT_MAJOR_VERSION}::I18n
    KF${QT_MAJOR_VERSION}::CoreAddons
    KF${QT_MAJOR_VERSION}::ConfigCore
    KF${QT_MAJOR_VERSION}::ConfigGui
    KF${QT_MAJOR_VERSION}::DBusAddons
    KF${QT_MAJOR_VERSION}::WindowSystem
    AngelfishCore
)

if(QT_MAJOR_VERSION STREQUAL "6")
    target_link_libraries(angelfish PRIVATE Qt::CorePrivate Qt::WebEngineCore Qt::WebEngineQuick Qt::WebEngineQuickPrivate)
else()
    target_link_libraries(angelfish PRIVATE Qt::WebEngine)
endif()

install(TARGETS angelfish ${KDE_INSTALL_TARGETS_DEFAULT_ARGS})
