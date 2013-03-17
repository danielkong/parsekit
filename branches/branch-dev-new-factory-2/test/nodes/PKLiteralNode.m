//
//  PKNodeLiteral.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/7/12.
//
//

#import "PKLiteralNode.h"
#import <ParseKit/PKLiteral.h>

@implementation PKLiteralNode

- (NSUInteger)type {
    return PKNodeTypeLiteral;
}


- (void)visit:(id <PKNodeVisitor>)v; {
    [v visitLiteral:self];
}


- (Class)parserClass {
    return [PKLiteral class];
}

@end
