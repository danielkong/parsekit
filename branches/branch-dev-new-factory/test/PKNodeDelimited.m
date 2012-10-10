//
//  PKNodeDelimited.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/5/12.
//
//

#import "PKNodeDelimited.h"

@implementation PKNodeDelimited

- (void)dealloc {
    self.startMarker = nil;
    self.endMarker = nil;
    [super dealloc];
}


- (id)copyWithZone:(NSZone *)zone {
    PKNodeDelimited *that = (PKNodeDelimited *)[super copyWithZone:zone];
    that->_startMarker = [_startMarker retain];
    that->_endMarker = [_endMarker retain];
    return that;
}


- (BOOL)isEqual:(id)obj {
    if (![super isEqual:obj]) {
        return NO;
    }
    
    PKNodeDelimited *that = (PKNodeDelimited *)obj;
    
    if (![_startMarker isEqual:that->_startMarker]) {
        return NO;
    }
    
    if (![_endMarker isEqual:that->_endMarker]) {
        return NO;
    }
    
    return YES;
}


- (int)type {
    return PKNodeTypeDelimited;
}


- (void)visit:(id <PKNodeVisitor>)v; {
    [v visitDelimited:self];
}

@end
