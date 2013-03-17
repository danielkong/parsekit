//
//  PKReferencePhaseVisitor.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 3/16/13.
//
//

#import "PKResolutionPhaseVisitor.h"

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

@interface PKResolutionPhaseVisitor ()

@end

@implementation PKResolutionPhaseVisitor

- (id)init {
    self = [super init];
    if (self) {

    }
    return self;
}


- (void)dealloc {

    [super dealloc];
}


- (void)visitRoot:(PKRootNode *)node {
    NSParameterAssert(node);
//    NSAssert(self.symbolTable, @"");
//
//    self.currentScope = self.symbolTable;
    
    [self recurse:node];

//    self.currentScope = nil;
}


- (void)visitDefinition:(PKDefinitionNode *)node {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
    // resolve type
    NSAssert(1 == [node.children count], @"");
    PKBaseNode *child = node.children[0];
    
    Class cls = child.parserClass;
    NSAssert(cls, @"");
    NSString *clsName = NSStringFromClass(cls);
    NSAssert([clsName length] > 2, @"");
//    NSString *typeName = [clsName substringFromIndex:2];
    
//    PKBuiltInTypeSymbol *typeSym = (id)[self.currentScope resolve:typeName];
//    NSAssert(typeSym, @"");
//
//    PKBaseSymbol *sym = node.symbol;
//    NSAssert(sym, @"");
//    
//    sym.type = typeSym;
    
    [self recurse:node];
}


- (void)visitReference:(PKReferenceNode *)node {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
//    NSString *name = node.token.stringValue;
//    PKBaseSymbol *sym = [node.scope resolve:name];
//    node.symbol = sym;
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
