//
//  PKGlobalScope.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 3/16/13.
//
//

#import "PKGlobalScope.h"

@interface PKGlobalScope ()
- (void)setUpBuiltInTypes;
@end

@implementation PKGlobalScope

- (id)init {
    self = [super init];
    if (self) {
        [self setUpBuiltInTypes];
    }
    return self;
}


- (NSString *)scopeName {
    return @"globals";
}


- (id <PKScope>)enclosingScope {
    return nil;
}


- (void)setUpBuiltInTypes {
    
}

@end
