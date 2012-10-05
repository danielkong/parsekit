//
//  PKNodeCollection.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/4/12.
//
//

#import "PKNodeCollection.h"

@implementation PKNodeCollection

- (int)type {
    return PKNodeTypeCollection;
}


- (void)visit:(PKParserVisitor *)v {
    [v visitCollection:self];
}

@end
