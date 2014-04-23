//
//  Created by Benoît on 11/01/14.
//  Copyright (c) 2014 Pragmatic Code. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const XCFDefaultsKeySelectedFormatter;
extern NSString * const XCFDefaultsFormatterValueClang;
extern NSString * const XCFDefaultsFormatterValueUncrustify;

extern NSString * const XCFDefaultsKeyXcodeIndentingEnabled;
extern NSString * const XCFDefaultsKeyFormatOnSaveEnabled;
extern NSString * const XCFDefaultsKeyFormatOnSaveFiletypes;//a string which ; separater file extensions
extern NSString * const XCFDefaultsKeyClangStyle;

extern NSString * const XCFDefaultsKeyClangFactoryBasedStyle;
extern NSString * const XCFDefaultsClangFactoryBasedStyleValueNone;

extern NSString * const XCFDefaultsKeyConfigurationEditorIdentifier;
extern NSString * const XCFDefaultsKeyUncrustifyXEnabled;

@interface XCFDefaults : NSObject

+ (void)registerDefaults;
+ (void)debug_clearPreferences;

@end
