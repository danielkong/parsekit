//
//  LabelEBNFParserTest.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 3/27/13.
//
//

#import "LabelEBNFParserTest.h"
#import "PKParserFactory.h"
#import "PKSParserGenVisitor.h"
#import "PKRootNode.h"
#import "LabelEBNFParser.h"

@interface LabelEBNFParserTest ()
@property (nonatomic, retain) PKParserFactory *factory;
@property (nonatomic, retain) PKRootNode *root;
@property (nonatomic, retain) PKSParserGenVisitor *visitor;
@property (nonatomic, retain) LabelEBNFParser *parser;
@end

@implementation LabelEBNFParserTest

- (void)setUp {
    self.factory = [PKParserFactory factory];
    _factory.collectTokenKinds = YES;

    NSError *err = nil;
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"label_ebnf" ofType:@"grammar"];
    NSString *g = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&err];
    
    err = nil;
    self.root = (id)[_factory ASTFromGrammar:g error:&err];
    _root.grammarName = @"LabelEBNF";
    
    self.visitor = [[[PKSParserGenVisitor alloc] init] autorelease];
    [_root visit:_visitor];
    
    self.parser = [[[LabelEBNFParser alloc] init] autorelease];

#if TD_EMIT
    path = [@"~/work/parsekit/trunk/test/LabelEBNFParser.h" stringByExpandingTildeInPath];
    err = nil;
    if (![_visitor.interfaceOutputString writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&err]) {
        NSLog(@"%@", err);
    }

    path = [@"~/work/parsekit/trunk/test/LabelEBNFParser.m" stringByExpandingTildeInPath];
    err = nil;
    if (![_visitor.implementationOutputString writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&err]) {
        NSLog(@"%@", err);
    }
#endif
}

- (void)tearDown {
    self.factory = nil;
}

//- (void)testAddDisableActions {
//    _parser.disableActions = YES;
//    
//    NSError *err = nil;
//    PKAssembly *res = [_parser parseString:@"1+2" assembler:nil error:&err];
//    
//    TDEqualObjects(@"[1, 2]1/+/2^", [res description]);
//}

@end
