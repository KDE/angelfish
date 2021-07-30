# Angelfish

This is a webbrowser designed to

- be used on small mobile devices,
- integrate well in Plasma workspaces

<a href='https://flathub.org/apps/details/org.kde.angelfish'><img width='190px' alt='Download on Flathub' src='https://flathub.org/assets/badges/flathub-badge-i-en.png'/></a>

## Reporting bugs

Bugtracker: https://invent.kde.org/plasma-mobile/angelfish/-/issues

Please choose the "default_issue" description template when opening issues.

## Preliminary roadmap:
- [x] browser navigation: back + forward + reload
- [x] browser status
- [x] Implement URL bar
- [x] Error handler in UI
- [x] history store, model and UI
- [x] bookmarks store, model and UI
  - [x] add / remove
- [x] in-window navigation: tabs in bottom bar
- [ ] SSL error handler
- [x] Touch actions (pinch?) (done in QtWebEngine)
- [x] user-agent to request mobile site
- [x] open and close new tabs
- [x] History based completion
- [x] Right click / long press menu
- [x] purpose integration (for kdeconnect)
- [x] adblock

## Development

### Building

If you are using a rolling release distribution, you can install the dependencies using your package manager.
Otherwise, use kdesrc-build to build angelfish and its dependencies. Setting up kdesrc-build is documented in the [Community Wiki](https://community.kde.org/Get_Involved/development#Set_up_kdesrc-build)

Currently the dependencies are:
 * Qt (including QtCore, QtQuick, QtTest, QtGui, QtSvg, QtQuickControls2, QtSql and QtFeedback)
 * The KDE Frameworks (including Kirigami2, Purpose, I18n, Config, CoreAddons, DBusAddons, WindowSystem, Notifications)
 * Rust (including cargo and rustc) (optional)

Please check the community wiki for how to build projects with kdesrc-build.
If you went for using your distribution's package manager, then you can build (and install) Angelfish like this:
```
mkdir build
cd build
cmake .. # add -DCMAKE_BUILD_TYPE=Release to compile for release
make
sudo make install # optional, if you want to install Angelfish into your system
```

### Adblock
To debug requests sent by the browser, for example for debugging the ad blocker, it can be useful to have a look at the development tools.
For using them, the browser needs to be started with a special environment variable set: `QTWEBENGINE_REMOTE_DEBUGGING=4321 angelfish`.
The variable contains the port on which the development tools will be available. You can now point another browser to http://localhost:4321.

To enable adblock logging, add the following to `~/.config/QtProject/qtlogging.ini`:
```
[Rules]
org.kde.angelfish.adblock.debug=true
```

### Flatpak
If one of the Cargo.toml files is updated, the flatpak sources need to be regenerated. That can be done using the `./flatpak/regenerate-sources.sh` script.
