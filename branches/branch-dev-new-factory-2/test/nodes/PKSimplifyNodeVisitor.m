//
//  PKSimplifyNodeVisitor.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/7/12.
//
//

#import "PKSimplifyNodeVisitor.h"
#import "PKBaseNode.h"
#import "PKRootNode.h"
#import "PKReferenceNode.h"
#import "PKConstantNode.h"
#import "PKLiteralNode.h"
#import "PKPatternNode.h"
#import "PKWhitespaceNode.h"
#import "PKCompositeNode.h"
#import "PKCollectionNode.h"
#import "PKCardinalNode.h"
#import "PKOptionalNode.h"
#import "PKMultipleNode.h"

@implementation PKSimplifyNodeVisitor

- (void)dealloc {
    self.rootNode = nil;
    self.currentParent = nil;
    [super dealloc];
}


- (void)visitRoot:(PKRootNode *)node {
    
}


- (void)visitDefinition:(PKDefinitionNode *)node {
    NSAssert(0, @"");
}


- (void)visitReference:(PKReferenceNode *)node {
    //NSLog(@"%s %@", __PRETTY_FUNCTION__, node);

    BOOL hasOnlyChild = 1 == [node.children count];
    
    BOOL isRoot = NO; // TODO remove rootNode check if remove "@start"
    PKBaseNode *firstChild = nil;
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
        for (PKBaseNode *child in node.children) {
            self.currentParent = node;
            [child visit:self];
        }
    }
}


- (void)visitConstant:(PKConstantNode *)node {

}


- (void)visitLiteral:(PKLiteralNode *)node {

}


- (void)visitDelimited:(PKDelimitedNode *)node {

}


- (void)visitPattern:(PKPatternNode *)node {
    
}


- (void)visitWhitespace:(PKWhitespaceNode *)node {
    
}


- (void)visitComposite:(PKCompositeNode *)node {
    for (PKBaseNode *child in node.children) {
        self.currentParent = node;
        [child visit:self];
    }
}


- (void)visitCollection:(PKCollectionNode *)node {
    for (PKBaseNode *child in node.children) {
        self.currentParent = node;
        [child visit:self];
    }
}


- (void)visitCardinal:(PKCardinalNode *)node {
    for (PKBaseNode *child in node.children) {
        self.currentParent = node;
        [child visit:self];
    }
}


- (void)visitOptional:(PKOptionalNode *)node {
    for (PKBaseNode *child in node.children) {
        self.currentParent = node;
        [child visit:self];
    }
}


- (void)visitMultiple:(PKMultipleNode *)node {
    for (PKBaseNode *child in node.children) {
        self.currentParent = node;
        [child visit:self];
    }
}


#pragma mark -
#pragma mark Properties

- (void)setRootNode:(PKBaseNode *)node {
    if (node != _rootNode) {
        [_rootNode release];
        _rootNode = [node retain];
        
        self.currentParent = _rootNode;
    }
}

@end
