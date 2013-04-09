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

@implementation BBXcode

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

+ (BOOL)uncrustifyCodeOfDocument:(IDESourceCodeDocument *)document {
    BOOL uncrustified = NO;
    DVTSourceTextStorage *textStorage = [document textStorage];
    if (textStorage.string.length > 0) {
        NSString *uncrustifiedCode = [BBUncrustify uncrustifyCodeFragment:textStorage.string options:@{BBUncrustifyOptionSourceFilename : document.fileURL.lastPathComponent}];
        if (![uncrustifiedCode isEqualToString:textStorage.string]) {
            [textStorage replaceCharactersInRange:NSMakeRange(0, textStorage.string.length) withString:uncrustifiedCode withUndoManager:[document undoManager]];
            [textStorage indentCharacterRange:NSMakeRange(0, textStorage.string.length) undoManager:[document undoManager]];
            uncrustified = YES;
        }
    }
    return uncrustified;
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
    
    __block NSString *uncrustifiedCode = textStorage.string;
    
    [textFragments enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSDictionary *textFragment, NSUInteger idx, BOOL *stop) {
        NSRange range = [textFragment[@"range"] rangeValue];
        uncrustifiedCode = [uncrustifiedCode stringByReplacingCharactersInRange:range withString:textFragment[@"textFragment"]];
    }];
    
    if (![uncrustifiedCode isEqualToString:textStorage.string]) {
        [textStorage replaceCharactersInRange:NSMakeRange(0, textStorage.string.length) withString:uncrustifiedCode withUndoManager:[document undoManager]];
        uncrustified = YES;
    }
    
    if (uncrustified) {
        [textStorage indentCharacterRange:NSMakeRange(0, textStorage.string.length) undoManager:[document undoManager]];
    }
    
    return uncrustified;
}

@end
