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


- (id)copyWithZone:(NSZone *)zone {
    PKDelimitedNode *that = (PKDelimitedNode *)[super copyWithZone:zone];
    that->_startMarker = [_startMarker retain];
    that->_endMarker = [_endMarker retain];
    return that;
}


- (BOOL)isEqual:(id)obj {
    if (![super isEqual:obj]) {
        return NO;
    }
    
    PKDelimitedNode *that = (PKDelimitedNode *)obj;
    
    if (![_startMarker isEqual:that->_startMarker]) {
        return NO;
    }
    
    if (![_endMarker isEqual:that->_endMarker]) {
        return NO;
    }
    
    return YES;
}


- (NSUInteger)type {
    return PKNodeTypeDelimited;
}


- (void)visit:(id <PKNodeVisitor>)v; {
    [v visitDelimited:self];
}

@end
