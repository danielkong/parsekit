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


- (int)type {
    return PKNodeTypePattern;
}


- (void)visit:(PKNodeVisitor *)v {
    [v visitPattern:self];
}

@end
