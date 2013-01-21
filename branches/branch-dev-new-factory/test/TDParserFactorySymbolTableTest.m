//
//  TDParserFactorySymbolTableTest.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 1/21/13.
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


- (void)testAlternationAST {
    NSString *g = @"@start=foo|bar;foo=Number;bar=foo Word;";
    
    NSError *err = nil;
    NSDictionary *tab = [_factory symbolTableFromGrammar:g simplify:NO error:&err];
    TDNotNil(tab);
    
    TDEquals((NSUInteger)3, [tab count]);
    TDNotNil(tab[@"@start"]);
    TDNotNil(tab[@"foo"]);
    TDNotNil(tab[@"bar"]);
    
    TDTrue([tab[@"foo"] isKindOfClass:[PKAST class]]);
    
    PKAST *start = [_factory ASTFromGrammar:g error:nil];
    TDNotNil(start);
    TDTrue([start isKindOfClass:[PKAST class]]);
    TDEqualObjects([start treeDescription], @"");
    
    PKParser *p = [_factory parserFromGrammar:g assembler:nil error:&err];
    TDNotNil(p);
    
    TDTrue([p isKindOfClass:[PKParser class]]);
    NSString *s = @"1";
    
    id res = [p parse:s error:nil];
    TDNotNil(res);
    TDTrue([res isKindOfClass:[PKToken class]]);
    
//    TDEqualObjects(@"(@start:SEQ (:SEQ (foo:SEQ (:SEQ (bar:SEQ (:| (:SEQ (baz:SEQ (:SEQ :Word))) (:SEQ (bat:SEQ (:SEQ :Number)))))))))", [rootNode treeDescription]);
    //TDEqualObjects(@"(@start (foo (bar (| (baz Word) (bat Number)))))", [rootNode treeDescription]);
}

@end