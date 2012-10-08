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
#import "PKNodeWhitespace.h"
#import "PKNodeComposite.h"
#import "PKNodeCollection.h"
#import "PKNodeCardinal.h"
#import "PKNodeOptional.h"
#import "PKNodeMultiple.h"

@implementation PKSimplifyNodeVisitor

- (void)dealloc {
    self.rootNode = nil;
    self.currentParent = nil;
    [super dealloc];
}


- (void)visitVariable:(PKNodeVariable *)node {
    //NSLog(@"%s %@", __PRETTY_FUNCTION__, node);

    BOOL hasOnlyChild = 1 == [node.children count];
    
    BOOL isRoot = NO; // TODO remove rootNode check if remove "@start"
    PKNodeBase *firstChild = nil;
    BOOL isChildTerminal = NO;

    if (hasOnlyChild) {
        isRoot = node == _rootNode;
        firstChild = [node.children objectAtIndex:0];
        isChildTerminal = PKNodeTypeConstant == firstChild.type || PKNodeTypeLiteral == firstChild.type;
    }
    
    if (hasOnlyChild && !isRoot && isChildTerminal) {
        //NSLog(@"%@", firstChild);
        
        // find index of current Node in parent's children
        NSUInteger idx = [_currentParent.children indexOfObject:node];
        
        // visit child
        [firstChild visit:self];
        
        // transfer name to child name
        firstChild.token = node.token;
        
        // replace current node with firstChild in parent's children
        NSMutableArray *sibs = [[_currentParent.children mutableCopy] autorelease];
        [sibs replaceObjectAtIndex:idx withObject:firstChild];
        _currentParent.children = sibs;
        
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


- (void)visitWhitespace:(PKNodeWhitespace *)node {
    
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


#pragma mark -
#pragma mark Properties

- (void)setRootNode:(PKNodeBase *)node {
    if (node != _rootNode) {
        [_rootNode release];
        _rootNode = [node retain];
        
        self.currentParent = _rootNode;
    }
}

@end
