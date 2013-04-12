//
//  BBXcode.m
//  BBUncrustifyPlugin
//
//  Created by Benoît on 16/03/13.
//
//

#import "BBXcode.h"
#import "BBUncrustify.h"

NSArray *BBMergeContinuousRanges(NSArray* ranges) {
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

NSString * BBStringByTrimmingTrailingCharactersFromString(NSString *string, NSCharacterSet * characterSet) {
    NSRange rangeOfLastWantedCharacter = [string rangeOfCharacterFromSet:[characterSet invertedSet] options:NSBackwardsSearch];
    if (rangeOfLastWantedCharacter.location == NSNotFound) return @"";
    return [string substringToIndex:rangeOfLastWantedCharacter.location + 1];
}

@implementation BBXcode {}

#pragma mark - Helpers

+ (id)currentEditor {
    id currentWindowController = [[NSApp keyWindow] windowController];
    if ([currentWindowController isKindOfClass:NSClassFromString(@"IDEWorkspaceWindowController")]) {
        IDEWorkspaceWindowController *workspaceController = currentWindowController;
        IDEEditorArea *editorArea = [workspaceController editorArea];
        IDEEditorContext *editorContext = [editorArea lastActiveEditorContext];
        return [editorContext editor];
    }
    return nil;
}

+ (NSArray *)selectedObjCFileNavigableItems {
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
                    if ([uti isEqualToString:(NSString *)kUTTypeObjectiveCSource] || [uti isEqualToString:(NSString *)kUTTypeCHeader]) {
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

#pragma mark - Uncrustify

+ (BOOL)uncrustifyCodeOfDocument:(IDESourceCodeDocument *)document {
    DVTSourceTextStorage *textStorage = [document textStorage];
    NSString *originalString = textStorage.string;
    if (textStorage.string.length > 0) {
        NSString *uncrustifiedCode = [BBUncrustify uncrustifyCodeFragment:textStorage.string options:@{BBUncrustifyOptionSourceFilename : document.fileURL.lastPathComponent}];
        if (![uncrustifiedCode isEqualToString:textStorage.string]) {
            [textStorage replaceCharactersInRange:NSMakeRange(0, textStorage.string.length) withString:uncrustifiedCode withUndoManager:[document undoManager]];
        }
        [BBXcode normalizeCodeAtRange:NSMakeRange(0, textStorage.string.length) document:document];
    }

    BOOL codeHasChanged = (originalString && ![originalString isEqualToString:textStorage.string]);
    return codeHasChanged;
}

+ (BOOL)uncrustifyCodeAtRanges:(NSArray *)ranges document:(IDESourceCodeDocument *)document {
    BOOL uncrustified = NO;
        
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
    
    for (NSValue *linesRangeValue in linesRangeValues) {
        NSRange linesRange = [linesRangeValue rangeValue];
        NSRange characterRange = [textStorage characterRangeForLineRange:linesRange];
        if (characterRange.location != NSNotFound) {
            NSString *string = [textStorage.string substringWithRange:characterRange];
            if (string.length > 0) {
                NSString *uncrustifiedString = [BBUncrustify uncrustifyCodeFragment:string options:@{BBUncrustifyOptionEvictCommentInsertion : @YES, BBUncrustifyOptionSourceFilename : document.fileURL.lastPathComponent}];
                if (uncrustifiedString.length > 0) {
                    [textFragments addObject:@{@"textFragment" : uncrustifiedString, @"range" : [NSValue valueWithRange:characterRange]}];
                }
            }
        }
    }
    
    NSString *originalString = textStorage.string;
    
    [textFragments enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSDictionary *textFragment, NSUInteger idx, BOOL *stop) {
        NSRange range = [textFragment[@"range"] rangeValue];
        NSString *newString = textFragment[@"textFragment"];
        [textStorage replaceCharactersInRange:range withString:newString withUndoManager:[document undoManager]];
        [BBXcode normalizeCodeAtRange:NSMakeRange(range.location, newString.length) document:document];
    }];

    BOOL codeHasChanged = (![originalString isEqualToString:textStorage.string]);
    return codeHasChanged;
}

#pragma mark - Normalizing

+ (void)normalizeCodeAtRange:(NSRange)range document:(IDESourceCodeDocument *)document {
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
    
    NSCharacterSet * characterSet = [NSCharacterSet whitespaceCharacterSet]; // [NSCharacterSet whitespaceCharacterSet] means tabs or spaces
    
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
