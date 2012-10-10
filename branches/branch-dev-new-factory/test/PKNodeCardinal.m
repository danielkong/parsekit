//
//  PKNodeCardinal.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/6/12.
//
//

#import "PKNodeCardinal.h"

@implementation PKNodeCardinal

- (id)copyWithZone:(NSZone *)zone {
    PKNodeCardinal *that = (PKNodeCardinal *)[super copyWithZone:zone];
    that->_rangeStart = _rangeStart;
    that->_rangeEnd = _rangeEnd;
    return that;
}


- (BOOL)isEqual:(id)obj {
    if (![super isEqual:obj]) {
        return NO;
    }
    
    PKNodeCardinal *that = (PKNodeCardinal *)obj;
    
    if (_rangeStart != that->_rangeStart) {
        return NO;
    }
    
    if (_rangeEnd != that->_rangeEnd) {
        return NO;
    }
    
    return YES;
}


- (int)type {
    return PKNodeTypeCardinal;
}


- (void)visit:(id <PKNodeVisitor>)v; {
    [v visitCardinal:self];
}

@end
