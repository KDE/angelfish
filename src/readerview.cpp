// SPDX-FileCopyrightText: 2021 Jonah Brüchert <jbb@kaidan.im>
//
// SPDX-License-Identifier: GPL-2.0-or-later

#include "readerview.h"

#include <lib.rs.h>

#include <utility>

#include <QDebug>

Q_DECLARE_METATYPE(ReaderView)

ReaderView::ReaderView(QString title, QString content)
    : m_title(std::move(title))
    , m_content(std::move(content))
{
}

ReaderViewExtractor::ReaderViewExtractor(QObject *parent)
    : QObject(parent)
{
    qRegisterMetaType<ReaderView>();
}

ReaderView ReaderViewExtractor::extractContent(const QString &originalHtml, const QString &sourceUrl)
{
    auto result = extract_reader_view(originalHtml.toStdString(), sourceUrl.toStdString());

    // TODO verify that the garbage collector takes care of this
    return ReaderView(
                QString::fromStdString(std::string(result.data.title)),
                QString::fromStdString(std::string(result.data.content)));
}
