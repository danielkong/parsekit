//
//  PKNodeWhitespace.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/8/12.
//
//

#import "PKWhitespaceNode.h"

@implementation PKWhitespaceNode

- (NSUInteger)type {
    return PKNodeTypeWhitespace;
}


- (void)visit:(id <PKNodeVisitor>)v; {
    [v visitWhitespace:self];
}

@end
