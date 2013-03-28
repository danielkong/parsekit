//
//  PKSTokenKind.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 3/27/13.
//
//

#import "PKSTokenKind.h"

@implementation PKSTokenKind

- (void)dealloc {
    self.stringValue = nil;
    [super dealloc];
}

@end
