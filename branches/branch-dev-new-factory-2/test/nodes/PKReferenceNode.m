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


- (void)visit:(id <PKNodeVisitor>)v; {
    [v visitReference:self];
}

@end
