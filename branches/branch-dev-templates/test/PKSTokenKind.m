//
//  PKSTokenKind.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 3/27/13.
//
//

#import "PKSTokenKind.h"

@implementation PKSTokenKind

+ (PKSTokenKind *)tokenKindWithStringValue:(NSString *)s name:(NSString *)name {
    PKSTokenKind *kind = [[[PKSTokenKind alloc] init] autorelease];
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
