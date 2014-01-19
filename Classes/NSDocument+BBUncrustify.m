//
//  NSDocument+BBUncrustify.m
//  Created by Dominik Pich on 1/17/14.
//

#import "NSDocument+BBUncrustify.h"
#import <objc/runtime.h>
#import "XCFXcodePrivate.h"
#import "XCFXcodeFormatter.h"

@implementation NSDocument (TRVSClangFormat)

- (void)bb_documentWillSave {
	if ([self bb_shouldFormatBeforeSaving]) {
		NSError *error;
		[XCFXcodeFormatter formatDocument:self withError:&error];

		NSLog(@"%@: %@", self.presentedItemURL, error ? error : @"OK");
	}
}

- (void)bb_saveDocumentWithDelegate:(id)delegate
                    didSaveSelector:(SEL)didSaveSelector
                        contextInfo:(void *)contextInfo {
	[self bb_documentWillSave];

	[self bb_saveDocumentWithDelegate:delegate
	                  didSaveSelector:didSaveSelector
	                      contextInfo:contextInfo];
}

- (BOOL)bb_shouldFormatBeforeSaving {
	return [self.class applyFormatOnSave] && [XCFXcodeFormatter canFormatDocument:self];
}

#pragma mark -

static BOOL _applyFormatOnSave;

+ (BOOL)applyFormatOnSave {
	return _applyFormatOnSave;
}

+ (void)setApplyFormatOnSave:(BOOL)formatOnSave {
	_applyFormatOnSave = formatOnSave;
}

#pragma mark -

+ (void)load {
	[self swizzleInstanceMethodWithSelector:@selector(saveDocumentWithDelegate:didSaveSelector:contextInfo:) withSelector:@selector(bb_saveDocumentWithDelegate:didSaveSelector:contextInfo:)];
}

+ (void)swizzleInstanceMethodWithSelector:(SEL)originalSelector withSelector:(SEL)overrideSelector {
	Method originalMethod = class_getInstanceMethod(self, originalSelector);
	Method overrideMethod = class_getInstanceMethod(self, overrideSelector);
	if (class_addMethod(self, originalSelector, method_getImplementation(overrideMethod), method_getTypeEncoding(overrideMethod))) {
		class_replaceMethod(self, overrideSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
	}
	else {
		method_exchangeImplementations(originalMethod, overrideMethod);
	}
}

@end
