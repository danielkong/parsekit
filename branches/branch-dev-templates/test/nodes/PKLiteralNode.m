//
//  PKNodeLiteral.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/7/12.
//
//

#import "PKLiteralNode.h"
#import <ParseKit/PKSpecificChar.h>
#import <ParseKit/PKCaseInsensitiveLiteral.h>

@implementation PKLiteralNode

- (void)dealloc {
    self.tokenUserType = nil;
    [super dealloc];
}


- (NSUInteger)type {
    return PKNodeTypeLiteral;
}


- (void)visit:(id <PKNodeVisitor>)v; {
    [v visitLiteral:self];
}


- (Class)parserClass {
    if (_wantsCharacters) {
        return [PKSpecificChar class];
    } else {
        return [PKCaseInsensitiveLiteral class];
    }
}

@end
