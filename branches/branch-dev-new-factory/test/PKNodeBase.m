//
//  PKNode.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/4/12.
//
//

#import "PKNodeBase.h"

@implementation PKNodeBase

- (void)dealloc {
    self.parserName = nil;
    self.callbackName = nil;
    [super dealloc];
}


- (id)copyWithZone:(NSZone *)zone {
    PKNodeBase *that = (PKNodeBase *)[super copyWithZone:zone];
    that->_parserName = [_parserName retain];
    that->_callbackName = [_callbackName retain];
    return that;
}


- (BOOL)isEqual:(id)obj {
    if (![super isEqual:obj]) {
        return NO;
    }

    PKNodeBase *that = (PKNodeBase *)obj;
    
    if (![_parserName isEqual:that->_parserName]) {
        return NO;
    }
    
    if (![_callbackName isEqual:that->_callbackName]) {
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
