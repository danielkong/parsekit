//
//  PKNodeTerminal.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/4/12.
//
//

#import "PKConstantNode.h"

@implementation PKConstantNode

- (NSUInteger)type {
    return PKNodeTypeConstant;
}


- (void)visit:(id <PKNodeVisitor>)v; {
    [v visitConstant:self];
}

@end
