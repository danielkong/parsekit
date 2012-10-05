//
//  TDParserVisitor.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/4/12.
//
//

#import "PKParserVisitor.h"
#import "PKNodeParser.h"
#import "PKNodeVariable.h"
#import "PKNodeConstant.h"
#import "PKNodeCollection.h"
#import "PKNodeRepetition.h"
#import "PKNodeDifference.h"
#import "PKNodePattern.h"
#import "PKNodeNegation.h"

@implementation PKParserVisitor

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
    
    for (PKNodeParser *child in node.children) {
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
    
    [_currentParser add:p];
}


- (void)visitCollection:(PKNodeCollection *)node {
    PKCollectionParser *p = nil;

    [_currentParser add:p];
    self.currentParser = p;

    for (PKNodeParser *child in node.children) {
        [child visit:self];
    }
}


- (void)visitRepetition:(PKNodeRepetition *)node {
    PKRepetition *p = nil;
    
    
    
    [_currentParser add:p];
    //    self.currentParser = p;

    for (PKNodeParser *child in node.children) {
        [child visit:self];
    }
}


- (void)visitDifference:(PKNodeDifference *)node {
    PKDifference *p = nil;
    
    [_currentParser add:p];
}


- (void)visitPattern:(PKNodePattern *)node {
    PKPattern *p = nil;
    
    [_currentParser add:p];
}


- (void)visitNegation:(PKNodeNegation *)node {
    PKNegation *p = nil;
    
    [_currentParser add:p];
}


- (void)setCurrentParser:(PKCollectionParser *)p {
    if (p != _currentParser) {
        [_currentParser release];
        _currentParser = [p retain];
        
        if (!_rootParser) {
            self.rootParser = _currentParser;
        }
    }
}

@end
