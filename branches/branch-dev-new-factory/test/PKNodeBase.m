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


- (void)visit:(id <PKNodeVisitor>)v; {
    NSAssert2(0, @"%s is an abastract method. Must be overridden in %@", __PRETTY_FUNCTION__, NSStringFromClass([self class]));
}


- (NSString *)name {
    if (_parserName) {
        return _parserName;
    } else {
        return [super name];
    }
}

@end
