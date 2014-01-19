//
//  Created by Benoît on 11/01/14.
//  Copyright (c) 2014 Pragmatic Code. All rights reserved.
//

#import "CFOFormatter.h"

@interface CFOUncrustifyFormatter : CFOFormatter

@property (nonatomic) NSURL *configurationFileURL;

+ (NSData *)factoryStyleConfigurationWithComments:(BOOL)includeComments error:(NSError **)error;

@end
