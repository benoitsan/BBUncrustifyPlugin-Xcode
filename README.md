#BBUncrustifyPlugin-Xcode

Xcode plugin to [uncrustify](http://uncrustify.sourceforge.net) the source code opened in the editor. 

## Requirements

Tested with Xcode 4.6+ on OS X 10.7 or higher.

## Installation

* Build the Xcode project. The plug-in will automatically be installed in `~/Library/Application Support/Developer/Shared/Xcode/Plug-ins`. 

* Relaunch Xcode.

To uninstall, just remove the plugin from `~/Library/Application Support/Developer/Shared/Xcode/Plug-ins` and restart Xcode.

## How does it work?

* Use the menu `Edit > Uncrustify` to uncrustify the source code actually opened in the editor. 

* Use the menu `Edit > Uncrustify Selected Files` to uncrustify the selected items in the project navigator.

PS: Modifications are recorded in the undo. So undo reverts the modifications.


## How to customize the uncrustify configuration?

I recommend to use [UncrustifyX](https://github.com/ryanmaxwell/UncrustifyX). Overwite the file `uncrustify.cfg` with your own configuration and rebuild the plugin (and restart Xcode).

## Creator

[Benoît Bourdon](https://github.com/benoitsan) ([@benoitsan](https://twitter.com/benoitsan)).

## License

BBUncrustifyPlugin is available under the MIT license. See the LICENSE file for more info.






