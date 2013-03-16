//
//  PKNode.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/4/12.
//
//

#import "PKBaseNode.h"

@implementation PKBaseNode

+ (id)nodeWithToken:(PKToken *)tok {
    return [[[self alloc] initWithToken:tok] autorelease];
}


- (id)copyWithZone:(NSZone *)zone {
    PKBaseNode *that = (PKBaseNode *)[super copyWithZone:zone];
    that->_discard = _discard;
    return that;
}


- (BOOL)isEqual:(id)obj {
    if (![super isEqual:obj]) {
        return NO;
    }

    PKBaseNode *that = (PKBaseNode *)obj;
    
    if (_discard != that->_discard) {
        return NO;
    }
    
    return YES;
}


- (void)visit:(id <PKNodeVisitor>)v; {
    NSAssert2(0, @"%s is an abastract method. Must be overridden in %@", __PRETTY_FUNCTION__, NSStringFromClass([self class]));
}

@end
