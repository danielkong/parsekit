//
//  TDParserVisitor.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/4/12.
//
//

#import "PKNodeVisitor.h"
#import "PKNodeBase.h"
#import "PKNodeVariable.h"
#import "PKNodeConstant.h"
#import "PKNodePattern.h"
#import "PKNodeComposite.h"
#import "PKNodeCollection.h"
//#import "PKNodeRepetition.h"
//#import "PKNodeDifference.h"
//#import "PKNodeNegation.h"

@implementation PKNodeVisitor

- (void)dealloc {
    self.rootParser = nil;
    self.currentParser = nil;
    [super dealloc];
}


- (void)visitVariable:(PKNodeVariable *)node {
    PKCollectionParser *p = nil;
    
    PKToken *tok = node.token;
    NSAssert(tok.isWord, @"");
    
    p = [PKSequence sequence];
    p.name = tok.stringValue;
    
    [_currentParser add:p];
    self.currentParser = p;
    
    for (PKNodeBase *child in node.children) {
        [child visit:self];
    }
}


- (void)visitConstant:(PKNodeConstant *)node {
    PKTerminal *p = nil;
    
    PKToken *tok = node.token;
    NSAssert(tok.isWord, @"");
    
    NSString *parserClassName = tok.stringValue;

    Class parserClass = NSClassFromString([NSString stringWithFormat:@"PK%@", parserClassName]);
    NSAssert(parserClass, @"");
    
    p = [[[parserClass alloc] init] autorelease];
    
    if (node.discard) {
        [p discard];
    }
    
    [_currentParser add:p];
}


- (void)visitDelimited:(PKNodeDelimited *)node {
    NSString *startMarker = nil;
    NSString *endMarker = nil;
    PKDelimitedString *p = [PKDelimitedString delimitedStringWithStartMarker:startMarker endMarker:endMarker];
    
    [_currentParser add:p];
}


- (void)visitPattern:(PKNodePattern *)node {
    PKPatternOptions opts = 0;
    NSString *regex = nil;
    PKPattern *p = [PKPattern patternWithString:regex options:opts];
    
    [_currentParser add:p];
}


- (void)visitComposite:(PKNodeComposite *)node {
    PKCompositeParser *p = nil;
    
    PKToken *tok = node.token;
    NSAssert(tok.isSymbol, @"");
    
    NSString *tokStr = tok.stringValue;
    NSAssert([tokStr length], @"");
    unichar c = [tokStr characterAtIndex:0];
    
    Class parserClass = Nil;
    
    switch (c) {
        case '*':
            parserClass = [PKRepetition class];
            break;
        case '~':
            parserClass = [PKNegation class];
            break;
        case '-':
            parserClass = [PKNegation class];
            break;
        default:
            NSAssert1(0, @"unknown composite node type '%@'", tokStr);
            break;
    }
    
    p = [[[parserClass alloc] init] autorelease];
    
    [_currentParser add:p];
    self.currentParser = p;
    
    for (PKNodeBase *child in node.children) {
        [child visit:self];
    }
}


- (void)visitCollection:(PKNodeCollection *)node {
    PKCollectionParser *p = nil;
    
    PKToken *tok = node.token;
    NSAssert(tok.isSymbol, @"");
    
    NSString *tokStr = tok.stringValue;
    NSAssert([tokStr length], @"");
    unichar c = [tokStr characterAtIndex:0];
    
    Class parserClass = Nil;
    
    switch (c) {
        case 'S':
            parserClass = [PKSequence class];
            break;
        case 'T':
            parserClass = [PKTrack class];
            break;
        case '&':
            parserClass = [PKIntersection class];
            break;
        case '|':
            parserClass = [PKAlternation class];
            break;
        default:
            NSAssert1(0, @"unknown collection node type '%@'", tokStr);
            break;
    }
    
    p = [[[parserClass alloc] init] autorelease];

    [_currentParser add:p];
    self.currentParser = p;
    
    for (PKNodeBase *child in node.children) {
        [child visit:self];
    }
}


- (void)visitOptional:(PKNodeCollection *)node {
    PKCollectionParser *alt = [PKAlternation alternation];
    [alt add:[PKEmpty empty]];
    
    PKToken *tok = node.token;
    NSAssert(tok.isSymbol, @"");
    NSAssert([tok.stringValue isEqualToString:@"?"], @"");
    
    [_currentParser add:alt];
    self.currentParser = alt;
    
    for (PKNodeBase *child in node.children) {
        [child visit:self];
    }
}


- (void)visitMultiple:(PKNodeCollection *)node {
    PKCollectionParser *seq = [PKSequence sequence];
    
    PKToken *tok = node.token;
    NSAssert(tok.isSymbol, @"");
    NSAssert([tok.stringValue isEqualToString:@"+"], @"");
    
    [_currentParser add:seq];
    self.currentParser = seq;
    
    NSAssert(1 == [node.children count], @"");
    for (PKNodeBase *childNode in node.children) {
        [childNode visit:self];
    }
    
    NSAssert(1 == [seq.subparsers count], @"");
    for (PKParser *childParser in seq.subparsers) {
        [seq add:[PKRepetition repetitionWithSubparser:childParser]];
    }
}


//- (void)visitRepetition:(PKNodeRepetition *)node {
//    PKRepetition *p = [[[PKRepetition alloc] init] autorelease];
//    
//    [_currentParser add:p];
//    self.currentParser = p;
//
//    for (PKNodeParser *child in node.children) {
//        [child visit:self];
//    }
//}
//
//
//- (void)visitDifference:(PKNodeDifference *)node {
//    PKDifference *p = [[[PKDifference alloc] init] autorelease];
//    
//    [_currentParser add:p];
//    self.currentParser = p;
//    
//    for (PKNodeParser *child in node.children) {
//        [child visit:self];
//    }
//}
//
//
//- (void)visitNegation:(PKNodeNegation *)node {
//    PKNegation *p = [[[PKNegation alloc] init] autorelease];
//    
//    [_currentParser add:p];
//    self.currentParser = p;
//    
//    for (PKNodeParser *child in node.children) {
//        [child visit:self];
//    }
//}


- (void)setCurrentParser:(PKCompositeParser *)p {
    if (p != _currentParser) {
        [_currentParser release];
        _currentParser = [p retain];
        
        if (!_rootParser) {
            self.rootParser = _currentParser;
        }
    }
}

@end
