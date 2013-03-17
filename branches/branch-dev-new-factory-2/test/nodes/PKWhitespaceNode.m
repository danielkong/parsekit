//
//  PKNodeWhitespace.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/8/12.
//
//

#import "PKWhitespaceNode.h"
#import <ParseKit/PKWhitespace.h>

@implementation PKWhitespaceNode

- (NSUInteger)type {
    return PKNodeTypeWhitespace;
}


- (void)visit:(id <PKNodeVisitor>)v; {
    [v visitWhitespace:self];
}


- (Class)parserClass {
    return [PKWhitespace class];
}

@end
