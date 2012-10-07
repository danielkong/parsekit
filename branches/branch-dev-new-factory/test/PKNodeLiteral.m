//
//  PKNodeLiteral.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/7/12.
//
//

#import "PKNodeLiteral.h"

@implementation PKNodeLiteral

- (int)type {
    return PKNodeTypeLiteral;
}


- (void)visit:(id <PKNodeVisitor>)v; {
    [v visitLiteral:self];
}

@end
