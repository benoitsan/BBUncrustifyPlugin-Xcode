# BBUncrustifyPlugin-Xcode

Xcode plugin to format code using [Uncrustify](http://uncrustify.sourceforge.net) or [ClangFormat](http://clang.llvm.org/docs/ClangFormat.html). 

![menu](https://github.com/benoitsan/BBUncrustifyPlugin-Xcode/blob/master/images/menu.png)

![preferences](https://github.com/benoitsan/BBUncrustifyPlugin-Xcode/blob/master/images/preferences.png)

## Requirements

Xcode 6.0+ on OS X 10.10+.

PS: [This fork](https://github.com/1951FDG/BBUncrustifyPlugin-Xcode) works with Xcode 3.

## Installation

#### Compiled Version

* The easiest way to install the plugin is to [download the lastest release](https://github.com/benoitsan/BBUncrustifyPlugin-Xcode/releases/latest).
* Unzip and copy `UncrustifyPlugin.xcplugin` to `~/Library/Application Support/Developer/Shared/Xcode/Plug-ins`.
* Relaunch Xcode after the copy.

#### Script Version

Run on Terminal:

```shell

curl -SL https://raw.githubusercontent.com/benoitsan/BBUncrustifyPlugin-Xcode/master/install.sh | sh
```

#### Build from Source

* Build the Xcode project. The plug-in will automatically be installed in `~/Library/Application Support/Developer/Shared/Xcode/Plug-ins`. 

* Relaunch Xcode.

To uninstall, just remove the plugin from `~/Library/Application Support/Developer/Shared/Xcode/Plug-ins` and restart Xcode.

## How does it work?

All the commands are in the menu `Edit > Format Code`.

* Use the menu `Format Selected Files` to format the selected items in the project navigator.

* Use the menu `Format Active File` to format the source file actually opened in the editor. 

* Use the menu `Format Selected Lines` to format the selected source code (multiple selection is supported). The selection is automatically extended in full lines. If the selection is empty, it uses the line under the cursor.

* Use the menu `Edit Configuration` to edit the formatter configuration in an external editor.

* Use the menu `BBUncrustifyPlugin Preferences` to change the plugin preferences.

## Tips

When the code is reformated, the modifications are recorded in the undo. So undo reverts the modifications.

The Preferences window contains detailed informations to customize the formatter settings.

You can create keyboard shortcuts for the menu items in the [Keyboard Preferences](http://support.apple.com/kb/ph3957) of OS X System Preferences.

Use the menu `Edit > Format Code > View Log` to identify issues when formatting.

The plugin includes binaries for ClangFormat and Uncrustify. To use your own version, install the binary to: `/usr/local/bin/clang-format` or `/usr/bin/clang-format` for ClangFormat, `/usr/local/bin/uncrustify` or `/usr/bin/uncrustify` for Uncrustify.

When formatting a code selection, keep in mind that formatting selected lines can fail depending of the selected scope. 

- Uncrustify assumes the first selected line is indented correctly. 

- ClangFormat takes in account the scope around the selection.

## Style configuration

To create the initial configuration file, you can use the button "Create Configuration File" in the preferences window.

The configuration file must be located in the current directory or any parent directories of the source file. The search is started from the current directory. The plugin looks for the following file name patterns, in the order priority shown:

- For ClangFormat: 

	1. `_clang-format`
	2. `.clang-format`

- For Uncrustify: 
	1. `uncrustify.cfg`
	2. `_uncrustify.cfg`
	3. `.uncrustify.cfg`
	4. `.uncrustifyconfig`
	5. In addition: your Home Folder and `~/.uncrustify/uncrustify.cfg`
	

So lets say you have a project with subproject1 (team1) and subproject2 (team2), you can use a structure like that:

```
root project folder
	| subproject1
		| config_file -> team1

	| subproject2
		| config_file -> team2
```

#### ClangFormat: Predefined style or Custom style file

When using ClangFormat, you can use a predefined non editable style or a custom file. **The plugin will use the style defined in the preferences window in the "Clang Style" section**: LLVM, Google, Chromium, Mozilla, WebKit, or, Custom File.

## Post Formatting options

In the plugin preferences, you can activate some post formatting operations:

#### Perform Xcode syntax-aware indenting

When enabled, the plugin re-indents the code using Xcode. By default, this feature is not selected because it overwrites the indentation performed by the formatter.

#### Indent whitespace-only lines to code level

Both ClangFormat and Uncrustify always trim whitespace-only lines. When enabled, the plugin re-indents empty lines to the code level. This option is disabled if "Including Whitespace-only lines" is enabled in Xcode preferences (Xcode Preferences > Text Editing Tab > Editing Panel > While Editing).


## Some Objective-C Style Guides

Using Uncrustify:

- [apps-ios-wikipedia](https://github.com/wikimedia/wikipedia-ios)
- [CocoaLumberjack](https://github.com/CocoaLumberjack/CocoaLumberjack)
- [inbox-ios](https://github.com/nylas/inbox-ios)
- [wonderful-objective-c-style-guide](https://github.com/markeissler/wonderful-objective-c-style-guide)

Some Style Guides:

- [GitHub](https://github.com/github/objective-c-style-guide)
- [raywenderlich](https://github.com/raywenderlich/objective-c-style-guide)
- [Realm](https://github.com/realm/realm-cocoa/wiki/Objective-C-Style-Guide)
- [Spotify](https://github.com/spotify/ios-style)
- [The New York Times](https://github.com/NYTimes/objective-c-style-guide)

## Creator

[Benoît Bourdon](https://github.com/benoitsan) ([@benoitsan](https://twitter.com/benoitsan)). Thanks to the [Contributors](https://github.com/benoitsan/BBUncrustifyPlugin-Xcode/graphs/contributors)!

Additional contributors actually not listed [here](https://github.com/benoitsan/BBUncrustifyPlugin-Xcode/graphs/contributors): [Dominik Pich](https://github.com/Daij-Djan).

## License

BBUncrustifyPlugin is available under the MIT license. See the LICENSE file for more info.






