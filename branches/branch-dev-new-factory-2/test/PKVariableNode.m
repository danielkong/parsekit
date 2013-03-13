//
//  PKNodeVariable.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/4/12.
//
//

#import "PKVariableNode.h"

@implementation PKVariableNode

- (void)dealloc {
    self.callbackName = nil;
    [super dealloc];
}


- (int)type {
    return PKNodeTypeVariable;
}


- (void)visit:(PKNodeVisitor *)v {
    [v visitVariable:self];
}

@end
