# SPDX-FileCopyrightText: 2014-2015 Sebastian Kügler <sebas@kde.org>
# SPDX-FileCopyrightText: 2020 Jonah Brüchert <jbb@kaidan.im>
#
# SPDX-License-Identifier: LGPL-2.0-or-later

cmake_minimum_required(VERSION 3.16.0)

# KDE Applications version, managed by release script.
set(RELEASE_SERVICE_VERSION_MAJOR "24")
set(RELEASE_SERVICE_VERSION_MINOR "08")
set(RELEASE_SERVICE_VERSION_MICRO "1")
set(RELEASE_SERVICE_VERSION "${RELEASE_SERVICE_VERSION_MAJOR}.${RELEASE_SERVICE_VERSION_MINOR}.${RELEASE_SERVICE_VERSION_MICRO}")

project(angelfish VERSION ${RELEASE_SERVICE_VERSION})

set(KF_MIN_VERSION "5.240")
set(QT_MIN_VERSION "6.4")
set(QCORO_MIN_VERSION "0.7.0")


set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

option(BUILD_TESTING "Build test programs" ON)

################# Disallow in-source build #################

if("${CMAKE_SOURCE_DIR}" STREQUAL "${CMAKE_BINARY_DIR}")
   message(FATAL_ERROR "This application requires an out of source build. Please create a separate build directory.")
endif()

include(FeatureSummary)

################# set KDE specific information #################

find_package(ECM ${KF_MIN_VERSION} REQUIRED NO_MODULE)

# where to look first for cmake modules, before ${CMAKE_ROOT}/Modules/ is checked
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${ECM_MODULE_PATH})

include(ECMSetupVersion)
include(ECMGenerateHeaders)
include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDEClangFormat)
include(ECMPoQmTools)
include(ECMFindQmlModule)
include(ECMQmlModule)
include(KDECompilerSettings NO_POLICY_SCOPE)

ecm_setup_version(${PROJECT_VERSION}
    VARIABLE_PREFIX ANGELFISH
    VERSION_HEADER ${CMAKE_CURRENT_BINARY_DIR}/version.h
)

################# Find dependencies #################

find_package(Qt6 ${QT_MIN_VERSION} REQUIRED NO_MODULE COMPONENTS Core Quick Test Gui Svg QuickControls2 Sql Widgets)
find_package(Qt6 ${QT_MIN_VERSION} OPTIONAL_COMPONENTS Feedback)
find_package(KF6 ${KF_MIN_VERSION} REQUIRED COMPONENTS Kirigami Purpose I18n Config CoreAddons DBusAddons WindowSystem Notifications OPTIONAL_COMPONENTS QQC2DesktopStyle)
find_package(KF6KirigamiAddons 0.6 REQUIRED)
set_package_properties(KF6QQC2DesktopStyle PROPERTIES TYPE RUNTIME)

# Necessary to support QtWebEngine installed in a different prefix than the rest of Qt (e.g flatpak)
find_package(Qt6WebEngineCore REQUIRED)
find_package(Qt6WebEngineQuick REQUIRED)

find_package(FutureSQL6 REQUIRED)
find_package(QCoro6 ${QCORO_MIN_VERSION} REQUIRED COMPONENTS Core Quick Qml)

# For adblocker
find_package(Corrosion)
set_package_properties(Corrosion PROPERTIES
    TYPE RECOMMENDED
    PURPOSE "Required to build the builtin adblocker"
    DESCRIPTION "CMake scripts to seamlessly build and link to targets using cargo"
    URL https://github.com/AndrewGaspar/corrosion
)

################# Definitions to pass to the compiler #################

add_definitions(-DQT_NO_FOREACH -DQT_NO_URL_CAST_FROM_STRING)
kde_enable_exceptions()
qcoro_enable_coroutines()

if (NOT Qt6Feedback_FOUND)
    message(WARNING "Qt Feedback dependency is not found.\n"
        "While it is optional since unmaintained, haptics feedback functionality is not supported without it.")
endif()

################# build and install #################
add_subdirectory(lib)
add_subdirectory(src)
if (BUILD_TESTING)
    add_subdirectory(autotests)
endif()
add_subdirectory(angelfish-webapp)

ki18n_install(po)

install(PROGRAMS org.kde.angelfish.desktop DESTINATION ${KDE_INSTALL_APPDIR})
install(FILES org.kde.angelfish.metainfo.xml DESTINATION ${KDE_INSTALL_METAINFODIR})
install(FILES org.kde.angelfish.svg DESTINATION ${KDE_INSTALL_FULL_ICONDIR}/hicolor/scalable/apps)

feature_summary(WHAT ALL INCLUDE_QUIET_PACKAGES FATAL_ON_MISSING_REQUIRED_PACKAGES)

file(GLOB_RECURSE ALL_CLANG_FORMAT_SOURCE_FILES src/*.cpp src/*.h lib/*.cpp lib/*.h angelfish-webapp/*.cpp angelfish-webapp/*.h)
kde_clang_format(${ALL_CLANG_FORMAT_SOURCE_FILES})
