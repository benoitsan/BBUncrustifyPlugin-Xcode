//
//  BBXcode.m
//  BBUncrustifyPlugin
//
//  Created by Benoît on 16/03/13.
//
//

#import "BBXcode.h"
#import "BBUncrustify.h"

NSString * const BBUserDefaultsCodeFormattingScheme = @"uncrustify_plugin_codeFormattingScheme";

NSArray * BBMergeContinuousRanges(NSArray *ranges) {
    if (ranges.count == 0) return nil;
    
    NSMutableIndexSet *mIndexes = [NSMutableIndexSet indexSet];
    for (NSValue *rangeValue in ranges) {
        NSRange range = [rangeValue rangeValue];
        [mIndexes addIndexesInRange:range];
    }
    
    NSMutableArray *mergedRanges = [NSMutableArray array];
    [mIndexes enumerateRangesUsingBlock:^(NSRange range, BOOL *stop) {
        [mergedRanges addObject:[NSValue valueWithRange:range]];
    }];
    return [NSArray arrayWithArray:mergedRanges];
}

NSString * BBStringByTrimmingTrailingCharactersFromString(NSString *string, NSCharacterSet *characterSet) {
    NSRange rangeOfLastWantedCharacter = [string rangeOfCharacterFromSet:[characterSet invertedSet] options:NSBackwardsSearch];
    if (rangeOfLastWantedCharacter.location == NSNotFound) return @"";
    return [string substringToIndex:rangeOfLastWantedCharacter.location + 1];
}

@implementation BBXcode {}

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
    if ([[BBXcode currentEditor] isKindOfClass:NSClassFromString(@"IDESourceCodeEditor")]) {
        IDESourceCodeEditor *editor = [BBXcode currentEditor];
        return editor.sourceCodeDocument;
    }
    
    if ([[BBXcode currentEditor] isKindOfClass:NSClassFromString(@"IDESourceCodeComparisonEditor")]) {
        IDESourceCodeComparisonEditor *editor = [BBXcode currentEditor];
        if ([[editor primaryDocument] isKindOfClass:NSClassFromString(@"IDESourceCodeDocument")]) {
            IDESourceCodeDocument *document = (IDESourceCodeDocument *)editor.primaryDocument;
            return document;
        }
    }
    
    return nil;
}

+ (NSTextView *)currentSourceCodeTextView {
    if ([[BBXcode currentEditor] isKindOfClass:NSClassFromString(@"IDESourceCodeEditor")]) {
        IDESourceCodeEditor *editor = [BBXcode currentEditor];
        return editor.textView;
    }
    
    if ([[BBXcode currentEditor] isKindOfClass:NSClassFromString(@"IDESourceCodeComparisonEditor")]) {
        IDESourceCodeComparisonEditor *editor = [BBXcode currentEditor];
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
                if ([selectedObject isKindOfClass:NSClassFromString(@"IDEFileNavigableItem")]) {
                    IDEFileNavigableItem *fileNavigableItem = selectedObject;
                    NSString *uti = fileNavigableItem.documentType.identifier;
                    if ([[NSWorkspace sharedWorkspace] type:uti conformsToType:(NSString *)kUTTypeSourceCode]) {
                        [mutableArray addObject:fileNavigableItem];
                    }
                }
            }
        }
    }
    
    if (mutableArray.count) {
        return [NSArray arrayWithArray:mutableArray];
    }
    return nil;
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
        return [BBXcode containerFolderURLsForNavigableItem:navigableItem];
    }
    return nil;
}

#pragma mark - Uncrustify

+ (BOOL)uncrustifyCodeOfDocument:(IDESourceCodeDocument *)document inWorkspace:(IDEWorkspace *)workspace {
    DVTSourceTextStorage *textStorage = [document textStorage];
    
    NSString *originalString = [NSString stringWithString:textStorage.string];
    
    if (textStorage.string.length > 0) {
        NSArray *additionalConfigurationFolderURLs = nil;
        if (workspace) {
            IDENavigableItemCoordinator *coordinator = [[IDENavigableItemCoordinator alloc] init];
            IDENavigableItem *navigableItem = [coordinator structureNavigableItemForDocumentURL:document.fileURL inWorkspace:workspace error:nil];
#if !__has_feature(objc_arc)
            [coordinator release];
#endif
            if (navigableItem) {
                additionalConfigurationFolderURLs = [BBXcode containerFolderURLsForNavigableItem:navigableItem];
            }
        }
        
        NSMutableDictionary *options = [NSMutableDictionary dictionaryWithDictionary:@{ BBUncrustifyOptionSourceFilename: document.fileURL.lastPathComponent }];
        if (additionalConfigurationFolderURLs.count > 0) {
            [options setObject:additionalConfigurationFolderURLs forKey:BBUncrustifyOptionSupplementalConfigurationFolders];
        }
        
        [textStorage beginEditing];
        NSString *uncrustifiedCode = [BBUncrustify uncrustifyCodeFragment:textStorage.string options:options];
        if (![uncrustifiedCode isEqualToString:textStorage.string]) {
            [textStorage replaceCharactersInRange:NSMakeRange(0, textStorage.string.length) withString:uncrustifiedCode withUndoManager:[document undoManager]];
        }
        [BBXcode normalizeCodeAtRange:NSMakeRange(0, textStorage.string.length) document:document];
        [textStorage endEditing];
    }
    
    BOOL codeHasChanged = (originalString && ![originalString isEqualToString:textStorage.string]);
    return codeHasChanged;
}

+ (BOOL)uncrustifyCodeAtRanges:(NSArray *)ranges document:(IDESourceCodeDocument *)document inWorkspace:(IDEWorkspace *)workspace {
    DVTSourceTextStorage *textStorage = [document textStorage];
    
    NSArray *linesRangeValues = nil;
    {
        NSMutableArray *mLinesRangeValues = [NSMutableArray array];
        for (NSValue *rangeValue in ranges) {
            NSRange range = [rangeValue rangeValue];
            NSRange lineRange = [textStorage lineRangeForCharacterRange:range];
            [mLinesRangeValues addObject:[NSValue valueWithRange:lineRange]];
        }
        linesRangeValues = BBMergeContinuousRanges(mLinesRangeValues);
    }
    
    NSMutableArray *textFragments = [NSMutableArray array];
    
    NSArray *additionalConfigurationFolderURLs = nil;
    if (workspace) {
        IDENavigableItemCoordinator *coordinator = [[IDENavigableItemCoordinator alloc] init];
        IDENavigableItem *navigableItem = [coordinator structureNavigableItemForDocumentURL:document.fileURL inWorkspace:workspace error:nil];
#if !__has_feature(objc_arc)
        [coordinator release];
#endif
        if (navigableItem) {
            additionalConfigurationFolderURLs = [BBXcode containerFolderURLsForNavigableItem:navigableItem];
        }
    }
    
    for (NSValue *linesRangeValue in linesRangeValues) {
        NSRange linesRange = [linesRangeValue rangeValue];
        NSRange characterRange = [textStorage characterRangeForLineRange:linesRange];
        if (characterRange.location != NSNotFound) {
            NSString *string = [textStorage.string substringWithRange:characterRange];
            if (string.length > 0) {
                NSMutableDictionary *options = [NSMutableDictionary dictionaryWithDictionary:@{ BBUncrustifyOptionEvictCommentInsertion: @YES, BBUncrustifyOptionSourceFilename: document.fileURL.lastPathComponent }];
                if (additionalConfigurationFolderURLs.count > 0) {
                    [options setObject:additionalConfigurationFolderURLs forKey:BBUncrustifyOptionSupplementalConfigurationFolders];
                }
                
                NSString *uncrustifiedString = [BBUncrustify uncrustifyCodeFragment:string options:options];
                if (uncrustifiedString.length > 0) {
                    [textFragments addObject:@{ @"textFragment": uncrustifiedString, @"range": [NSValue valueWithRange:characterRange] }];
                }
            }
        }
    }
    
    NSString *originalString = [NSString stringWithString:textStorage.string];
    
    NSMutableArray *newSelectionRanges = [NSMutableArray array];
    
    [textFragments enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSDictionary *textFragment, NSUInteger idx, BOOL *stop) {
        NSRange range = [textFragment[@"range"] rangeValue];
        NSString *newString = textFragment[@"textFragment"];
        [textStorage beginEditing];
        [textStorage replaceCharactersInRange:range withString:newString withUndoManager:[document undoManager]];
        [BBXcode normalizeCodeAtRange:NSMakeRange(range.location, newString.length) document:document];
        
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
        [[BBXcode currentSourceCodeTextView] setSelectedRanges:newSelectionRanges];
    }
    
    BOOL codeHasChanged = (![originalString isEqualToString:textStorage.string]);
    return codeHasChanged;
}

#pragma mark - Normalizing

+ (void)normalizeCodeAtRange:(NSRange)range document:(IDESourceCodeDocument *)document {
    BBCodeFormattingScheme scheme = [[NSUserDefaults standardUserDefaults] integerForKey:BBUserDefaultsCodeFormattingScheme];
    NSLog(@"scheme %li",scheme);
    if (scheme != BBCodeFormattingSchemeUncrustifyAndXCodeNormalization) return;
    
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
        NSString *trimString = [BBXcode stringByTrimmingString:string trimWhitespaceOnlyLines:trimWhitespaceOnlyLines trimTrailingWhitespace:trimTrailingWhitespace];
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
                line = BBStringByTrimmingTrailingCharactersFromString(line, characterSet);
            }
            [mResultString appendString:line];
        }
    }];
    
    return [NSString stringWithString:mResultString];
}

@end
