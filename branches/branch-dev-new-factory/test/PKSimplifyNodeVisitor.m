//
//  PKSimplifyNodeVisitor.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/7/12.
//
//

#import "PKSimplifyNodeVisitor.h"
#import "PKNodeBase.h"
#import "PKNodeVariable.h"
#import "PKNodeConstant.h"
#import "PKNodeLiteral.h"
#import "PKNodePattern.h"
#import "PKNodeComposite.h"
#import "PKNodeCollection.h"
#import "PKNodeCardinal.h"
#import "PKNodeOptional.h"
#import "PKNodeMultiple.h"

@implementation PKSimplifyNodeVisitor

- (void)dealloc {
    self.currentParent = nil;
    [super dealloc];
}


- (void)visitVariable:(PKNodeVariable *)node {
    
    NSUInteger c = [node.children count];
    
    if (1 == c) {
        PKNodeBase *child = [node.children objectAtIndex:0];
        
        NSUInteger idx = [_currentParent.children indexOfObject:node];
        //self.currentParent = node;
        [child visit:self];
        [_currentParent.children replaceObjectAtIndex:idx withObject:child];
    } else {
        for (PKNodeBase *child in node.children) {
            self.currentParent = node;
            [child visit:self];
        }
    }
}


- (void)visitConstant:(PKNodeConstant *)node {

}


- (void)visitLiteral:(PKNodeLiteral *)node {

}


- (void)visitDelimited:(PKNodeDelimited *)node {

}


- (void)visitPattern:(PKNodePattern *)node {

}


- (void)visitComposite:(PKNodeComposite *)node {
    for (PKNodeBase *child in node.children) {
        self.currentParent = node;
        [child visit:self];
    }
}


- (void)visitCollection:(PKNodeCollection *)node {
    for (PKNodeBase *child in node.children) {
        self.currentParent = node;
        [child visit:self];
    }
}


- (void)visitCardinal:(PKNodeCardinal *)node {
    for (PKNodeBase *child in node.children) {
        self.currentParent = node;
        [child visit:self];
    }
}


- (void)visitOptional:(PKNodeOptional *)node {
    for (PKNodeBase *child in node.children) {
        self.currentParent = node;
        [child visit:self];
    }
}


- (void)visitMultiple:(PKNodeMultiple *)node {
    for (PKNodeBase *child in node.children) {
        self.currentParent = node;
        [child visit:self];
    }
}

@end
