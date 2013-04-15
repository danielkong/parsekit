//
//  PKSTokenKindDescriptor.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 3/27/13.
//
//

#import "PKSTokenKindDescriptor.h"
#import "PKSParser.h"

static NSMutableDictionary *sCache = nil;

@implementation PKSTokenKindDescriptor

+ (void)initialize {
    if ([PKSTokenKindDescriptor class] == self) {
        sCache = [[NSMutableDictionary alloc] init];
    }
}

+ (PKSTokenKindDescriptor *)descriptorWithStringValue:(NSString *)s name:(NSString *)name {
    PKSTokenKindDescriptor *kind = sCache[name];
    
    if (!kind) {
        kind = [[[PKSTokenKindDescriptor alloc] init] autorelease];
        kind.stringValue = s;
        kind.name = name;
        
        sCache[name] = kind;
    }
    
    return kind;
}


+ (PKSTokenKindDescriptor *)anyDescriptor {
    return [PKSTokenKindDescriptor descriptorWithStringValue:@"TOKEN_KIND_BUILTIN_ANY" name:@"TOKEN_KIND_BUILTIN_ANY"];
}


- (void)dealloc {
    self.stringValue = nil;
    self.name = nil;
    [super dealloc];
}


- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ %p '%@' %@>", [self class], self, _stringValue, _name];
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
