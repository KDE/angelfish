// SPDX-FileCopyrightText: 2021 Jonah Brüchert <jbb@kaidan.im>
//
// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

#include <QObject>

class ReaderView {
    Q_GADGET

    Q_PROPERTY(QString title MEMBER m_title CONSTANT)
    Q_PROPERTY(QString content MEMBER m_content CONSTANT)

public:
    ReaderView() = default;
    ReaderView(QString title, QString content);

private:
    QString m_title;
    QString m_content;
};

class ReaderViewExtractor : public QObject
{
    Q_OBJECT

public:
    explicit ReaderViewExtractor(QObject *parent = nullptr);

    Q_INVOKABLE ReaderView extractContent(const QString &originalHtml, const QString &sourceUrl);
};

