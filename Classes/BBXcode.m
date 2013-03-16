//
//  BBXcode.m
//  BBUncrustifyPlugin
//
//  Created by Benoît on 16/03/13.
//
//

#import "BBXcode.h"

@implementation BBXcode

+ (id)currentEditor {
    IDEWorkspaceWindowController *workspaceController = [[NSApp keyWindow] windowController];
    if ([workspaceController isKindOfClass:NSClassFromString(@"IDEWorkspaceWindowController")]) {
        IDEEditorArea *editorArea = [workspaceController editorArea];
        IDEEditorContext *editorContext = [editorArea lastActiveEditorContext];
        return [editorContext editor];
    }
    return nil;
}

@end
