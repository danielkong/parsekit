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

@interface PKTerminal ()
@property (nonatomic, readwrite, copy) NSString *string;
@end

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
        if (PKNodeTypeReference == child.type) {
            self.currentParser = cp;
        } else {
            parent = child;
            child.parser = cp;
        }
        
        [child visit:self];
//        for (PKBaseNode *child in parent.children) {
//            self.currentParser = cp;
//            [child visit:self];
//        }
//        
//        // TODO remove
//        switch (child.type) {
//            case PKNodeTypeOptional: {
//                [cp add:[PKEmpty empty]];
//            } break;
//            case PKNodeTypeMultiple: {
//                NSAssert([cp isKindOfClass:[PKSequence class]], @"");
//                PKSequence *seq = (PKSequence *)cp;
//                NSAssert(1 == [seq.subparsers count], @"");
//                PKParser *sub = seq.subparsers[0];
//                [seq add:[PKRepetition repetitionWithSubparser:sub]];
//            } break;
////            case PKNodeTypeCardinal: {
////                NSAssert([cp isKindOfClass:[PKSequence class]], @"");
////                PKSequence *seq = (PKSequence *)cp;
////                NSAssert(1 == [seq.subparsers count], @"");
////                PKParser *sub = seq.subparsers[0];
////                [seq add:[PKRepetition repetitionWithSubparser:sub]];
////            } break;
//            default:
//                break;
//        }
        
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
    
    PKCompositeParser *cp = node.parser;
    if (!cp) {
        Class parserCls = [node parserClass];
        cp = [[[parserCls alloc] init] autorelease];
        NSAssert([cp isKindOfClass:[PKCompositeParser class]], @"");
    }
    
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
    
    PKCompositeParser *cp = node.parser;
    if (!cp) {
        Class parserCls = [node parserClass];
        cp = [[[parserCls alloc] init] autorelease];
        NSAssert([cp isKindOfClass:[PKCollectionParser class]], @"");
    }
    
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
    
    // create cardinal parser
    PKSequence *seq = (PKSequence *)node.parser;
    if (!seq) {
        Class parserCls = [node parserClass];
        seq = [[[parserCls alloc] init] autorelease];
        NSAssert([seq isKindOfClass:[PKSequence class]], @"");
    }
    
    // add to parser tree
    [self.currentParser add:seq];
    
    // prepare for recursion
    PKCompositeParser *oldParser = _currentParser;

    // recurse
    NSAssert(1 == [node.children count], @"");
    PKBaseNode *child = node.children[0];
    
    self.currentParser = seq;
    [child visit:self];
    
    // get result sub parser
    NSAssert(1 == [seq.subparsers count], @"");
    PKParser *sub = seq.subparsers[0];
    
    // duplicate sub parser specified number of times
    {
        NSUInteger start = node.rangeStart;
        NSUInteger end = node.rangeEnd;
        
        NSAssert(start >= 1 && NSNotFound != start, @"");
        NSAssert(end >= 1 && NSNotFound != end, @"");
        for (NSUInteger i = 1; i < start; i++) {
            [seq add:sub];
        }
        
        for (NSInteger i = start ; i < end; i++) {
            PKAlternation *alt = [PKAlternation alternationWithSubparsers:sub, [PKEmpty empty], nil];
            [seq add:alt];
        }
    }
    
    // restore from recursion
    self.currentParser = oldParser;
}


- (void)visitOptional:(PKOptionalNode *)node {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
    PKCompositeParser *alt = node.parser;
    if (!alt) {
        Class parserCls = [node parserClass];
        alt = [[[parserCls alloc] init] autorelease];
        NSAssert([alt isKindOfClass:[PKAlternation class]], @"");
    }
    
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
    
    PKSequence *seq = (PKSequence *)node.parser;
    if (!seq) {
        Class parserCls = [node parserClass];
        seq = [[[parserCls alloc] init] autorelease];
        NSAssert([seq isKindOfClass:[PKSequence class]], @"");
    }
    
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
    
    PKTerminal *p = (PKTerminal *)node.parser;
    if (!p) {
        Class parserCls = [node parserClass];
        p = [[[parserCls alloc] init] autorelease];
        NSAssert([p isKindOfClass:[PKTerminal class]], @"");
    }
    NSString *literal = node.literal;
    if (literal) {
        p.string = literal;
    }
    NSAssert(!literal || [p.string isEqualToString:literal], @"");
    
    [self.currentParser add:p];
}


- (void)visitLiteral:(PKLiteralNode *)node {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
    PKLiteral *p = (PKLiteral *)node.parser;
    if (!p) {
        Class parserCls = [node parserClass];
        p = [[[parserCls alloc] init] autorelease];
        NSAssert([p isKindOfClass:[PKLiteral class]], @"");
    }

    NSAssert(node.token.isQuotedString, @"");
    NSString *literal = [node.token.stringValue stringByTrimmingQuotes];
    NSAssert([literal length], @"");
    if (literal) {
        p.string = literal;
    }
    NSAssert(!literal || [p.string isEqualToString:literal], @"");
    
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
