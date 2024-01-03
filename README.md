### What is this?

Linux convenience script for easily disabling or unreserving hardcoded Firefox keyboard shortcuts based on [Gautam Iyer's article](https://www.math.cmu.edu/~gautam/sj/blog/20220329-firefox-disable-ctrl-w.html).

#### **This script is provided as is, without any warranty or guarantee of any kind. Use at your own risk.**

### Why?

I wanted to make this since <Ctrl+w> annoyingly closed the tab when using Leetcode in Vim mode. The manual steps laid out in the above article were painful to go through each time the Firefox package was updated on my system.

The script is generalized though, so any command found in the [Commands](#commands) section or in [mainKeyset.xhtml](mainKeyset.xhtml) can be unreserved or disabled.

### Initial setup

```shell
apt-get install xmlstarlet # or equivalent for your system's package manager
git clone https://github.com/vxsl/firefox-keyboard-shortcut-manager
cd firefox-keyboard-shortcut-manager
chmod +x run.sh
```

### Example

For example, to

1. allow addons to use <Ctrl+w> (i.e. _unreserve_ `cmd_close`), and
2. prevent "about:processes" from opening on <shift+Esc> (i.e. _disable_ `View:AboutProcesses`):

```shell
./run.sh --remove View:AboutProcesses
./run.sh --unreserve cmd_close
# then restart Firefox process
```

### If something breaks:

However, for safety, it makes a backup copy of the untouched `omni.ja` file on its first run.

If the script somehow breaks your Firefox installation (sorry!), this should reset Firefox to its original state:

```shell
./run.sh --reset
# then restart Firefox process
```

If that doesn't work, uninstalling then reinstalling Firefox using your distro's package manager will resolve any further issues.

### Commands

At the time of writing, some commands that appear to be modifiable using this method are as follows. For reference, an excerpt of `browser.xhtml` titled [mainKeyset.xhtml](mainKeyset.xhtml) is included in this repository.

    - cmd_newNavigator
    - cmd_newNavigatorTabNoEvent
    - Browser:OpenLocation
    - Tools:Search
    - Tools:Downloads
    - Tools:Addons
    - Browser:OpenFile
    - Browser:SavePage
    - cmd_print
    - cmd_close
    - cmd_closeWindow
    - cmd_toggleMute
    - cmd_handleBackspace
    - cmd_handleShiftBackspace
    - Browser:Back
    - Browser:Forward
    - BrowserHome()
    - Browser:Reload
    - Browser:ReloadSkipCache
    - View:FullScreen
    - View:ReaderView
    - View:PictureInPicture
    - cmd_delete
    - cmd_find
    - cmd_findAgain
    - cmd_findPrevious
    - Browser:AddBookmarkAs
    - Browser:ShowAllBookmarks
    - Browser:Stop
    - Browser:ShowAllHistory
    - cmd_fullZoomReduce
    - cmd_fullZoomEnlarge
    - cmd_fullZoomReset
    - cmd_switchTextDirection
    - Tools:PrivateBrowsing
    - Browser:Screenshot
    - Tools:Sanitize
    - cmd_quitApplication
    - History:RestoreLastClosedTabOrWindowOrSession
    - History:UndoCloseWindow
    - wrCaptureCmd
    - wrToggleCaptureSequenceCmd
