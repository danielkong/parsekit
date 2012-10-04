//
//  TDParserVisitor.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/4/12.
//
//

#import "PKParserVisitor.h"
#import "PKNodeParser.h"
#import "PKNodeTerminal.h"
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


- (void)visitTerminal:(PKNodeTerminal *)node {
    PKTerminal *p = nil;
    
    PKToken *tok = node.token;
    
    switch (tok.tokenType) {
        case PKTokenTypeWord:
            p = [PKWord word];
            break;
            
        default:
            break;
    }
    
    
    [_currentParser add:p];
}


- (void)visitCollection:(PKNodeCollection *)node {
    PKCollectionParser *p = nil;

    [_currentParser add:p];
    self.currentParser = p;
}


- (void)visitRepetition:(PKNodeRepetition *)node {
    PKRepetition *p = nil;
    
    [_currentParser add:p];
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
