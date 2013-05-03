//
//  PKTreeNode.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 5/1/13.
//
//

#import "PKTreeNode.h"
#import <ParseKit/PKToken.h>

@implementation PKTreeNode

- (NSUInteger)type {
    return PKNodeTypeAction;
}


- (void)visit:(id <PKNodeVisitor>)v; {
    [v visitTree:self];
}


- (BOOL)isTerminal {
    return NO;
}


- (NSString *)childrenStartDelimiter {
    if ([self.token.stringValue isEqualToString:@"->"]) {
        return @"";
    } else {
        return @"^(";
    }
}


- (NSString *)childrenEndDelimiter {
    if ([self.token.stringValue isEqualToString:@"->"]) {
        return @"";
    } else {
        return @")";
    }
}

@end
