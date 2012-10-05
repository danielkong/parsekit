//
//  PKNodeMultiple.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/5/12.
//
//

#import "PKNodeMultiple.h"

@implementation PKNodeMultiple

- (NSInteger)type {
    return PKNodeTypeMultiple;
}


- (void)visit:(PKParserVisitor *)v {
    [v visitMultiple:self];
}

@end
