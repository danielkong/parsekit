//
//  PKSMethod.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 3/26/13.
//
//

#import "PKSMethod.h"

@implementation PKSMethod

- (void)dealloc {
    self.name = nil;
    self.children = nil;
    [super dealloc];
}


- (void)addChild:(PKSMethod *)m {
    if (!_children) {
        self.children = [NSMutableArray array];
    }
    [_children addObject:m];
}

@end
