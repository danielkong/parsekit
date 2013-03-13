//
//  PKNodeCardinal.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/6/12.
//
//

#import "PKCardinalNode.h"

@implementation PKCardinalNode

- (int)type {
    return PKNodeTypeCardinal;
}


- (void)visit:(PKNodeVisitor *)v {
    [v visitCardinal:self];
}

@end
