//
//  PKNodeDefinition.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/4/12.
//
//

#import "PKDefinitionNode.h"
#import <ParseKit/PKToken.h>

@implementation PKDefinitionNode

- (NSUInteger)type {
    return PKNodeTypeDefinition;
}


- (NSString *)name {
    NSString *prefix = nil;
    
    NSString *pname = self.token.stringValue;
    NSAssert([pname length], @"");

    if ('@' == [pname characterAtIndex:0]) {
        NSAssert([@"@start" isEqualToString:pname], @"");
        
        prefix = @"";
    } else {
        prefix = @"$";
    }
    
    NSString *str = [NSString stringWithFormat:@"%@%@", prefix, pname];
    return str;
}


- (void)visit:(id <PKNodeVisitor>)v; {
    [v visitDefinition:self];
}

@end
