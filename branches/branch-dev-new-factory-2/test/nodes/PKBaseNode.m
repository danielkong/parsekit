//
//  PKNode.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/4/12.
//
//

#import "PKBaseNode.h"

@implementation PKBaseNode

- (void)dealloc {
    self.parserName = nil;
    self.callbackName = nil;
    [super dealloc];
}


- (id)copyWithZone:(NSZone *)zone {
    PKBaseNode *that = (PKBaseNode *)[super copyWithZone:zone];
    that->_parserName = [_parserName copyWithZone:zone];
    that->_callbackName = [_callbackName copyWithZone:zone];
    that->_discard = _discard;
    return that;
}


- (BOOL)isEqual:(id)obj {
    if (![super isEqual:obj]) {
        return NO;
    }

    PKBaseNode *that = (PKBaseNode *)obj;
    
    if (![_parserName isEqual:that->_parserName]) {
        return NO;
    }
    
    if (![_callbackName isEqual:that->_callbackName]) {
        return NO;
    }
    
    if (_discard != that->_discard) {
        return NO;
    }
    
    return YES;
}


- (void)visit:(id <PKNodeVisitor>)v; {
    NSAssert2(0, @"%s is an abastract method. Must be overridden in %@", __PRETTY_FUNCTION__, NSStringFromClass([self class]));
}


- (NSString *)name {
    NSString *prefix = _parserName ? _parserName : @"";
    NSString *suffix = [super name];
    
    NSString *str = [NSString stringWithFormat:@"%@:%@", prefix, suffix];
    return str;
}

@end
