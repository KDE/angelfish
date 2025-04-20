# SPDX-FileCopyrightText: 2020 Jonah Brüchert <jbb@kaidan.im>
# SPDX-FileCopyrightText: 2020 Rinigus <rinigus.git@gmail.com>
#
# SPDX-License-Identifier: LGPL-2.0-or-later

add_subdirectory(settings)

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
    angelfish.qrc
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
    if (Corrosion_VERSION VERSION_LESS 0.5.0)
        target_link_libraries(angelfish PRIVATE angelfish-adblock)
    else()
        target_link_libraries(angelfish PRIVATE angelfish_adblock)
    endif()
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
    Qt::WebEngineCore
    Qt::WebEngineQuick
    KF6::I18n
    KF6::CoreAddons
    KF6::ConfigCore
    KF6::ConfigGui
    KF6::DBusAddons
    KF6::WindowSystem
    QCoro6::Qml
    AngelfishCore
    angelfish_settingsplugin
)

install(TARGETS angelfish ${KDE_INSTALL_TARGETS_DEFAULT_ARGS})
