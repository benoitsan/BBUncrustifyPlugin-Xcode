//
//  Created by Benoît on 11/01/14.
//  Copyright (c) 2014 Pragmatic Code. All rights reserved.
//

#import "BBHyperLinkButtonCell.h"

@implementation BBHyperLinkButtonCell

- (NSAttributedString*)attributedTitle {
    
    NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithAttributedString:[super attributedTitle]];
    
    NSRange range = NSMakeRange(0, [attributedTitle length]);
    
    [attributedTitle addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSSingleUnderlineStyle] range:range];
    
    NSColor *textColor = (self.isHighlighted) ? [NSColor colorWithCalibratedRed:0.117 green:0.376 blue:0.998 alpha:1.000] : [NSColor blueColor];
    
    [attributedTitle addAttribute:NSForegroundColorAttributeName value:textColor range:range];
    
    return [attributedTitle copy];
}

@end
