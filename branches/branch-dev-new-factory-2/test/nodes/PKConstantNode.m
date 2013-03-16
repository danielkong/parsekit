//
//  PKNodeTerminal.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/4/12.
//
//

#import "PKConstantNode.h"
#import <ParseKit/PKToken.h>

@implementation PKConstantNode

- (void)dealloc {
    self.literal = nil;
    [super dealloc];
}


- (NSUInteger)type {
    return PKNodeTypeConstant;
}


- (NSString *)name {
    NSString *res = nil;
    
    if (_literal) {
        res = [NSString stringWithFormat:@"%@('%@')", self.token.stringValue, _literal];
    } else {
        res = [super name];
    }

    return  res;
}

- (void)visit:(id <PKNodeVisitor>)v; {
    [v visitConstant:self];
}

@end
