//
//  PKNodeDelimited.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/5/12.
//
//

#import "PKDelimitedNode.h"

@implementation PKDelimitedNode

- (void)dealloc {
    self.startMarker = nil;
    self.endMarker = nil;
    [super dealloc];
}


- (int)type {
    return PKNodeTypeDelimited;
}


- (void)visit:(PKNodeVisitor *)v {
    [v visitDelimited:self];
}

@end
