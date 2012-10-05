//
//  PKNodeTerminal.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/4/12.
//
//

#import "PKNodeConstant.h"

@implementation PKNodeConstant

- (int)type {
    return PKNodeTypeConstant;
}


- (void)visit:(PKParserVisitor *)v {
    [v visitConstant:self];
}

@end
