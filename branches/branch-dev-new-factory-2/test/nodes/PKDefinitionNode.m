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
    self.symbol = nil;
    [super dealloc];
}


- (id)copyWithZone:(NSZone *)zone {
    PKDefinitionNode *that = (PKDefinitionNode *)[super copyWithZone:zone];
    that->_callbackName = [_callbackName copyWithZone:zone];
    that->_symbol = [_symbol copyWithZone:zone];
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

    if (![_symbol isEqual:that->_symbol]) {
        return NO;
    }
    
    return YES;
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

@end
