//
//  Created by Benoît on 21/01/14.
//  Copyright (c) 2014 Pragmatic Code. All rights reserved.
//

#define BBLogModuleName @"[BBUncrustifyPlugin]"
#define BBLogRelease(fmt, ...) NSLog((BBLogModuleName @" " fmt), ##__VA_ARGS__)
#define BBLogReleaseWithLocation(fmt, ...) NSLog((BBLogModuleName @" (%s[Line %d]) " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
