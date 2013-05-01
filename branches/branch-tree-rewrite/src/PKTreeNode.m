//
//  PKTreeNode.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 5/1/13.
//
//

#import "PKTreeNode.h"

@implementation PKTreeNode

- (NSString *)treeDescription {
    if (![self.children count]) {
        return self.name;
    }
    
    NSMutableString *ms = [NSMutableString string];
    
    if (![self isNil]) {
        [ms appendFormat:@"^(%@ ", self.name];
    }
    
    NSInteger i = 0;
    for (PKAST *child in self.children) {
        NSString *fmt = 0 == i++ ? @"%@" : @" %@";
        [ms appendFormat:fmt, [child treeDescription]];
    }
    
    if (![self isNil]) {
        [ms appendString:@")"];
    }
    
    return [[ms copy] autorelease];
}

@end
