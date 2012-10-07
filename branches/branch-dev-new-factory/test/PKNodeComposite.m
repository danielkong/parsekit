//
//  PKNodeComposite.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/5/12.
//
//

#import "PKNodeComposite.h"

@implementation PKNodeComposite

- (int)type {
    return PKNodeTypeComposite;
}


- (void)visit:(id <PKNodeVisitor>)v; {
    [v visitComposite:self];
}

@end
