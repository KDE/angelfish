# SPDX-FileCopyrightText: 2020 Jonah Brüchert <jbb@kaidan.im>
# SPDX-FileCopyrightText: 2020 Rinigus <rinigus.git@gmail.com>
#
# SPDX-License-Identifier: LGPL-2.0-or-later

add_executable(angelfish-webapp main.cpp)

ecm_add_qml_module(angelfish-webapp
    GENERATE_PLUGIN_SOURCE
    URI org.kde.angelfish.webapp
)

ecm_target_qml_sources(angelfish-webapp
    SOURCES
        qml/WebAppView.qml
        qml/WebApp.qml
)

target_include_directories(angelfish-webapp PRIVATE ../src/)
target_compile_definitions(angelfish-webapp PRIVATE -DQT_NO_CAST_FROM_ASCII)
target_link_libraries(angelfish-webapp PRIVATE
    Qt::Core
    Qt::Qml
    Qt::Quick
    Qt::QuickControls2
    Qt::Sql
    Qt::Svg
    Qt::Widgets
    KF6::I18n
    KF6::CoreAddons
    AngelfishCore
    AngelfishCoreplugin
)

target_link_libraries(angelfish-webapp PRIVATE Qt::WebEngineCore Qt::WebEngineQuick)

install(TARGETS angelfish-webapp ${KDE_INSTALL_TARGETS_DEFAULT_ARGS})

