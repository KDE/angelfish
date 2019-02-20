/***************************************************************************
 *                                                                         *
 *   Copyright 2019 Simon Schmeisser <s.schmeisser@gmx.net>                *
 *   Copyright 2019 Jonah Brüchert <jbb@kaidan.im>                         *
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

import QtQuick 2.7

ListView {
    id: completion

    property string searchText

    anchors {
        bottom: navigation.top
        horizontalCenter: navigation.horizontalCenter
    }

    width: 0.9 * navigation.width
    height: 0.5 * parent.height
    z: 10

    verticalLayoutDirection: ListView.BottomToTop
    clip: true

    delegate: UrlDelegate {
        showRemove: false
        onClicked: tabs.forceActiveFocus()
        highlightText: completion.searchText
    }
}