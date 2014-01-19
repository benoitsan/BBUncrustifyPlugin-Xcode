//
//  NSDocument+BBUncrustify.h
//  Created by Dominik Pich on 1/17/14.
//

#import <Cocoa/Cocoa.h>

@interface NSDocument (BBUncrustify)

+ (BOOL)applyFormatOnSave;
+ (void)setApplyFormatOnSave:(BOOL)formatOnSave;

@end
