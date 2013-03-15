//
//  PKNodePattern.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/4/12.
//
//

#import "PKPatternNode.h"

@implementation PKPatternNode

- (void)dealloc {
    self.string = nil;
    [super dealloc];
}


- (id)copyWithZone:(NSZone *)zone {
    PKPatternNode *that = (PKPatternNode *)[super copyWithZone:zone];
    that->_string = [_string retain];
    that->_options = _options;
    return that;
}


- (BOOL)isEqual:(id)obj {
    if (![super isEqual:obj]) {
        return NO;
    }
    
    PKPatternNode *that = (PKPatternNode *)obj;
    
    if (![_string isEqual:that->_string]) {
        return NO;
    }
    
    if (_options != that->_options) {
        return NO;
    }
    
    return YES;
}


- (NSUInteger)type {
    return PKNodeTypePattern;
}


- (void)visit:(id <PKNodeVisitor>)v; {
    [v visitPattern:self];
}

@end
