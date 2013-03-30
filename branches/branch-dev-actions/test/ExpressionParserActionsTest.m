//
//  ExpressionParserActionsTest.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 3/27/13.
//
//

#import "ExpressionParserActionsTest.h"
#import "PKParserFactory.h"
#import "PKSParserGenVisitor.h"
#import "PKRootNode.h"
#import "ExpressionActionsParser.h"

@interface ExpressionParserActionsTest ()
@property (nonatomic, retain) PKParserFactory *factory;
@property (nonatomic, retain) PKRootNode *root;
@property (nonatomic, retain) PKSParserGenVisitor *visitor;
@property (nonatomic, retain) ExpressionActionsParser *parser;
@end

@implementation ExpressionParserActionsTest

- (void)setUp {
    self.factory = [PKParserFactory factory];
    _factory.collectTokenKinds = YES;

    NSError *err = nil;
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"expressionActions" ofType:@"grammar"];
    NSString *g = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&err];
    
    err = nil;
    self.root = (id)[_factory ASTFromGrammar:g error:&err];
    _root.grammarName = @"ExpressionActions";
    
    self.visitor = [[[PKSParserGenVisitor alloc] init] autorelease];
    [_root visit:_visitor];
    
    self.parser = [[[ExpressionActionsParser alloc] init] autorelease];

#if TD_EMIT
    path = [@"~/work/parsekit/trunk/test/ExpressionActionsParser.h" stringByExpandingTildeInPath];
    err = nil;
    if (![_visitor.interfaceOutputString writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&err]) {
        NSLog(@"%@", err);
    }

    path = [@"~/work/parsekit/trunk/test/ExpressionActionsParser.m" stringByExpandingTildeInPath];
    err = nil;
    if (![_visitor.implementationOutputString writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&err]) {
        NSLog(@"%@", err);
    }
#endif
}


- (void)tearDown {
    self.factory = nil;
}


- (void)testYes {
    PKAssembly *res = [_parser parseString:@"yes" assembler:self error:nil];
    TDEqualObjects(@"[1]yes^", [res description]);
}

- (void)testN {
    PKAssembly *res = [_parser parseString:@"no" assembler:self error:nil];
    TDEqualObjects(@"[0]no^", [res description]);
}


- (void)parser:(PKSParser *)p didMatchArgList:(PKAssembly *)a {
    //NSLog(@"%s %@", __PRETTY_FUNCTION__, a);
    
}

@end
