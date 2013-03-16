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

@interface IDESourceCodeDocument : NSObject
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
- (IDEEditorArea *)editorArea;
@end

@interface BBXcode : NSObject
+ (id)currentEditor;
@end
