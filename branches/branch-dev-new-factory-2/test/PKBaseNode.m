//
//  PKNode.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/4/12.
//
//

#import "PKBaseNode.h"

@implementation PKBaseNode

- (void)visit:(PKNodeVisitor *)v {
    NSAssert2(0, @"%s is an abastract method. Must be overridden in %@", __PRETTY_FUNCTION__, NSStringFromClass([self class]));
}

@end
