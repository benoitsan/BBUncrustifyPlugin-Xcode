//
//  Created by Benoît on 11/01/14.
//  Copyright (c) 2014 Pragmatic Code. All rights reserved.
//

#import "CFOClangFormatter.h"
#import "CFOUncrustifyFormatter.h"

@interface CFOClangFormatter(XCFAdditions)

+ (NSURL *)configurationFileURLForPresentedURL:(NSURL *)presentedURL;

@end

@interface CFOUncrustifyFormatter(XCFAdditions)

+ (NSURL *)builtinConfigurationFileURL;

+ (NSURL *)configurationFileURLForPresentedURL:(NSURL *)presentedURL;

@end


