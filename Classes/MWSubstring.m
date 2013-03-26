//
//  MWSubstring.m
//  BBUncrustifyPlugin
//
//  Created by Daniel Ericsson on 2013-03-24.
//

#import "MWSubstring.h"

@implementation MWSubstring

- (id)initWithString:(NSString *)aString rangeValue:(NSRange)aRange {
    if (self = [super init]) {
        _string = aString;
        _range = aRange;
    }

    return self;
}

@end
