//
//  PKSParseTreeAssembler.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 4/25/13.
//
//

#import "PKSParseTreeAssembler.h"
#import <ParseKit/PKSParser.h>
#import <ParseKit/PKSTokenAssembly.h>
#import <ParseKit/PKToken.h>

#import "PKParseTree.h"
#import "PKRuleNode.h"
#import "PKTokenNode.h"

@implementation PKSParseTreeAssembler

- (void)dealloc {
    self.root = nil;
    self.currentNode = nil;
    self.saveNode = nil;
    [super dealloc];
}


- (void)parser:(PKSParser *)p willMatchInterior:(NSString *)ruleName {
    PKRuleNode *r = [PKRuleNode ruleNodeWithName:ruleName];
    if (!_root) {
        self.root = r;
    } else {
        [_currentNode addChild:r];
    }
    
    self.saveNode = _currentNode;
    self.currentNode = r;
}


- (void)parser:(PKSParser *)p didMatchInterior:(NSString *)ruleName {
    NSAssert(_saveNode, @"");

    self.currentNode = _saveNode;
}


- (void)parser:(PKSParser *)p willMatchLeaf:(NSString *)ruleName {
    NSAssert(_currentNode, @"");
    
    [_currentNode addChildToken:[p LT:1]];
}


- (void)parser:(PKSParser *)p didMatchLeaf:(NSString *)ruleName {
    
}

@end
