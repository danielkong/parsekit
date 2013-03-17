//
//  PKNodeReference.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/4/12.
//
//

#import "PKReferenceNode.h"
#import "PKScope.h"
#import <ParseKit/PKToken.h>
#import <ParseKit/PKSequence.h>

@implementation PKReferenceNode

- (void)dealloc {
    self.scope = nil;
    [super dealloc];
}


- (id)copyWithZone:(NSZone *)zone {
    PKReferenceNode *that = (PKReferenceNode *)[super copyWithZone:zone];
    that->_scope = _scope; // don't copy, just ref
    return that;
}


- (BOOL)isEqual:(id)obj {
    if (![super isEqual:obj]) {
        return NO;
    }
    
    PKReferenceNode *that = (PKReferenceNode *)obj;
    
    if (![_scope isEqual:that->_scope]) {
        return NO;
    }
    
    return YES;
}


- (NSUInteger)type {
    return PKNodeTypeReference;
}


- (NSString *)name {
    NSString *str = [NSString stringWithFormat:@"#%@", self.token.stringValue];
    return str;
}


- (void)visit:(id <PKNodeVisitor>)v; {
    [v visitReference:self];
}


- (Class)parserClass {
    return [PKSequence class];
}

@end
