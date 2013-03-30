//
//  PKSTokenKindDescriptor.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 3/27/13.
//
//

#import "PKSTokenKindDescriptor.h"

@implementation PKSTokenKindDescriptor

+ (PKSTokenKindDescriptor *)descriptorWithStringValue:(NSString *)s name:(NSString *)name {
    PKSTokenKindDescriptor *kind = [[[PKSTokenKindDescriptor alloc] init] autorelease];
    kind.stringValue = s;
    kind.name = name;
    return kind;
}


- (void)dealloc {
    self.stringValue = nil;
    self.name = nil;
    [super dealloc];
}


- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ %p '%@'>", [self class], self, _stringValue];
}


- (BOOL)isEqual:(id)obj {
    if (![obj isMemberOfClass:[self class]]) {
        return NO;
    }
    
    PKSTokenKindDescriptor *that = (PKSTokenKindDescriptor *)obj;
    
    if (![_stringValue isEqualToString:that->_stringValue]) {
        return NO;
    }
    
    NSAssert([_name isEqualToString:that->_name], @"if the stringValues match, so should the names");
    
    return YES;
}

@end
