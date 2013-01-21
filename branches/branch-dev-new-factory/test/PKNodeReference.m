//
//  PKNodeReference.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/4/12.
//
//

#import "PKNodeReference.h"

@implementation PKNodeReference

- (int)type {
    return PKNodeTypeReference;
}


- (void)visit:(id <PKNodeVisitor>)v; {
    [v visitReference:self];
}

@end
