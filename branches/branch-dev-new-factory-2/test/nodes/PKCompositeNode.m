//
//  PKCompositeNode.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/5/12.
//
//

#import "PKCompositeNode.h"
#import <ParseKit/ParseKit.h>

static NSDictionary *sClassTab = nil;

@implementation PKCompositeNode

+ (void)initialize {
    if ([PKCompositeNode class] == self) {
        sClassTab = [@{
            @"*" : [PKRepetition class],
            @"~" : [PKNegation class],
            @"-" : [PKDifference class],
        } retain];
    }
}


- (NSUInteger)type {
    return PKNodeTypeComposite;
}


- (void)visit:(id <PKNodeVisitor>)v; {
    [v visitComposite:self];
}


- (Class)parserClass {
    Class cls = Nil;
    
    NSString *typeName = self.token.stringValue;
    cls = sClassTab[typeName];
    
    return cls;
}

@end
