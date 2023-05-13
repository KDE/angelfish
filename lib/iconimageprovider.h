// SPDX-FileCopyrightText: 2020 Jonah Brüchert <jbb@kaidan.im>
// SPDX-FileCopyrightText: 2020 Rinigus <rinigus.git@gmail.com>
//
// SPDX-License-Identifier: GPL-2.0-or-later

#ifndef ICONIMAGEPROVIDER_H
#define ICONIMAGEPROVIDER_H

#include <QQuickImageProvider>
#include <QQuickAsyncImageProvider>

#include <QCoro/QCoroTask>
#include <QCoro/QCoroImageProvider>

class IconImageProvider : public QCoro::ImageProvider
{
public:
    IconImageProvider();

    QCoro::Task<QImage> asyncRequestImage(const QString &id, const QSize &) override;

    static QString providerId();
};

// store image into the database if it is missing. Return new
// image:// uri that should be used to fetch the icon
QCoro::Task<QString> storeIcon(QQmlEngine *engine, const QString &iconSource);

#endif // ICONIMAGEPROVIDER_H
