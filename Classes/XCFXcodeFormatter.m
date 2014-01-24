//
//  Created by Benoît on 11/01/14.
//  Copyright (c) 2014 Pragmatic Code. All rights reserved.
//

#import "XCFXcodeFormatter.h"
#import "XCFXcodePrivate.h"
#import "XCFClangFormatter.h"
#import "XCFUncrustifyFormatter.h"
#import "XCFFormatterUtilities.h"
#import "XCFDefaults.h"

static NSString * const XCFUncrustifyXIdentifier = @"nz.co.xwell.UncrustifyX";

NSString * XCFStringByTrimmingTrailingCharactersFromString(NSString *string, NSCharacterSet *characterSet) {
    NSRange rangeOfLastWantedCharacter = [string rangeOfCharacterFromSet:[characterSet invertedSet] options:NSBackwardsSearch];
    if (rangeOfLastWantedCharacter.location == NSNotFound) return @"";
    return [string substringToIndex:rangeOfLastWantedCharacter.location + 1];
}

@implementation XCFXcodeFormatter {}

#pragma mark - Formatter

+ (BOOL)canFormatSelectedFiles {
    NSArray *selectedFiles = [XCFXcodeFormatter selectedSourceCodeFileNavigableItems];
    return (selectedFiles.count > 0);
}

+ (void)formatSelectedFilesWithEnumerationBlock:(void(^)(NSURL *url, NSError *error, BOOL *stop))enumerationBlock {
    NSArray *fileNavigableItems = [XCFXcodeFormatter selectedSourceCodeFileNavigableItems];
    IDEWorkspace *currentWorkspace = [XCFXcodeFormatter currentWorkspaceDocument].workspace;
    for (IDEFileNavigableItem *fileNavigableItem in fileNavigableItems) {
        NSError *error = nil;
        NSDocument *document = [IDEDocumentController retainedEditorDocumentForNavigableItem:fileNavigableItem error:nil];
        if ([document isKindOfClass:NSClassFromString(@"IDESourceCodeDocument")]) {
            IDESourceCodeDocument *sourceCodeDocument = (IDESourceCodeDocument *)document;
            [XCFXcodeFormatter formatCodeOfDocument:sourceCodeDocument inWorkspace:currentWorkspace error:&error];
            //[document saveDocument:nil];
        }
        [IDEDocumentController releaseEditorDocument:document];
        
        BOOL __block stop = NO;
        if (enumerationBlock) {
            enumerationBlock(document.fileURL, error, &stop);
        }
        if (stop) {
            break;
        }
    }
}

+ (void)formatSelectedFilesWithError:(NSError **)outError {
    NSArray *fileNavigableItems = [XCFXcodeFormatter selectedSourceCodeFileNavigableItems];
    IDEWorkspace *currentWorkspace = [XCFXcodeFormatter currentWorkspaceDocument].workspace;
    for (IDEFileNavigableItem *fileNavigableItem in fileNavigableItems) {
        NSError *error = nil;
        NSDocument *document = [IDEDocumentController retainedEditorDocumentForNavigableItem:fileNavigableItem error:nil];
        if ([document isKindOfClass:NSClassFromString(@"IDESourceCodeDocument")]) {
            IDESourceCodeDocument *sourceCodeDocument = (IDESourceCodeDocument *)document;
            [XCFXcodeFormatter formatCodeOfDocument:sourceCodeDocument inWorkspace:currentWorkspace error:&error];
            //[document saveDocument:nil];
        }
        [IDEDocumentController releaseEditorDocument:document];
        
        if (error) {
            if (outError) {
                *outError = error;
            }
            break;
        }
    }
}

+ (BOOL)canFormatActiveFile {
    IDESourceCodeDocument *document = [XCFXcodeFormatter currentSourceCodeDocument];
    return (document != nil);
}

+ (void)formatActiveFileWithError:(NSError **)outError {
        
    IDESourceCodeDocument *document = [XCFXcodeFormatter currentSourceCodeDocument];
    if (!document) return;
    
    [[self class] formatDocument:document withError:outError];
}

+ (BOOL)canFormatSelectedLines {
    BOOL validated = NO;
    IDESourceCodeDocument *document = [XCFXcodeFormatter currentSourceCodeDocument];
    NSTextView *textView = [XCFXcodeFormatter currentSourceCodeTextView];
    if (document && textView) {
        NSArray *selectedRanges = [textView selectedRanges];
        validated = (selectedRanges.count > 0);
    }
    return validated;
}

+ (void)formatSelectedLinesWithError:(NSError **)outError {
    IDESourceCodeDocument *document = [XCFXcodeFormatter currentSourceCodeDocument];
    NSTextView *textView = [XCFXcodeFormatter currentSourceCodeTextView];
    if (!document || !textView) return;
    IDEWorkspace *currentWorkspace = [XCFXcodeFormatter currentWorkspaceDocument].workspace;
    NSArray *selectedRanges = [textView selectedRanges];
    [XCFXcodeFormatter formatCodeAtRanges:selectedRanges document:document inWorkspace:currentWorkspace error:outError];
}

+ (void)formatDocument:(IDESourceCodeDocument *)document withError:(NSError **)outError {

    NSTextView *textView = [XCFXcodeFormatter currentSourceCodeTextView];
    
    DVTSourceTextStorage *textStorage = [document textStorage];
    
    // We try to restore the original cursor position after the uncrustification. We compute a percentage value
    // expressing the actual selected line compared to the total number of lines of the document. After the uncrustification,
    // we restore the position taking into account the modified number of lines of the document.
    
    NSRange originalCharacterRange = [textView selectedRange];
    NSRange originalLineRange = [textStorage lineRangeForCharacterRange:originalCharacterRange];
    NSRange originalDocumentLineRange = [textStorage lineRangeForCharacterRange:NSMakeRange(0, textStorage.string.length)];
    
    CGFloat verticalRelativePosition = (CGFloat)originalLineRange.location / (CGFloat)originalDocumentLineRange.length;
    
    IDEWorkspace *currentWorkspace = [XCFXcodeFormatter currentWorkspaceDocument].workspace;
    
    [XCFXcodeFormatter formatCodeOfDocument:document inWorkspace:currentWorkspace error:outError];
    
    NSRange newDocumentLineRange = [textStorage lineRangeForCharacterRange:NSMakeRange(0, textStorage.string.length)];
    NSUInteger restoredLine = roundf(verticalRelativePosition * (CGFloat)newDocumentLineRange.length);
    
    NSRange newCharacterRange = NSMakeRange(0, 0);
    
    newCharacterRange = [textStorage characterRangeForLineRange:NSMakeRange(restoredLine, 0)];
    
    // If the selected line didn't change, we try to restore the initial cursor position.
    
    if (originalLineRange.location == restoredLine && NSMaxRange(originalCharacterRange) < textStorage.string.length) {
        newCharacterRange = originalCharacterRange;
    }
    
    if (newCharacterRange.location < textStorage.string.length) {
        [[XCFXcodeFormatter currentSourceCodeTextView] setSelectedRanges:@[[NSValue valueWithRange:newCharacterRange]]];
        [textView scrollRangeToVisible:newCharacterRange];
    }
}

#pragma mark Formatting

+ (CFOFormatter *)formatterForString:(NSString *)inputString presentedURL:(NSURL *)presentedURL error:(NSError **)outError {
    
    NSString *selectedFormatter = [[NSUserDefaults standardUserDefaults] stringForKey:XCFDefaultsKeySelectedFormatter];
    if ([selectedFormatter isEqualToString:XCFDefaultsFormatterValueClang]) {
        XCFClangFormatter *formatter = [[XCFClangFormatter alloc] initWithInputString:inputString presentedURL:presentedURL];
        formatter.style = [[NSUserDefaults standardUserDefaults] stringForKey:XCFDefaultsKeyClangStyle];
        return formatter;
    }
    else if ([selectedFormatter isEqualToString:XCFDefaultsFormatterValueUncrustify]) {
        XCFUncrustifyFormatter *formatter = [[XCFUncrustifyFormatter alloc] initWithInputString:inputString presentedURL:presentedURL];
        formatter.configurationFileURL = [XCFUncrustifyFormatter configurationFileURLForPresentedURL:presentedURL];
        
        if (!formatter.configurationFileURL) {
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey : @"No configuration file was found for Uncrustify. To create a configuration file, open the Preferences."};
            NSError *error = [NSError errorWithDomain:XCFErrorDomain code:XCFFormatterMissingConfigurationError userInfo:userInfo];
            if (outError) {
                *outError = error;
            }
            return nil;
        }
        
        return formatter;
    }
    else NSAssert(NO, @"Missing case");
    return nil;
}

+ (BOOL)formatCodeOfDocument:(IDESourceCodeDocument *)document inWorkspace:(IDEWorkspace *)workspace error:(NSError **)outError {
    
    NSError *error = nil;
    
    DVTSourceTextStorage *textStorage = [document textStorage];
    
    NSString *originalString = [NSString stringWithString:textStorage.string];
    
    if (textStorage.string.length > 0) {
        CFOFormatter *formatter = [[self class] formatterForString:textStorage.string presentedURL:document.fileURL error:&error];
        NSString *formattedCode = [formatter stringByFormattingInputWithError:&error];
        if (formattedCode) {
            [textStorage beginEditing];
            if (![formattedCode isEqualToString:textStorage.string]) {
                [textStorage replaceCharactersInRange:NSMakeRange(0, textStorage.string.length) withString:formattedCode withUndoManager:[document undoManager]];
            }
            [XCFXcodeFormatter normalizeCodeAtRange:NSMakeRange(0, textStorage.string.length) document:document];
            [textStorage endEditing];
        }
    }
    
    if (error && outError) {
        *outError = error;
    }
    
    BOOL codeHasChanged = (originalString && ![originalString isEqualToString:textStorage.string]);
    return codeHasChanged;
}

+ (BOOL)formatCodeAtRanges:(NSArray *)ranges document:(IDESourceCodeDocument *)document inWorkspace:(IDEWorkspace *)workspace error:(NSError **)outError {
    DVTSourceTextStorage *textStorage = [document textStorage];
    
    NSError *error = nil;
    
    CFOFormatter *formatter = [[self class] formatterForString:textStorage.string presentedURL:document.fileURL error:&error];
    NSArray *fragments = [formatter fragmentsByFormattingInputAtRanges:ranges error:&error];

    NSString *originalString = [NSString stringWithString:textStorage.string];

    if (fragments) {

        NSMutableArray *newSelectionRanges = [NSMutableArray array];
        
        [fragments enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(CFOFragment *fragment, NSUInteger idx, BOOL *stop) {
            [textStorage beginEditing];
            [textStorage replaceCharactersInRange:fragment.inputRange withString:fragment.string withUndoManager:[document undoManager]];
            [XCFXcodeFormatter normalizeCodeAtRange:NSMakeRange(fragment.inputRange.location, fragment.string.length) document:document];
            
            // If more than one selection update previous range.locations by adding changeInLength
            if (newSelectionRanges.count > 0) {
                NSUInteger i = 0;
                while (i < newSelectionRanges.count) {
                    NSRange range = [[newSelectionRanges objectAtIndex:i] rangeValue];
                    range.location = range.location + [textStorage changeInLength];
                    [newSelectionRanges replaceObjectAtIndex:i withObject:[NSValue valueWithRange:range]];
                    i++;
                }
            }
            
            NSRange editedRange = [textStorage editedRange];
            if (editedRange.location != NSNotFound) {
                [newSelectionRanges addObject:[NSValue valueWithRange:editedRange]];
            }
            [textStorage endEditing];
        }];
        
        if (newSelectionRanges.count > 0) {
            [[XCFXcodeFormatter currentSourceCodeTextView] setSelectedRanges:newSelectionRanges];
        }
        
//        NSString *selectedFormatter = [[NSUserDefaults standardUserDefaults] stringForKey:XCFDefaultsKeySelectedFormatter];
//        if (0 && [selectedFormatter isEqualToString:XCFDefaultsFormatterValueClang]) {
//            NSArray *normalizedRanges = [formatter normalizedRangesForInputRanges:ranges];
//            NSMutableArray *fixedRanges = [NSMutableArray array];
//            for (NSValue *normalizedRangeValue in normalizedRanges) {
//                NSRange normalizedRange = [normalizedRangeValue rangeValue];
//                normalizedRange.length = MIN(normalizedRange.length, textStorage.string.length - normalizedRange.location);
//                [fixedRanges addObject:normalizedRangeValue];
//            }
//            if (fixedRanges.count > 0) {
//                [[XCFXcodeFormatter currentSourceCodeTextView] setSelectedRanges:fixedRanges];
//                [[XCFXcodeFormatter currentSourceCodeTextView]scrollRangeToVisible:[fixedRanges.firstObject rangeValue]];
//            }
//        }
//        else {
//            if (newSelectionRanges.count > 0) {
//                [[XCFXcodeFormatter currentSourceCodeTextView] setSelectedRanges:newSelectionRanges];
//            }
//        }
    }

    if (error && outError) {
        *outError = error;
    }
    
    BOOL codeHasChanged = (![originalString isEqualToString:textStorage.string]);
    return codeHasChanged;
}

#pragma mark Normalizing Formatting

+ (void)normalizeCodeAtRange:(NSRange)range document:(IDESourceCodeDocument *)document {
    
    BOOL shouldNormalize = [[NSUserDefaults standardUserDefaults] boolForKey:XCFDefaultsKeyXcodeIndentingEnabled];

    if (!shouldNormalize) return;
    
    DVTSourceTextStorage *textStorage = [document textStorage];
    
    const NSRange scopeLineRange = [textStorage lineRangeForCharacterRange:range]; // the line range stays unchanged during the normalization
    
    NSRange characterRange = [textStorage characterRangeForLineRange:scopeLineRange];
    
    DVTTextPreferences *preferences = [DVTTextPreferences preferences];
    
    if (preferences.useSyntaxAwareIndenting) {
        // PS: The method [DVTSourceTextStorage indentCharacterRange:undoManager:] always indents empty lines to the same level as code (ignoring the preferences in Xcode concerning the identation of whitespace only lines).
        [textStorage indentCharacterRange:characterRange undoManager:[document undoManager]];
        characterRange = [textStorage characterRangeForLineRange:scopeLineRange];
    }
    
    if (preferences.trimTrailingWhitespace) {
        BOOL trimTrailingWhitespace = preferences.trimTrailingWhitespace;
        BOOL trimWhitespaceOnlyLines = trimTrailingWhitespace && preferences.trimWhitespaceOnlyLines; // only enabled in Xcode preferences if trimTrailingWhitespace is enabled
        NSString *string = [textStorage.string substringWithRange:characterRange];
        NSString *trimString = [XCFXcodeFormatter stringByTrimmingString:string trimWhitespaceOnlyLines:trimWhitespaceOnlyLines trimTrailingWhitespace:trimTrailingWhitespace];
        [textStorage replaceCharactersInRange:characterRange withString:trimString withUndoManager:[document undoManager]];
    }
}

+ (NSString *)stringByTrimmingString:(NSString *)string trimWhitespaceOnlyLines:(BOOL)trimWhitespaceOnlyLines trimTrailingWhitespace:(BOOL)trimTrailingWhitespace {
    NSMutableString *mResultString = [NSMutableString string];
    
    // I'm not using [NSString enumerateLinesUsingBlock:] to enumerate the string by lines because the last line of the string is ignored if it's an empty line.
    NSArray *lines = [string componentsSeparatedByString:@"\n"];
    
    NSCharacterSet *characterSet = [NSCharacterSet whitespaceCharacterSet];  // [NSCharacterSet whitespaceCharacterSet] means tabs or spaces
    
    [lines enumerateObjectsWithOptions:0 usingBlock:^(NSString *line, NSUInteger idx, BOOL *stop) {
        if (idx > 0) {
            [mResultString appendString:@"\n"];
        }
        
        BOOL acceptedLine = YES;
        
        NSString *trimSubstring = [line stringByTrimmingCharactersInSet:characterSet];
        
        if (trimWhitespaceOnlyLines) {
            acceptedLine = (trimSubstring.length > 0);
        }
        
        if (acceptedLine) {
            if (trimTrailingWhitespace && trimSubstring.length > 0) {
                line = XCFStringByTrimmingTrailingCharactersFromString(line, characterSet);
            }
            [mResultString appendString:line];
        }
    }];
    
    return [NSString stringWithString:mResultString];
}

#pragma mark - Configuration Editor

+ (BOOL)canOpenApplicationWithIdentifier:(NSString *)identifier {
    BOOL appExists = NO;
    NSURL *appURL = [[NSWorkspace sharedWorkspace] URLForApplicationWithBundleIdentifier:identifier];
    if (appURL) appExists = [[NSFileManager defaultManager] fileExistsAtPath:appURL.path];
    return appExists;
}

+ (BOOL)canLaunchConfigurationEditor {
    IDESourceCodeDocument *document = [XCFXcodeFormatter currentSourceCodeDocument];
    return (document != nil);
}

+ (void)launchConfigurationEditorWithError:(NSError **)outError {
    
    IDESourceCodeDocument *document = [XCFXcodeFormatter currentSourceCodeDocument];
    if (!document) return;

    NSURL *configurationFileURL = nil;
    
    NSString *selectedFormatter = [[NSUserDefaults standardUserDefaults] stringForKey:XCFDefaultsKeySelectedFormatter];

    if ([selectedFormatter isEqualToString:XCFDefaultsFormatterValueClang]) {
        configurationFileURL = [XCFClangFormatter configurationFileURLForPresentedURL:document.fileURL];
    }
    else if ([selectedFormatter isEqualToString:XCFDefaultsFormatterValueUncrustify]) {
        configurationFileURL = [XCFUncrustifyFormatter configurationFileURLForPresentedURL:document.fileURL];
        if ([configurationFileURL isEqualTo:[XCFUncrustifyFormatter builtinConfigurationFileURL]]) {
            configurationFileURL = nil; // forbid to edit the configuration file in the plugin bundle
        }
    }
    else {
        return;
    }
    
    if (!configurationFileURL) {
        if (outError) {
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey : @"No configuration file was found. To create a configuration file, open the Preferences."};
            *outError = [NSError errorWithDomain:XCFErrorDomain code:XCFFormatterMissingConfigurationError userInfo:userInfo];
        }
        return;
    }
    
    if ([selectedFormatter isEqualToString:XCFDefaultsFormatterValueUncrustify]
        && [[NSUserDefaults standardUserDefaults] boolForKey:XCFDefaultsKeyUncrustifyXEnabled]
        && [[self class] canOpenApplicationWithIdentifier:XCFUncrustifyXIdentifier]) {
        
        IDESourceCodeDocument *document = [XCFXcodeFormatter currentSourceCodeDocument];
        if (document) {
            DVTSourceTextStorage *textStorage = [document textStorage];
            [[NSPasteboard pasteboardWithName:@"BBUncrustifyPlugin-source-code"] clearContents];
            if (textStorage.string) {
                [[NSPasteboard pasteboardWithName:@"BBUncrustifyPlugin-source-code"] writeObjects:@[textStorage.string]];
            }
        }
        NSDictionary *configuration = @{ NSWorkspaceLaunchConfigurationArguments: @[@"-bbuncrustifyplugin", @"-configpath", configurationFileURL.path] };
        NSURL *appURL = [[NSWorkspace sharedWorkspace] URLForApplicationWithBundleIdentifier:XCFUncrustifyXIdentifier];
        
        [[NSWorkspace sharedWorkspace]launchApplicationAtURL:appURL options:0 configuration:configuration error:nil];
    }
    else {
        BOOL succeeds = NO;
        
        NSString *editorIdentifier = [[NSUserDefaults standardUserDefaults] stringForKey:XCFDefaultsKeyConfigurationEditorIdentifier];
        if (editorIdentifier) {
            succeeds = [[NSWorkspace sharedWorkspace] openURLs:@[configurationFileURL] withAppBundleIdentifier:editorIdentifier options:NSWorkspaceLaunchDefault additionalEventParamDescriptor:nil launchIdentifiers:nil];
        }
        
        if (!succeeds) {
            [[NSWorkspace sharedWorkspace] openURL:configurationFileURL];
        }
        
    }
}

#pragma mark - Helpers

+ (id)currentEditor {
    NSWindowController *currentWindowController = [[NSApp keyWindow] windowController];
    if ([currentWindowController isKindOfClass:NSClassFromString(@"IDEWorkspaceWindowController")]) {
        IDEWorkspaceWindowController *workspaceController = (IDEWorkspaceWindowController *)currentWindowController;
        IDEEditorArea *editorArea = [workspaceController editorArea];
        IDEEditorContext *editorContext = [editorArea lastActiveEditorContext];
        return [editorContext editor];
    }
    return nil;
}

+ (IDEWorkspaceDocument *)currentWorkspaceDocument {
    NSWindowController *currentWindowController = [[NSApp keyWindow] windowController];
    id document = [currentWindowController document];
    if (currentWindowController && [document isKindOfClass:NSClassFromString(@"IDEWorkspaceDocument")]) {
        return (IDEWorkspaceDocument *)document;
    }
    return nil;
}

+ (IDESourceCodeDocument *)currentSourceCodeDocument {
    if ([[XCFXcodeFormatter currentEditor] isKindOfClass:NSClassFromString(@"IDESourceCodeEditor")]) {
        IDESourceCodeEditor *editor = [XCFXcodeFormatter currentEditor];
        return editor.sourceCodeDocument;
    }
    
    if ([[XCFXcodeFormatter currentEditor] isKindOfClass:NSClassFromString(@"IDESourceCodeComparisonEditor")]) {
        IDESourceCodeComparisonEditor *editor = [XCFXcodeFormatter currentEditor];
        if ([[editor primaryDocument] isKindOfClass:NSClassFromString(@"IDESourceCodeDocument")]) {
            IDESourceCodeDocument *document = (IDESourceCodeDocument *)editor.primaryDocument;
            return document;
        }
    }
    
    return nil;
}

+ (NSTextView *)currentSourceCodeTextView {
    if ([[XCFXcodeFormatter currentEditor] isKindOfClass:NSClassFromString(@"IDESourceCodeEditor")]) {
        IDESourceCodeEditor *editor = [XCFXcodeFormatter currentEditor];
        return editor.textView;
    }
    
    if ([[XCFXcodeFormatter currentEditor] isKindOfClass:NSClassFromString(@"IDESourceCodeComparisonEditor")]) {
        IDESourceCodeComparisonEditor *editor = [XCFXcodeFormatter currentEditor];
        return editor.keyTextView;
    }
    
    return nil;
}

+ (NSArray *)selectedNavigableItems {
    NSMutableArray *mutableArray = [NSMutableArray array];
    id currentWindowController = [[NSApp keyWindow] windowController];
    if ([currentWindowController isKindOfClass:NSClassFromString(@"IDEWorkspaceWindowController")]) {
        IDEWorkspaceWindowController *workspaceController = currentWindowController;
        IDEWorkspaceTabController *workspaceTabController = [workspaceController activeWorkspaceTabController];
        IDENavigatorArea *navigatorArea = [workspaceTabController navigatorArea];
        id currentNavigator = [navigatorArea currentNavigator];
        
        if ([currentNavigator isKindOfClass:NSClassFromString(@"IDEStructureNavigator")]) {
            IDEStructureNavigator *structureNavigator = currentNavigator;
            for (id selectedObject in structureNavigator.selectedObjects) {
                if ([selectedObject isKindOfClass:NSClassFromString(@"IDENavigableItem")]) {
                    [mutableArray addObject:selectedObject];
                }
            }
        }
    }
    
    if (mutableArray.count) {
        return [NSArray arrayWithArray:mutableArray];
    }
    return nil;
}

+ (NSArray *)selectedSourceCodeFileNavigableItems {
    NSMutableArray *mutableArray = [NSMutableArray array];
    id currentWindowController = [[NSApp keyWindow] windowController];
    if ([currentWindowController isKindOfClass:NSClassFromString(@"IDEWorkspaceWindowController")]) {
        IDEWorkspaceWindowController *workspaceController = currentWindowController;
        IDEWorkspaceTabController *workspaceTabController = [workspaceController activeWorkspaceTabController];
        IDENavigatorArea *navigatorArea = [workspaceTabController navigatorArea];
        id currentNavigator = [navigatorArea currentNavigator];
        
        if ([currentNavigator isKindOfClass:NSClassFromString(@"IDEStructureNavigator")]) {
            IDEStructureNavigator *structureNavigator = currentNavigator;
            for (id selectedObject in structureNavigator.selectedObjects) {
                NSArray *arrayOfFiles = [self recursivlyCollectFileNavigableItemsFrom:selectedObject];
                if (arrayOfFiles.count) {
                    [mutableArray addObjectsFromArray:arrayOfFiles];
                }
            }
        }
    }
    
    if (mutableArray.count) {
        return [NSArray arrayWithArray:mutableArray];
    }
    return nil;
}

+ (NSArray *)recursivlyCollectFileNavigableItemsFrom:(IDENavigableItem *)selectedObject {
    id items = nil;
    
    if ([selectedObject isKindOfClass:NSClassFromString(@"IDEGroupNavigableItem")]) {
        //|| [selectedObject isKindOfClass:NSClassFromString(@"IDEContainerFileReferenceNavigableItem")]) { //disallow project
        NSMutableArray *mItems = [NSMutableArray array];
        IDEGroupNavigableItem *groupNavigableItem = (IDEGroupNavigableItem *)selectedObject;
        for (IDENavigableItem *child in groupNavigableItem.childItems) {
            NSArray *childItems = [self recursivlyCollectFileNavigableItemsFrom:child];
            if (childItems.count) {
                [mItems addObjectsFromArray:childItems];
            }
        }
        items = mItems;
    }
    else if ([selectedObject isKindOfClass:NSClassFromString(@"IDEFileNavigableItem")]) {
        IDEFileNavigableItem *fileNavigableItem = (IDEFileNavigableItem *)selectedObject;
        NSString *uti = fileNavigableItem.documentType.identifier;
        if ([[NSWorkspace sharedWorkspace] type:uti conformsToType:(NSString *)kUTTypeSourceCode]) {
            items = @[fileNavigableItem];
        }
    }
    
    return items;
}

+ (NSArray *)containerFolderURLsForNavigableItem:(IDENavigableItem *)navigableItem {
    NSMutableArray *mArray = [NSMutableArray array];
    
    do {
        NSURL *folderURL = nil;
        id representedObject = navigableItem.representedObject;
        if ([navigableItem isKindOfClass:NSClassFromString(@"IDEGroupNavigableItem")]) {
            // IDE-GROUP (a folder in the navigator)
            IDEGroup *group = (IDEGroup *)representedObject;
            folderURL = group.resolvedFilePath.fileURL;
        } else if ([navigableItem isKindOfClass:NSClassFromString(@"IDEContainerFileReferenceNavigableItem")]) {
            // CONTAINER (an Xcode project)
            IDEFileReference *fileReference = representedObject;
            folderURL = [fileReference.resolvedFilePath.fileURL URLByDeletingLastPathComponent];
        } else if ([navigableItem isKindOfClass:NSClassFromString(@"IDEKeyDrivenNavigableItem")]) {
            // WORKSPACE (root: Xcode project or workspace)
            IDEWorkspace *workspace = representedObject;
            folderURL = [workspace.representingFilePath.fileURL URLByDeletingLastPathComponent];
        }
        if (folderURL && ![mArray containsObject:folderURL]) [mArray addObject:folderURL];
        navigableItem = [navigableItem parentItem];
    } while (navigableItem != nil);
    
    if (mArray.count > 0) return [NSArray arrayWithArray:mArray];
    return nil;
}

+ (NSArray *)containerFolderURLsAncestorsToNavigableItem:(IDENavigableItem *)navigableItem {
    if (navigableItem) {
        return [XCFXcodeFormatter containerFolderURLsForNavigableItem:navigableItem];
    }
    return nil;
}


@end
