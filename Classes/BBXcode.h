//
//  BBXcode.h
//  BBUncrustifyPlugin
//
//  Created by Benoît on 16/03/13.
//
//

#import <Cocoa/Cocoa.h>

extern NSString *const BBUserDefaultsCodeFormattingScheme;

typedef NS_ENUM (NSUInteger, BBCodeFormattingScheme) {
	BBCodeFormattingSchemeUncrustifyAndXCodeNormalization = 0, // code is formatted using uncrustify program and then normalized following Xcode preferences.
	BBCodeFormattingSchemeUncrustify = 1 // code is formatted using uncrustify program.
};

@interface DVTTextDocumentLocation : NSObject
@property (readonly) NSRange characterRange;
@property (readonly) NSRange lineRange;
@end

@interface DVTTextPreferences : NSObject
+ (id)preferences;
@property BOOL trimWhitespaceOnlyLines;
@property BOOL trimTrailingWhitespace;
@property BOOL useSyntaxAwareIndenting;
@end

@interface DVTSourceTextStorage : NSTextStorage
- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)string withUndoManager:(id)undoManager;
- (NSRange)lineRangeForCharacterRange:(NSRange)range;
- (NSRange)characterRangeForLineRange:(NSRange)range;
- (void)indentCharacterRange:(NSRange)range undoManager:(id)undoManager;
@end

@interface DVTFileDataType : NSObject
@property (readonly) NSString *identifier;
@end

@interface DVTFilePath : NSObject
@property (readonly) NSURL *fileURL;
@property (readonly) DVTFileDataType *fileDataTypePresumed;
@end

@interface IDEContainerItem : NSObject
@property (readonly) DVTFilePath *resolvedFilePath;
@end

@interface IDEGroup : IDEContainerItem

@end

@interface IDEFileReference : IDEContainerItem

@end

@interface IDENavigableItem : NSObject
@property (readonly) IDENavigableItem *parentItem;
@property (readonly) NSArray *childItems;
@property (readonly) id representedObject;
@end

@interface IDEFileNavigableItem : IDENavigableItem
@property (readonly) DVTFileDataType *documentType;
@property (readonly) NSURL *fileURL;
@end

@interface IDEGroupNavigableItem : IDENavigableItem
@property (readonly) IDEGroup *group;
@end

@interface IDEStructureNavigator : NSObject
@property (retain) NSArray *selectedObjects;
@end

@interface IDENavigableItemCoordinator : NSObject
- (id)structureNavigableItemForDocumentURL:(id)arg1 inWorkspace:(id)arg2 error:(id *)arg3;
@end

@interface IDENavigatorArea : NSObject
- (id)currentNavigator;
@end

@interface IDEWorkspaceTabController : NSObject
@property (readonly) IDENavigatorArea *navigatorArea;
@end

@interface IDEDocumentController : NSDocumentController
+ (id)editorDocumentForNavigableItem:(id)arg1;
+ (id)retainedEditorDocumentForNavigableItem:(id)arg1 error:(id *)arg2;
+ (void)releaseEditorDocument:(id)arg1;
@end

@interface IDESourceCodeDocument : NSDocument
- (DVTSourceTextStorage *)textStorage;
- (NSUndoManager *)undoManager;
@end

@interface IDESourceCodeComparisonEditor : NSObject
@property (readonly) NSTextView *keyTextView;
@property (retain) NSDocument *primaryDocument;
@end

@interface IDESourceCodeEditor : NSObject
@property (retain) NSTextView *textView;
- (IDESourceCodeDocument *)sourceCodeDocument;
@end

@interface IDEEditorContext : NSObject
- (id)editor; // returns the current editor. If the editor is the code editor, the class is `IDESourceCodeEditor`
@end

@interface IDEEditorArea : NSObject
- (IDEEditorContext *)lastActiveEditorContext;
@end

@interface IDEWorkspaceWindowController : NSObject
@property (readonly) IDEWorkspaceTabController *activeWorkspaceTabController;
- (IDEEditorArea *)editorArea;
@end

@interface IDEWorkspace : NSObject
@property (readonly) DVTFilePath *representingFilePath;
@end

@interface IDEWorkspaceDocument : NSDocument
@property (readonly) IDEWorkspace *workspace;
@end

@interface BBXcode : NSObject
+ (IDEWorkspaceDocument *)currentWorkspaceDocument;
+ (IDESourceCodeDocument *)currentSourceCodeDocument;
+ (NSTextView *)currentSourceCodeTextView;
+ (NSArray *)selectedSourceCodeFileNavigableItems;
+ (NSArray *)selectedNavigableItems;
+ (NSArray *)containerFolderURLsAncestorsToNavigableItem:(IDENavigableItem *)navigableItem;
+ (BOOL)uncrustifyCodeOfDocument:(IDESourceCodeDocument *)document inWorkspace:(IDEWorkspace *)workspace;
+ (BOOL)uncrustifyCodeAtRanges:(NSArray *)ranges document:(IDESourceCodeDocument *)document inWorkspace:(IDEWorkspace *)workspace;
@end
