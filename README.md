Convenience script based on [Gautam Iyer's article about disabling or unreserving Firefox keyboard shortcuts](https://www.math.cmu.edu/~gautam/sj/blog/20220329-firefox-disable-ctrl-w.html).

### Initial setup:

```shell
git clone https://github.com/vxsl/firefox-keyboard-shortcut-manager
cd firefox-keyboard-shortcut-manager
chmod +x run.sh
```

### Example

For example, to allow addons to use `ctrl+w` (i.e. _unreserve_ `ctrl+w`) and prevent `about:processes` from opening on `shift+Esc` (i.e. _disable_ `View:AboutProcesses`):

```shell
./run.sh --remove View:AboutProcesses
./run.sh --unreserve cmd_close
```

### If something breaks:

```shell
./run.sh --reset
```

### Commands

At the time of writing, some commands that appear to be modifiable using this method are as follows. An excerpt of `browser.xhtml` titled `mainKeyset.xhtml` is included in this repository for reference.

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
