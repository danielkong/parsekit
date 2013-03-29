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

@end
