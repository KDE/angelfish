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

        fn new_adblock(list_dir: &str) -> Box<Adblock>;
        fn should_block(
            self: &Adblock,
            url: &str,
            source_url: &str,
            request_type: &str,
        ) -> AdblockResult;
        fn extract_reader_view(html: &str, url: &str) -> ReadabilityResult;
    }
}
