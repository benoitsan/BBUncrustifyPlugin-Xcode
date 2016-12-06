
xcodebuild:=xcodebuild -scheme "BBUncrustifyPlugin-ARC" -configuration

debug:
	$(xcodebuild) Debug

release:
	$(xcodebuild) Release

clean: clean-release clean-debug

clean-debug:
	$(xcodebuild) Debug clean

clean-release:
	$(xcodebuild) Release clean

uninstall:
	rm -rf "$(HOME)/Library/Application Support/Developer/Shared/Xcode/Plug-ins/UncrustifyPlugin.xcplugin"

