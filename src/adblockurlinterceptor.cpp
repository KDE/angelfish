// SPDX-FileCopyrightText: 2020 Jonah Brüchert <jbb@kaidan.im>
//
// SPDX-License-Identifier: GPL-2.0-or-later

#include "adblockurlinterceptor.h"

#include <QDebug>
#include <QDir>
#include <QLoggingCategory>
#include <QStandardPaths>
#include <QStringBuilder>

#include "adblockfilterlistsmanager.h"

#include "angelfishsettings.h"

namespace ranges = std::ranges;

Q_LOGGING_CATEGORY(AdblockCategory, "org.kde.angelfish.adblock", QtWarningMsg);

#ifdef BUILD_ADBLOCK
template <typename T>
auto toRustType(T input) {
    if constexpr (std::is_same_v<T, std::vector<QString>>) {
        std::vector<rust::String> rustStringVec;
        ranges::transform(input, std::back_inserter(rustStringVec), [](const QString &c) {
            return rust::String(c.toStdString());
        });
        return rustStringVec;
    }
}

template <typename T>
auto toQtType(T input) {
    if constexpr (std::is_same_v<T, rust::Vec<rust::String>>) {
        std::vector<QString> qStringVec;
        ranges::transform(input, std::back_inserter(qStringVec), [](const auto &c) {
            return QString::fromStdString(std::string(c));
        });
        return qStringVec;
    } else if constexpr (std::is_same_v<T, rust::String>) {
        return QString::fromStdString(std::string(input));
    }
}
#endif

AdblockUrlInterceptor::AdblockUrlInterceptor(QObject *parent)
    : QWebEngineUrlRequestInterceptor(parent)
#ifdef BUILD_ADBLOCK
    // parsing the block lists takes some time, try to do it asynchronously
    // if it is not ready when it's needed, reading the future will block
    , m_adblockInitFuture(std::async(std::launch::async, [this] { return createOrRestoreAdblock(); }))
    , m_adblock(std::nullopt)
#endif
    , m_enabled(AngelfishSettings::adblockEnabled())
{
#ifdef BUILD_ADBLOCK
    connect(this, &AdblockUrlInterceptor::adblockInitialized, this, [this] {
        if (m_adblockInitFuture.valid()) {
            qDebug() << "Adblock ready";
            m_adblock = m_adblockInitFuture.get();
        }
    });
#endif
}

#ifdef BUILD_ADBLOCK
rust::Box<Adblock> AdblockUrlInterceptor::createOrRestoreAdblock()
{
    rust::Box<Adblock> adb = [] {
        auto cacheLocation = adblockCacheLocation();
        if (QFile::exists(cacheLocation)) {
            return loadAdblock(cacheLocation.toStdString());
        }
        return newAdblock(AdblockFilterListsManager::filterListPath().toStdString());
    }();

    Q_EMIT adblockInitialized();
    return adb;
}
#endif

QString AdblockUrlInterceptor::adblockCacheLocation()
{
    return QStandardPaths::writableLocation(QStandardPaths::CacheLocation) % u"/adblockCache";
}

bool AdblockUrlInterceptor::enabled() const
{
    return m_enabled;
}

void AdblockUrlInterceptor::setEnabled(bool enabled)
{
    m_enabled = enabled;
    AngelfishSettings::setAdblockEnabled(enabled);
}

AdblockUrlInterceptor &AdblockUrlInterceptor::instance()
{
    static AdblockUrlInterceptor instance;

    return instance;
}

AdblockUrlInterceptor::~AdblockUrlInterceptor()
{
#ifdef BUILD_ADBLOCK
    if (m_adblock && (*m_adblock)->isValid() && (*m_adblock)->needsSave()) {
        (*m_adblock)->save(adblockCacheLocation().toStdString());
    }
#endif
}

bool AdblockUrlInterceptor::downloadNeeded() const
{
    return QDir(AdblockFilterListsManager::filterListPath()).isEmpty();
}

void AdblockUrlInterceptor::resetAdblock()
{
#ifdef BUILD_ADBLOCK
    if (m_adblock) {
        m_adblock = std::nullopt;
    }
    m_adblockInitFuture = std::async(std::launch::async, [this] {
        auto adb = newAdblock(AdblockFilterListsManager::filterListPath().toStdString());
        Q_EMIT adblockInitialized();
        return adb;
    });
#endif
}

#ifdef BUILD_ADBLOCK
std::vector<QString> AdblockUrlInterceptor::getCosmeticFilters(const QUrl &url,
                                                               const std::vector<QString> &classes,
                                                               const std::vector<QString> &ids) const
{
    if (!m_adblock.has_value()) {
        return {};
    }

    const auto rustClasses = toRustType(classes);
    const auto rustIds = toRustType(ids);
    return toQtType((*m_adblock)->getCosmeticFilters(url.toString().toStdString(),
                                                     {rustClasses.data(), rustClasses.size()},
                                                     {rustIds.data(), rustIds.size()}));
}

QString AdblockUrlInterceptor::getInjectedScript(const QUrl &url) const
{
    if (!m_adblock) {
        return {};
    }

    auto u = (*m_adblock)->getInjectedScript(url.toString().toStdString());
    return toQtType(u);
}
#endif

inline auto resourceTypeToString(const QWebEngineUrlRequestInfo::ResourceType type)
{
    // Strings from https://docs.rs/crate/adblock/0.3.3/source/src/request.rs
    using Type = QWebEngineUrlRequestInfo::ResourceType;
    switch (type) {
    case Type::ResourceTypeMainFrame:
        return "main_frame";
    case Type::ResourceTypeSubFrame:
        return "sub_frame";
    case Type::ResourceTypeStylesheet:
        return "stylesheet";
    case Type::ResourceTypeScript:
        return "script";
    case Type::ResourceTypeFontResource:
        return "font";
    case Type::ResourceTypeImage:
        return "image";
    case Type::ResourceTypeSubResource:
        return "object_subrequest"; // TODO CHECK
    case Type::ResourceTypeObject:
        return "object";
    case Type::ResourceTypeMedia:
        return "media";
    case Type::ResourceTypeFavicon:
        return "image"; // almost
    case Type::ResourceTypeXhr:
        return "xhr";
    case Type::ResourceTypePing:
        return "ping";
    case Type::ResourceTypeCspReport:
        return "csp_report";
    default:
        return "other";
    }
}

void AdblockUrlInterceptor::interceptRequest(QWebEngineUrlRequestInfo &info)
{
#ifdef BUILD_ADBLOCK
    if (!m_enabled) {
        return;
    }

    // Only wait for the adblock initialization if it isn't ready on first use
    if (!m_adblock) {
        qDebug() << "Adblock not yet initialized, blindly allowing request";
        return;
    }

    const std::string url = info.requestUrl().toString().toStdString();
    const std::string firstPartyUrl = info.firstPartyUrl().toString().toStdString();
    const AdblockResult result = (*m_adblock)->shouldBlock(url, firstPartyUrl, resourceTypeToString(info.resourceType()));

    const auto &redirect = result.redirect;
    if (!redirect.empty()) {
        info.redirect(QUrl(QString::fromStdString(std::string(redirect))));
    } else {
        info.block(result.matched);
    }
#else
    Q_UNUSED(info);
#endif
}

void q_cdebug_adblock(const char *message)
{
    qCDebug(AdblockCategory) << message;
}
