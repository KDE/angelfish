// SPDX-FileCopyrightText: 2020 Jonah Brüchert <jbb@kaidan.im>
//
// SPDX-License-Identifier: GPL-2.0-or-later

use std::fs;
use std::io::Write;

use adblock::{
    lists::{FilterSet, ParseOptions},
    request::Request,
    Engine,
};

use crate::adblock_debug;

struct Adblock {
    blocker: Option<Engine>,
    needs_save: bool,
}

/// creates a new adblock object, and returns a pointer to it.
/// If the passed list_dir is invalid, the Adblock will not contain an engine.
fn new_adblock(list_dir: &str) -> Box<Adblock> {
    adblock_debug!("## Creating new adblock instance");
    // Create domain resolver
    let mut filter_set = FilterSet::new(true);

    // iterate directory
    if let Ok(entries) = fs::read_dir(list_dir) {
        for entry in entries.into_iter().flatten() {
            if let Ok(ft) = entry.file_type() {
                if ft.is_file() {
                    adblock_debug!("Loading filter {:?}", entry);
                    match fs::read_to_string(&entry.path()) {
                        Ok(contents) => {
                            filter_set.add_filter_list(&contents, ParseOptions::default());
                        }
                        Err(e) => {
                            adblock_debug!("Loading filter {:?} failed: {}", entry.path(), e);
                        }
                    }
                }
            }
        }

        let blocker = Engine::from_filter_set(filter_set, true);
        return Box::new(Adblock {
            blocker: Some(blocker),
            needs_save: true,
        });
    }
    Box::new(Adblock {
        blocker: None,
        needs_save: false,
    })
}

fn load_adblock(path: &str) -> Box<Adblock> {
    let engine = match fs::read(path) {
        Ok(data) => {
            let mut engine = Engine::default();
            match engine.deserialize(&data) {
                Ok(()) => Some(engine),
                Err(e) => {
                    adblock_debug!("Failed to deserialize saved adblock data: {:?}", e);
                    None
                }
            }
        }
        Err(e) => {
            adblock_debug!("Failed to read adblock state from disk: {:?}", e);
            None
        }
    };

    Box::from(Adblock {
        blocker: engine,
        needs_save: false,
    })
}

impl Adblock {
    /// returns a boxed AdblockResult object with information on whether
    /// the request should be blocked or redirected.
    fn should_block(&self, url: &str, source_url: &str, request_type: &str) -> ffi::AdblockResult {
        if let Some(engine) = &self.blocker {
            if let Ok(request) = Request::new(url, source_url, request_type) {
                let blocker_result = engine.check_network_request(&request);
                adblock_debug!("Blocker input: {}, {}, {}", url, source_url, request_type);
                adblock_debug!("Blocker result: {:?}", blocker_result);

                return ffi::AdblockResult {
                    matched: blocker_result.matched,
                    important: blocker_result.important,
                    redirect: blocker_result.redirect.unwrap_or_default(),
                    rewritten_url: blocker_result.rewritten_url.unwrap_or_default(),
                };
            }
        } else {
            adblock_debug!("Adblock engine doesn't exist! Probably it failed to load or restore");
        }

        ffi::AdblockResult::default()
    }

    fn get_injected_script(&self, url: &str) -> String {
        self.blocker
            .as_ref()
            .map(|engine| engine.url_cosmetic_resources(url).injected_script)
            .unwrap_or_default()
    }

    fn get_cosmetic_filters(&self, url: &str, classes: &[String], ids: &[String]) -> Vec<String> {
        self.blocker
            .as_ref()
            .map(|engine| {
                let cosmetic_resources = engine.url_cosmetic_resources(url);
                engine.hidden_class_id_selectors(classes, ids, &cosmetic_resources.exceptions)
            })
            .unwrap_or_default()
    }

    fn save(&self, path: &str) -> bool {
        match fs::File::create(path) {
            Ok(mut file) => match &self.blocker {
                Some(engine) => {
                    let data = engine.serialize();
                    match file.write_all(&data) {
                        Ok(()) => {
                            adblock_debug!("Successfully saved adblock cache");
                            return true;
                        }
                        Err(e) => adblock_debug!("Failed to write adblock cache: {:?}", e),
                    }
                }
                None => adblock_debug!("Can't save adblock cache, since the engine is not loaded."),
            },
            Err(e) => adblock_debug!("Can't save adblock cache, failed to write to file: {:?}", e),
        }

        false
    }

    fn is_valid(&self) -> bool {
        self.blocker.is_some()
    }

    fn needs_save(&self) -> bool {
        self.needs_save
    }
}

#[cxx::bridge]
mod ffi {
    #[derive(Default)]
    struct AdblockResult {
        matched: bool,
        important: bool,
        redirect: String,
        #[cxx_name = "rewrittenUrl"]
        rewritten_url: String,
    }

    extern "Rust" {
        type Adblock;

        #[cxx_name = "newAdblock"]
        fn new_adblock(list_dir: &str) -> Box<Adblock>;
        #[cxx_name = "loadAdblock"]
        fn load_adblock(path: &str) -> Box<Adblock>;

        #[cxx_name = "isValid"]
        fn is_valid(self: &Adblock) -> bool;
        #[cxx_name = "needsSave"]
        fn needs_save(self: &Adblock) -> bool;
        #[cxx_name = "shouldBlock"]
        fn should_block(
            self: &Adblock,
            url: &str,
            source_url: &str,
            request_type: &str,
        ) -> AdblockResult;
        #[cxx_name = "getCosmeticFilters"]
        fn get_cosmetic_filters(
            self: &Adblock,
            url: &str,
            classes: &[String],
            ids: &[String],
        ) -> Vec<String>;
        #[cxx_name = "getInjectedScript"]
        fn get_injected_script(self: &Adblock, url: &str) -> String;
        fn save(self: &Adblock, path: &str) -> bool;
    }
}
