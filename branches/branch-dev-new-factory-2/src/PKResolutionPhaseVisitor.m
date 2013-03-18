//
//  PKReferencePhaseVisitor.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 3/16/13.
//
//

#import "PKResolutionPhaseVisitor.h"
#import <ParseKit/ParseKit.h>
#import "NSString+ParseKitAdditions.h"

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
#import "PKAlternationNode.h"
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
//}


- (void)visitRoot:(PKRootNode *)node {
    NSParameterAssert(node);
    NSAssert(self.symbolTable, @"");

    [self recurse:node];
    
    self.symbolTable = nil;
}


- (void)visitDefinition:(PKDefinitionNode *)node {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
//    NSAssert(0, @"should not reach");
    
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
        
        // TODO remove
        switch (child.type) {
            case PKNodeTypeOptional: {
                [cp add:[PKEmpty empty]];
            } break;
            case PKNodeTypeMultiple: {
                NSAssert([cp isKindOfClass:[PKSequence class]], @"");
                PKSequence *seq = (PKSequence *)cp;
                NSAssert(1 == [seq.subparsers count], @"");
                PKParser *sub = seq.subparsers[0];
                [seq add:[PKRepetition repetitionWithSubparser:sub]];
            } break;
            default:
                break;
        }
            
    }
}


- (void)visitReference:(PKReferenceNode *)node {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
    NSString *name = node.token.stringValue;
    
    PKParser *p = self.symbolTable[name];
    NSAssert([p isKindOfClass:[PKParser class]], @"");
    
    [self.currentParser add:p];
    
}


- (void)visitComposite:(PKCompositeNode *)node {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
    Class parserCls = [node parserClass];
    PKCompositeParser *cp = [[[parserCls alloc] init] autorelease];
    NSAssert([cp isKindOfClass:[PKCompositeParser class]], @"");
    
    [self.currentParser add:cp];
    
    PKCompositeParser *oldParser = _currentParser;
    
    for (PKBaseNode *child in node.children) {
        self.currentParser = cp;
        [child visit:self];
    }
    
    self.currentParser = oldParser;
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


- (void)visitAlternation:(PKAlternationNode *)node {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
    [self visitCollection:node];
}


- (void)visitCardinal:(PKCardinalNode *)node {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
    [self recurse:node];

    // KEEP THIS FOR VISITOR!!!!!!!!!!!!!
    //    NSRange r = [[a pop] rangeValue];
    //
    //    p = [a pop];
    //    PKSequence *s = [PKSequence sequence];
    //
    //    NSInteger start = r.location;
    //    NSInteger end = r.length;
    //
    //    for (NSInteger i = 0; i < start; i++) {
    //        [s add:p];
    //    }
    //
    //    for (NSInteger i = start ; i < end; i++) {
    //        [s add:[self zeroOrOne:p]];
    //    }
    //
    //    [a push:s];
    
    
}


- (void)visitOptional:(PKOptionalNode *)node {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
    PKAlternation *alt = [PKAlternation alternation];
    
    [self.currentParser add:alt];
    
    PKCompositeParser *oldParser = _currentParser;
    
    NSAssert(1 == [node.children count], @"");
    for (PKBaseNode *child in node.children) {
        self.currentParser = alt;
        [child visit:self];
    }
    
    [alt add:[PKEmpty empty]];
    
    self.currentParser = oldParser;
}


- (void)visitMultiple:(PKMultipleNode *)node {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
    PKSequence *seq = [PKSequence sequence];
    
    [self.currentParser add:seq];
    
    PKCompositeParser *oldParser = _currentParser;
    
    NSAssert(1 == [node.children count], @"");
    PKBaseNode *child = node.children[0];
    self.currentParser = seq;
    [child visit:self];
    
    NSAssert(1 == [seq.subparsers count], @"");
    PKParser *sub = seq.subparsers[0];
    [seq add:[PKRepetition repetitionWithSubparser:sub]];
    
    self.currentParser = oldParser;
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
    
    NSAssert(node.token.isQuotedString, @"");
    NSString *literal = [node.token.stringValue stringByTrimmingQuotes];
    NSAssert([literal length], @"");
    PKParser *p = [PKLiteral literalWithString:literal];
    
    [self.currentParser add:p];
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
