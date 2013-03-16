//
//  PKNodeReference.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/4/12.
//
//

#import "PKReferenceNode.h"

@implementation PKReferenceNode

- (NSUInteger)type {
    return PKNodeTypeReference;
}


- (NSString *)name {
    NSString *str = [NSString stringWithFormat:@"%@%@", self.token.stringValue, self.parserName];
    return str;
}


- (void)visit:(id <PKNodeVisitor>)v; {
    [v visitReference:self];
}

@end
