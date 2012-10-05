//
//  PKNodeOptional.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/5/12.
//
//

#import "PKNodeOptional.h"

@implementation PKNodeOptional

- (NSInteger)type {
    return PKNodeTypeOptional;
}


- (void)visit:(PKParserVisitor *)v {
    [v visitOptional:self];
}

@end
