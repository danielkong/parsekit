//
//  PKNodeDefinition.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/4/12.
//
//

#import "PKNodeDefinition.h"

@implementation PKNodeDefinition

- (int)type {
    return PKNodeTypeDefinition;
}


- (void)visit:(id <PKNodeVisitor>)v; {
    [v visitDefinition:self];
}


- (NSString *)fullTreeDescription:(NSDictionary *)symbolTab {
    NSString *name = [self name];

    if (![self.children count]) {
        return name;
    }
    
    NSMutableString *ms = [NSMutableString string];
    
    if (![self isNil]) {
        [ms appendFormat:@"(%@ ", name];
    }
    
    NSInteger i = 0;
    for (PKAST *child in self.children) {
        NSAssert(child != self, @"");
        if (i++) {
            [ms appendFormat:@" %@", [child fullTreeDescription:symbolTab]];
        } else {
            [ms appendFormat:@"%@", [child fullTreeDescription:symbolTab]];
        }
    }
    
    if (![self isNil]) {
        [ms appendString:@")"];
    }
    
    return [[ms copy] autorelease];
}

@end
