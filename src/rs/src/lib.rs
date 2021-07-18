// SPDX-FileCopyrightText: 2020 Jonah Brüchert <jbb@kaidan.im>
//
// SPDX-License-Identifier: GPL-2.0-or-later

mod adblock;
mod readability;
mod logging;

use crate::adblock::*;
use crate::readability::*;

#[cxx::bridge]
mod ffi {
    #[derive(Default)]
    struct AdblockResult {
        matched: bool,
        important: bool,
        redirect: String,
    }

    struct ReadabilityOutput {
        title: String,
        content: String
    }

    struct ReadabilityResult {
        success: bool,
        data: ReadabilityOutput
    }

    extern "Rust" {
        type Adblock;

        #[cxx_name="newAdblock"]
        fn new_adblock(list_dir: &str) -> Box<Adblock>;
        #[cxx_name="loadAdblock"]
        fn load_adblock(path: &str) -> Box<Adblock>;

        #[cxx_name="isValid"]
        fn is_valid(self: &Adblock) -> bool;
        #[cxx_name="needsSave"]
        fn needs_save(self: &Adblock) -> bool;
        #[cxx_name="shouldBlock"]
        fn should_block(
            self: &Adblock,
            url: &str,
            source_url: &str,
            request_type: &str,
        ) -> AdblockResult;
        fn save(self: &Adblock, path: &str) -> bool;
        fn extract_reader_view(html: &str, url: &str) -> ReadabilityResult;
    }
}
