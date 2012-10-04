//
//  PKNodePattern.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/4/12.
//
//

#import "PKNodePattern.h"

@implementation PKNodePattern

- (NSInteger)type {
    return PKNodeTypePattern;
}


- (void)visit:(PKParserVisitor *)v {
    [v visitPattern:self];
}

@end
