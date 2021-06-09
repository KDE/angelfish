# SPDX-FileCopyrightText: 2020 Jonah Brüchert <jbb@kaidan.im>
# SPDX-FileCopyrightText: 2020 Rinigus <rinigus.git@gmail.com>
#
# SPDX-License-Identifier: LGPL-2.0-or-later

set(angelfish_SRCS
    main.cpp
    adblockfilterlistsmodel.cpp
    adblockfilterlistsmanager.cpp
    adblockurlinterceptor.cpp
    downloadsmodel.cpp
    webappcreator.cpp
    webappmanager.cpp
    webappmanagermodel.cpp
    readerview.cpp
    angelfish.qrc
)

add_executable(angelfish ${angelfish_SRCS})

if (Corrosion_FOUND)
    corrosion_import_crate(MANIFEST_PATH ${CMAKE_SOURCE_DIR}/Cargo.toml CRATES angelfish-adblock angelfish-readability)
    target_link_libraries(angelfish PRIVATE angelfish-adblock angelfish-readability)
    target_compile_definitions(angelfish PRIVATE -DHAVE_RUST)

    target_include_directories(angelfish PRIVATE
        ${CMAKE_BINARY_DIR}/cargo/build/${Rust_CARGO_TARGET}/cxxbridge/angelfish-adblock/src/
        ${CMAKE_BINARY_DIR}/cargo/build/${Rust_CARGO_TARGET}/cxxbridge/angelfish-readability/src/)
endif()

target_include_directories(angelfish PRIVATE ${CMAKE_BINARY_DIR})
target_compile_definitions(angelfish PRIVATE -DQT_NO_CAST_FROM_ASCII)
target_link_libraries(angelfish PRIVATE
    Qt5::Core
    Qt5::Qml
    Qt5::Quick
    Qt5::Sql
    Qt5::Svg
    Qt5::WebEngine
    KF5::I18n
    KF5::ConfigCore
    KF5::ConfigGui
    KF5::DBusAddons
    KF5::WindowSystem
    AngelfishCore
)

install(TARGETS angelfish ${KF5_INSTALL_TARGETS_DEFAULT_ARGS})
install(FILES angelfish.notifyrc DESTINATION ${KNOTIFYRC_INSTALL_DIR})
