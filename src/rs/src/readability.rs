// SPDX-FileCopyrightText: 2021 Jonah Brüchert <jbb@kaidan.im>
//
// SPDX-License-Identifier: GPL-2.0-or-later

use readability::extractor;
use url::Url;

pub fn extract_reader_view(html: &str, url: &str) -> crate::ffi::ReadabilityResult {
    let mut contents = html.as_bytes();
    if let Ok(url) = Url::parse(url) {
        if let Ok(output) = extractor::extract(&mut contents, &url) {
            return crate::ffi::ReadabilityResult {
                success: true,
                data: crate::ffi::ReadabilityOutput {
                    title: output.title,
                    content: output.content
                }
            }
        }
    }

    crate::ffi::ReadabilityResult {
        success: false,
        data: crate::ffi::ReadabilityOutput {
            title: String::new(),
            content: String::new()
        }
    }
}
