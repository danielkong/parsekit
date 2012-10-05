//
//  PKNodeVariable.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/4/12.
//
//

#import "PKNodeVariable.h"

@implementation PKNodeVariable

- (NSInteger)type {
    return PKNodeTypeVariable;
}


- (void)visit:(PKParserVisitor *)v {
    [v visitVariable:self];
}

@end
