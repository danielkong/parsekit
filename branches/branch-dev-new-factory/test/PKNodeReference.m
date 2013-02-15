//
//  PKNodeReference.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/4/12.
//
//

#import "PKNodeReference.h"

@implementation PKNodeReference

- (int)type {
    return PKNodeTypeReference;
}


- (void)visit:(id <PKNodeVisitor>)v; {
    [v visitReference:self];
}


- (NSString *)fullTreeDescription:(NSDictionary *)symbolTab {
    NSString *name = self.parserName;
    PKNodeBase *parent = symbolTab[name];
    NSAssert(parent, @"");

    if (![parent.children count]) {
        return [parent name];
    }
    
    NSMutableString *ms = [NSMutableString string];
    
    if (![parent isNil]) {
        [ms appendFormat:@"(%@ ", [parent name]];
    }
    
    NSInteger i = 0;
    for (PKNodeBase *child in parent.children) {
        NSAssert(child != parent, @"");
        
        if (i++) {
            [ms appendFormat:@" %@", [child fullTreeDescription:symbolTab]];
        } else {
            [ms appendFormat:@"%@", [child fullTreeDescription:symbolTab]];
        }
    }
    
    if (![parent isNil]) {
        [ms appendString:@")"];
    }
    
    return [[ms copy] autorelease];
}

@end
