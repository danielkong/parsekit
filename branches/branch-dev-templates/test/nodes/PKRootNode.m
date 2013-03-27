//
//  PKRootNode.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/4/12.
//
//

#import "PKRootNode.h"

@implementation PKRootNode

- (void)dealloc {
    self.tokenUserTypes = nil;
    [super dealloc];
}


- (NSUInteger)type {
    return PKNodeTypeRoot;
}


- (void)visit:(id <PKNodeVisitor>)v {
    [v visitRoot:self];
}

@end
