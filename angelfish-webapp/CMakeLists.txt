# SPDX-FileCopyrightText: 2020 Jonah Brüchert <jbb@kaidan.im>
# SPDX-FileCopyrightText: 2020 Rinigus <rinigus.git@gmail.com>
#
# SPDX-License-Identifier: LGPL-2.0-or-later

set(angelfish_webapp_SRCS
    main.cpp
    webapp-resources.qrc
)

add_executable(angelfish-webapp ${angelfish_webapp_SRCS} ${RESOURCES} ${WEBAPP_RESOURCES})

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
    KF${QT_MAJOR_VERSION}::I18n
    KF${QT_MAJOR_VERSION}::CoreAddons
    AngelfishCore
    AngelfishCoreplugin
)

if(QT_MAJOR_VERSION STREQUAL "6")
    target_link_libraries(angelfish-webapp PRIVATE Qt::WebEngineCore Qt::WebEngineQuick)
else()
    target_link_libraries(angelfish-webapp PRIVATE Qt::WebEngine)
endif()

install(TARGETS angelfish-webapp ${KDE_INSTALL_TARGETS_DEFAULT_ARGS})

