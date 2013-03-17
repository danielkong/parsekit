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
    
    PKSymbolTable *symTab = [_factory symbolTableFromGrammar:g error:&err];
    TDNotNil(symTab);
    
    PKBaseSymbol *start = [symTab resolve:@"@start"];
    TDNotNil(start);
    TDTrue([start isKindOfClass:[PKVariableSymbol class]]);
    
    TDNotNil(start.type);
    TDTrue([start.type isKindOfClass:[PKBuiltInTypeSymbol class]]);
    TDEqualObjects(@"Sequence", start.type.name);

    PKBaseSymbol *foo = [symTab resolve:@"foo"];
    TDNotNil(foo);
    TDTrue([foo isKindOfClass:[PKVariableSymbol class]]);
    
    TDNotNil(foo.type);
    TDTrue([foo.type isKindOfClass:[PKBuiltInTypeSymbol class]]);
    TDEqualObjects(@"Word", foo.type.name);
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
