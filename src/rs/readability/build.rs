// SPDX-FileCopyrightText: 2021 Jonah Brüchert <jbb@kaidan.im>
//
// SPDX-License-Identifier: GPL-2.0-or-later

extern crate cxx_build;

fn main() {
    cxx_build::bridge("src/readability.rs").compile("angelfish-readability")
}
