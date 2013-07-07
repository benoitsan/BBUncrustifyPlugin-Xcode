#BBUncrustifyPlugin-Xcode

Xcode plugin to [uncrustify](http://uncrustify.sourceforge.net) code in Xcode. 

## Requirements

Tested with Xcode 4.6+ (also works in Xcode 5) on OS X 10.7 or higher.

## Installation

* Build the Xcode project. The plug-in will automatically be installed in `~/Library/Application Support/Developer/Shared/Xcode/Plug-ins`. 

* Relaunch Xcode.

To uninstall, just remove the plugin from `~/Library/Application Support/Developer/Shared/Xcode/Plug-ins` and restart Xcode.

## How does it work?

* Use the menu `Edit > Uncrustify Selected Files` to uncrustify the selected items in the project navigator.

* Use the menu `Edit > Uncrustify Active File` to uncrustify the source file actually opened in the editor. 

* Use the menu `Edit > Uncrustify Selected Lines` to uncrustify the selected source code (multiple selection is supported). The selection is automatically extended in full lines. If the selection is empty, it uses the line under the cursor.

PS: Modifications are recorded in the undo. So undo reverts the modifications.

You can create keyboard shortcuts for the menu items in the [Keyboard Preferences](http://support.apple.com/kb/ph3957) of OS X System Preferences.


## How to customize the uncrustify configuration?

By default, the plugin uses the configuration file `uncrustify.cfg` found in the bundle.

#### Per user configuration
To customize the configuration, copy the file `uncrustify.cfg` or your own to:

1. `~/.uncrustifyconfig` or
2. `~/uncrustify.cfg` or
3. `~/.uncrustify/uncrustify.cfg`

#### Per project configuration
A configuration file named `uncrustify.cfg` or `.uncrustifyconfig` can be defined for a project, a workspace or a Xcode container folder (folder with the yellow icon in the Xcode files navigator).

The lookup of the configuration file is made in this order:

1. Closest Xcode container folder ancestor.
2. Closest Xcode project file ('.xcodeproj') folder ancestor.
3. Closest Xcode workspace file ('.xcworkspace') folder ancestor.

Example:

```
|-- workspace.xcworkspace
|-- uncrustify.cfg
|-- project folder
|---- project.xcodeproj
|---- Third Party Library Folder
|------ uncrustify.cfg
|-- An other project folder
|---- An other project.xcodeproj
|---- uncrustify.cfg
````

### Using UncrustifyX

A more easy way to edit the configuration is to use the Mac appplication [UncrustifyX](https://github.com/ryanmaxwell/UncrustifyX). 

Once UncrustifyX is installed, the plugin will add a menu item `Open with UncrustifyX` to open the actual source code and configuration in UncrustifyX.

## Xcode Normalization

After uncrustification, the plugin:

* performs a syntax-aware indenting if checked in the Xcode preferences (Preferences > Text Editing > Indentation > Syntax-aware indenting).

* Trims trailing whitespaces and white-only lines if checked in the Xcode preferences (Preferences > Text Editing > Editing).

You can disable this feature by setting the default key `uncrustify_plugin_codeFormattingScheme`to `1` (`0` or not defined means enabled).

    defaults write com.apple.dt.Xcode uncrustify_plugin_codeFormattingScheme -int 1


## Creator

[Benoît Bourdon](https://github.com/benoitsan) ([@benoitsan](https://twitter.com/benoitsan)).

## License

BBUncrustifyPlugin is available under the MIT license. See the LICENSE file for more info.






