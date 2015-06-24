//
// NSDocument+XCFAdditions.m
// Created by Dominik Pich on 1/17/14.
//

#import "NSDocument+XCFAdditions.h"
#import "XCFDefaults.h"
#import "XCFXcodePrivate.h"
#import "XCFXcodeFormatter.h"
#import "JRSwizzle.h"
#import "BBLogging.h"

@implementation NSDocument (XCFAdditions)

#pragma mark - Setup and Teardown

+ (void)load
{
	NSError *error = nil;
	
	if (![self jr_swizzleMethod:@selector(saveDocumentWithDelegate:didSaveSelector:contextInfo:) withMethod:@selector(xcf_saveDocumentWithDelegate:didSaveSelector:contextInfo:) error:&error]) {
		DDLogError(@"swizzling error %@", error);
	}
}

#pragma mark - Additions

- (void)xcf_documentWillSave
{
	BOOL canFormatDocument = [self isKindOfClass:NSClassFromString(@"IDESourceCodeDocument")];
	
	if (!canFormatDocument) {
		return;
	}
	
	BOOL shouldFormatBeforeSaving = [[NSUserDefaults standardUserDefaults] boolForKey:XCFDefaultsKeyFormatOnSaveEnabled];
	
	if (!shouldFormatBeforeSaving) {
		return;
	}
	
	NSString *patternsString = [[NSUserDefaults standardUserDefaults] stringForKey:XCFDefaultsKeyFormatOnSaveFiletypes];
	
	if (patternsString.length) {
		NSArray *extensions = [patternsString componentsSeparatedByString:@";"];
		
		if (![extensions containsObject:self.fileURL.pathExtension]) {
			// NSLog(@"Skip %@ due to extension mismatch: %@", self.fileURL, patternsString);
			return;
		}
	}
	
	IDESourceCodeDocument *document = (IDESourceCodeDocument *)self;
	NSError *error;
	
	BOOL isTemporaryFile = (document && [document.fileURL.path hasPrefix:@"/var/folders/"]);
	
	// When formatting on save is enabled, when using the Xcode refactoring tools, the document is temporary saved in the temporary directory
	if (!isTemporaryFile) {
		[XCFXcodeFormatter formatDocument:document withError:&error];
	}
	
	if (error) {
		DDLogError(@"%@", error);
	}
	// NSLog(@"Formatted %@: %@", self.fileURL, error ? error : @"OK");
}

#pragma mark - Swizzled methods

- (void)xcf_saveDocumentWithDelegate:(id)delegate didSaveSelector:(SEL)didSaveSelector contextInfo:(void *)contextInfo
{
	[self xcf_documentWillSave];
	
	[self xcf_saveDocumentWithDelegate:delegate didSaveSelector:didSaveSelector contextInfo:contextInfo];
}

@end
