//
//  PKNodeWhitespace.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/8/12.
//
//

#import "PKNodeWhitespace.h"

@implementation PKNodeWhitespace

- (int)type {
    return PKNodeTypeWhitespace;
}


- (void)visit:(id <PKNodeVisitor>)v; {
    [v visitWhitespace:self];
}
@end
