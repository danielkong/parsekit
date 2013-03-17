//
//  PKReferencePhaseVisitor.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 3/16/13.
//
//

#import "PKResolutionPhaseVisitor.h"
#import <ParseKit/ParseKit.h>

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
    self.currentParser = nil;
    [super dealloc];
}


//- (void)recurse:(PKBaseNode *)node {
//
//    PKParser *p = node.parser
//    for (PKBaseNode *child in node.children) {
//        self.currentParser = node;
//        [child visit:self];
//    }
//}



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
//    NSAssert(1 == [node.children count], @"");
//    PKBaseNode *child = node.children[0];
//    
//    Class cls = child.parserClass;
//    NSAssert(cls, @"");
//    NSString *clsName = NSStringFromClass(cls);
//    NSAssert([clsName length] > 2, @"");
//    NSString *typeName = [clsName substringFromIndex:2];
    
//    PKBuiltInTypeSymbol *typeSym = (id)[self.currentScope resolve:typeName];
//    NSAssert(typeSym, @"");
//
//    PKBaseSymbol *sym = node.symbol;
//    NSAssert(sym, @"");
//    
//    sym.type = typeSym;
    
    NSString *name = node.token.stringValue;
    PKParser *p = self.symbolTable[name];
    NSAssert([p isKindOfClass:[PKParser class]], @"");
    
    if ([p isKindOfClass:[PKCompositeParser class]]) {
        PKCompositeParser *cp = (PKCompositeParser *)p;
        
        PKBaseNode *parent = node;
        
        NSAssert(1 == [parent.children count], @"");
        PKBaseNode *child = parent.children[0];
        if (PKNodeTypeReference != child.type) {
            parent = child;
        }

        for (PKBaseNode *child in parent.children) {
            self.currentParser = cp;
            [child visit:self];
        }
    }
}


- (void)visitReference:(PKReferenceNode *)node {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
    NSString *name = node.token.stringValue;
//    PKBaseSymbol *sym = [node.scope resolve:name];
//    node.symbol = sym;
    
    PKParser *p = self.symbolTable[name];
    NSAssert([p isKindOfClass:[PKParser class]], @"");
    
    [self.currentParser add:p];
    
}


- (void)visitComposite:(PKCompositeNode *)node {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
    [self recurse:node];
}


- (void)visitCollection:(PKCollectionNode *)node {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
    Class parserCls = [node parserClass];
    PKCollectionParser *cp = [[[parserCls alloc] init] autorelease];
    NSAssert([cp isKindOfClass:[PKCollectionParser class]], @"");
    
    [self.currentParser add:cp];
    
    PKCompositeParser *oldParser = _currentParser;

    for (PKBaseNode *child in node.children) {
        self.currentParser = cp;
        [child visit:self];
    }
    
    self.currentParser = oldParser;
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
    
    Class parserCls = [node parserClass];
    PKParser *p = nil;
    
    NSString *literal = node.literal;
    if (literal) {
        p = [[[parserCls alloc] initWithString:literal] autorelease];
    } else {
        p = [[[parserCls alloc] init] autorelease];
    }

    [self.currentParser add:p];
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
