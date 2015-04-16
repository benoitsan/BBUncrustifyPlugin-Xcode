#BBUncrustifyPlugin-Xcode

Xcode plugin to format code using [Uncrustify](http://uncrustify.sourceforge.net) or [ClangFormat](http://clang.llvm.org/docs/ClangFormat.html). 

![menu](https://github.com/benoitsan/BBUncrustifyPlugin-Xcode/blob/master/images/menu.png)

![preferences](https://github.com/benoitsan/BBUncrustifyPlugin-Xcode/blob/master/images/preferences.png)

## Requirements

Xcode 6.0+ on OS X 10.10+.

PS: [This fork](https://github.com/1951FDG/BBUncrustifyPlugin-Xcode) works with Xcode 3.

## Installation

#### Compiled Version

* The easiest way to install the plugin is to [download the last available release](https://github.com/benoitsan/BBUncrustifyPlugin-Xcode/releases) (Click on the **green button** corresponding to the last version).
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

## Notes

When the code is reformated, the modifications are recorded in the undo. So undo reverts the modifications.

The Preferences window contains detailed informations to customize the formatter settings.

You can create keyboard shortcuts for the menu items in the [Keyboard Preferences](http://support.apple.com/kb/ph3957) of OS X System Preferences.


## Creator

[Benoît Bourdon](https://github.com/benoitsan) ([@benoitsan](https://twitter.com/benoitsan)). Thanks to the [Contributors](https://github.com/benoitsan/BBUncrustifyPlugin-Xcode/graphs/contributors)!

Additional contributors actually not listed [here](https://github.com/benoitsan/BBUncrustifyPlugin-Xcode/graphs/contributors): [Dominik Pich](https://github.com/Daij-Djan).

## License

BBUncrustifyPlugin is available under the MIT license. See the LICENSE file for more info.






