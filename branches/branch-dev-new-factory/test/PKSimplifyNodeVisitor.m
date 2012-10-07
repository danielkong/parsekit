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

- (void)visitVariable:(PKNodeVariable *)node {
    for (PKNodeBase *child in node.children) {
        [child visit:self];
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
        [child visit:self];
    }
}


- (void)visitCollection:(PKNodeCollection *)node {
    for (PKNodeBase *child in node.children) {
        [child visit:self];
    }
}


- (void)visitCardinal:(PKNodeCardinal *)node {

}


- (void)visitOptional:(PKNodeOptional *)node {
    for (PKNodeBase *child in node.children) {
        [child visit:self];
    }
}


- (void)visitMultiple:(PKNodeMultiple *)node {
    for (PKNodeBase *child in node.children) {
        [child visit:self];
    }
}

@end
