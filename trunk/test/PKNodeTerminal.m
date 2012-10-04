//
//  PKNodeTerminal.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/4/12.
//
//

#import "PKNodeTerminal.h"

@implementation PKNodeTerminal

- (NSInteger)type {
    return PKNodeTypeTerminal;
}


- (void)visit:(PKParserVisitor *)v {
    [v visitTerminal:self];
}

@end
