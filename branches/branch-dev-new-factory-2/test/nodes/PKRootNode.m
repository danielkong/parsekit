//
//  PKRootNode.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/4/12.
//
//

#import "PKRootNode.h"

@implementation PKRootNode

- (void)visit:(id <PKNodeVisitor>)v {
    [v visitRoot:self];
}

@end
