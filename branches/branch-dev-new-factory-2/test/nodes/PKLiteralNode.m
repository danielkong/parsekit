//
//  PKNodeLiteral.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/7/12.
//
//

#import "PKLiteralNode.h"

@implementation PKLiteralNode

- (NSUInteger)type {
    return PKNodeTypeLiteral;
}


- (NSString *)name {
    return [NSString stringWithFormat:@"'%@'", self.parserName];
}


- (void)visit:(id <PKNodeVisitor>)v; {
    [v visitLiteral:self];
}

@end
