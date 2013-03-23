//
//  BBXcode.h
//  BBUncrustifyPlugin
//
//  Created by Benoît on 16/03/13.
//
//

#import <Cocoa/Cocoa.h>

@interface DVTTextDocumentLocation : NSObject
- (NSRange)characterRange;
@end

@interface DVTSourceTextStorage : NSTextStorage
- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)string withUndoManager:(id)undoManager;
@end

@interface DVTFileDataType : NSObject
@property(readonly) NSString *identifier;
@end

@interface IDEFileNavigableItem : NSObject
@property(readonly) DVTFileDataType *documentType;
@property(readonly) NSURL *fileURL;
@end

@interface IDEStructureNavigator : NSObject
@property(retain) NSArray *selectedObjects;
@end

@interface IDENavigatorArea : NSObject
- (id)currentNavigator;
@end

@interface IDEWorkspaceTabController : NSObject
@property(readonly) IDENavigatorArea *navigatorArea;
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

@interface IDESourceCodeEditor : NSObject
- (IDESourceCodeDocument *)sourceCodeDocument;
- (NSArray *)currentSelectedDocumentLocations; // DVTTextDocumentLocation objects
@end

@interface IDEEditorContext : NSObject
- (id)editor; // returns the current editor. If the editor is the code editor, the class is `IDESourceCodeEditor`
@end

@interface IDEEditorArea : NSObject
- (IDEEditorContext *)lastActiveEditorContext;
@end

@interface IDEWorkspaceWindowController : NSObject
@property(readonly) IDEWorkspaceTabController *activeWorkspaceTabController;
- (IDEEditorArea *)editorArea;
@end

@interface BBXcode : NSObject
+ (id)currentEditor;
+ (NSArray *)selectedObjCFileNavigableItems;
+ (BOOL)uncrustifyCodeOfDocument:(IDESourceCodeDocument*)document;
@end
