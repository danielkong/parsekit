//
//  PKNodeCollection.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/4/12.
//
//

#import "PKCollectionNode.h"

@implementation PKCollectionNode

- (int)type {
    return PKNodeTypeCollection;
}


- (void)visit:(id <PKNodeVisitor>)v; {
    [v visitCollection:self];
}

@end
