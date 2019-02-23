/***************************************************************************
 *                                                                         *
 *   Copyright 2019 Simon Schmeisser <s.schmeisser@gmx.net>                *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA .        *
 *                                                                         *
 ***************************************************************************/


#include "urlfilterproxymodel.h"

#include "urlmodel.h"

using namespace AngelFish;

UrlFilterProxyModel::UrlFilterProxyModel(QObject *parent) : QSortFilterProxyModel(parent)
{

}

bool UrlFilterProxyModel::filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const
{
    QModelIndex index = sourceModel()->index(sourceRow, 0, sourceParent);

    return (sourceModel()->data(index, UrlModel::url).toString().contains(filterRegExp())
            || sourceModel()->data(index, UrlModel::title).toString().contains(filterRegExp()));
}