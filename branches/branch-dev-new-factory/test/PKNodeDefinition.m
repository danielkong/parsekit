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

@end
