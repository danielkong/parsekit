//
//  PKBaseVisitor.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 3/16/13.
//
//

#import "PKBaseVisitor.h"
#import "PKScope.h"
#import "PKSymbolTable.h"
#import "PKVariableSymbol.h"

#import "PKBaseNode.h"
#import "PKRootNode.h"
#import "PKDefinitionNode.h"
#import "PKReferenceNode.h"
#import "PKConstantNode.h"
#import "PKDelimitedNode.h"
#import "PKLiteralNode.h"
#import "PKPatternNode.h"
#import "PKWhitespaceNode.h"
#import "PKCompositeNode.h"
#import "PKCollectionNode.h"
#import "PKCardinalNode.h"
#import "PKOptionalNode.h"
#import "PKMultipleNode.h"

@implementation PKBaseVisitor

- (id)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}


- (void)dealloc {
    self.rootNode = nil;
    self.symbolTable = nil;
    self.currentScope = nil;
    [super dealloc];
}


- (void)recurse:(PKBaseNode *)node {
    for (PKBaseNode *child in node.children) {
        [child visit:self];
    }
}


- (void)visitRoot:(PKRootNode *)node {
    //NSLog(@"%s %@", __PRETTY_FUNCTION__, node);

}


- (void)visitDefinition:(PKDefinitionNode *)node {
    //NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
}


- (void)visitReference:(PKReferenceNode *)node {
    //NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
}


- (void)visitComposite:(PKCompositeNode *)node {
    //NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
}


- (void)visitCollection:(PKCollectionNode *)node {
    //NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
}


- (void)visitCardinal:(PKCardinalNode *)node {
    //NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
}


- (void)visitOptional:(PKOptionalNode *)node {
    //NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
}


- (void)visitMultiple:(PKMultipleNode *)node {
    //NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
}


- (void)visitConstant:(PKConstantNode *)node {
    //NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
}


- (void)visitLiteral:(PKLiteralNode *)node {
    //NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
}


- (void)visitDelimited:(PKDelimitedNode *)node {
    //NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
}


- (void)visitPattern:(PKPatternNode *)node {
    //NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
}


- (void)visitWhitespace:(PKWhitespaceNode *)node {
    //NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
}

@end
