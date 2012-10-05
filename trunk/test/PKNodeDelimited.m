//
//  PKNodeDelimited.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/5/12.
//
//

#import "PKNodeDelimited.h"

@implementation PKNodeDelimited

- (NSInteger)type {
    return PKNodeTypeDelimited;
}


- (void)visit:(PKParserVisitor *)v {
    [v visitDelimited:self];
}

@end
