//
//  TDParserFactorySymbolTableTest.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/5/12.
//
//

#import "TDParserFactorySymbolTableTest.h"
#import "PKParserFactory.h"
#import "PKAST.h"

@interface TDParserFactorySymbolTableTest ()
@property (nonatomic, retain) PKParserFactory *factory;
@end

@implementation TDParserFactorySymbolTableTest

- (void)setUp {
    self.factory = [PKParserFactory factory];
}


- (void)tearDown {
    self.factory = nil;
}


- (void)testSimpleAST {
    NSString *g = @"@start=foo;foo=Word;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(ROOT (@start #foo) ($foo Word))", [rootNode treeDescription]);
}


- (void)testAlternationAST {
    NSString *g = @"@start=foo;foo=Word|Number;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(ROOT (@start #foo) ($foo (| Word Number)))", [rootNode treeDescription]);
}


- (void)testAlternationAST1 {
    NSString *g = @"@start=foo;foo=Word|Number Symbol;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(ROOT (@start #foo) ($foo (| Word (. Number Symbol))))", [rootNode treeDescription]);
}

@end
