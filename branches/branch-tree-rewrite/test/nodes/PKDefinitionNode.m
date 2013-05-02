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

- (void)dealloc {
    self.callbackName = nil;
    self.rewriteNode = nil;
    [super dealloc];
}


- (id)copyWithZone:(NSZone *)zone {
    PKDefinitionNode *that = (PKDefinitionNode *)[super copyWithZone:zone];
    that->_callbackName = [_callbackName copyWithZone:zone];
    that->_rewriteNode = [_rewriteNode copyWithZone:zone];
    return that;
}


- (BOOL)isEqual:(id)obj {
    if (![super isEqual:obj]) {
        return NO;
    }
    
    PKDefinitionNode *that = (PKDefinitionNode *)obj;
    
    if (![_callbackName isEqual:that->_callbackName]) {
        return NO;
    }
    
    if (![_rewriteNode isEqual:that->_rewriteNode]) {
        return NO;
    }
    
    return YES;
}


- (NSString *)treeDescription {
    NSString *res = [super treeDescription];
    
    if (_rewriteNode) {
        res = [NSString stringWithFormat:@"%@ %@", res, [_rewriteNode treeDescription]];
    }
    
    return res;
}


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
    
    if (_callbackName) {
        str = [NSString stringWithFormat:@"%@(%@)", str, _callbackName];
    }
    
    return str;
}


- (void)visit:(id <PKNodeVisitor>)v; {
    [v visitDefinition:self];
}


- (BOOL)isTerminal {
    NSAssert2(0, @"%s is an abastract method. Must be overridden in %@", __PRETTY_FUNCTION__, NSStringFromClass([self class]));
    return NO;
}

@end
