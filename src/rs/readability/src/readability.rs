// SPDX-FileCopyrightText: 2021 Jonah Brüchert <jbb@kaidan.im>
//
// SPDX-License-Identifier: GPL-2.0-or-later

use readability::extractor;
use url::Url;

fn extract_reader_view(html: &str, url: &str) -> ffi::ReadabilityResult {
    let mut contents = html.as_bytes();
    if let Ok(url) = Url::parse(url) {
        if let Ok(output) = extractor::extract(&mut contents, &url) {
            return ffi::ReadabilityResult {
                success: true,
                data: ffi::ReadabilityOutput {
                    title: output.title,
                    content: output.content
                }
            }
        }
    }

    ffi::ReadabilityResult {
        success: false,
        data: ffi::ReadabilityOutput {
            title: String::new(),
            content: String::new()
        }
    }
}

#[cxx::bridge]
mod ffi {
    struct ReadabilityOutput {
        title: String,
        content: String
    }

    struct ReadabilityResult {
        success: bool,
        data: ReadabilityOutput
    }

    extern "Rust" {
        fn extract_reader_view(html: &str, url: &str) -> ReadabilityResult;
    }
}
