//
//  PKDefinitionPhaseVisitor.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/4/12.
//
//

#import "PKDefinitionPhaseVisitor.h"
#import <ParseKit/PKCollectionParser.h>

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

@interface PKDefinitionPhaseVisitor ()
@end

@implementation PKDefinitionPhaseVisitor

- (void)visitRoot:(PKRootNode *)node {
//    self.symbolTable = [[[PKSymbolTable alloc] init] autorelease];
//    self.currentScope = self.symbolTable;
    
    self.symbolTable = [NSMutableDictionary dictionary];
    
    [self recurse:node];
    
//    self.currentScope = nil;
}


- (void)visitDefinition:(PKDefinitionNode *)node {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, node);

    NSString *name = node.token.stringValue;
//    PKVariableSymbol *sym = [PKVariableSymbol symbolWithName:name];
//    sym.scope = self.currentScope;
//    
//    sym.def = node;
//    node.symbol = sym;
//    
//    [self.currentScope define:sym];
    
    NSAssert([node.children count], @"");
    PKBaseNode *child = node.children[0];
    Class parserCls = [child parserClass];
    PKCollectionParser *p = [[[parserCls alloc] init] autorelease];
    
    self.symbolTable[name] = p;
    
    [self recurse:node];
}


- (void)visitReference:(PKReferenceNode *)node {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, node);

//    node.scope = self.currentScope;
}


- (void)visitComposite:(PKCompositeNode *)node {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, node);

    [self recurse:node];
}


- (void)visitCollection:(PKCollectionNode *)node {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, node);

    [self recurse:node];
}


- (void)visitCardinal:(PKCardinalNode *)node {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, node);

    [self recurse:node];
}


- (void)visitOptional:(PKOptionalNode *)node {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, node);

    [self recurse:node];
}


- (void)visitMultiple:(PKMultipleNode *)node {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, node);

    [self recurse:node];
}


- (void)visitConstant:(PKConstantNode *)node {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
}


- (void)visitLiteral:(PKLiteralNode *)node {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
}


- (void)visitDelimited:(PKDelimitedNode *)node {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
}


- (void)visitPattern:(PKPatternNode *)node {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
}


- (void)visitWhitespace:(PKWhitespaceNode *)node {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
}

@end
