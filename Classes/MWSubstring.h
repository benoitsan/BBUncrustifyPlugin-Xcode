//
//  MWSubstring.h
//  BBUncrustifyPlugin
//
//  Created by Daniel Ericsson on 2013-03-24.
//

#import <Foundation/Foundation.h>

@interface MWSubstring : NSObject

@property (nonatomic, readwrite, copy) NSString *string;
@property (nonatomic, readwrite, assign) NSRange range;

- (id)initWithString:(NSString *)aString rangeValue:(NSRange)aRange;

@end
