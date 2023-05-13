-- SPDX-FileCopyrightText: 2022 Jonah Brüchert <jbb@kaidan.im>
--
-- SPDX-License-Identifier: GPL-2.0-or-later

CREATE TABLE IF NOT EXISTS bookmarks (url TEXT UNIQUE, title TEXT, icon TEXT, lastVisited INT);
CREATE TABLE IF NOT EXISTS history (url TEXT UNIQUE, title TEXT, icon TEXT, lastVisited INT);
CREATE TABLE IF NOT EXISTS icons (url TEXT UNIQUE, icon BLOB);
CREATE UNIQUE INDEX IF NOT EXISTS idx_bookmarks_url ON bookmarks(url);
CREATE UNIQUE INDEX IF NOT EXISTS idx_history_url ON history(url);
CREATE UNIQUE INDEX IF NOT EXISTS idx_icons_url ON icons(url);
