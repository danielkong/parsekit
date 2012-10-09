//
//  TDParserFactoryASTTest.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/3/12.
//
//

#import "TDParserFactoryASTTest.h"
#import "PKParserFactory.h"
#import "PKAST.h"

@interface TDParserFactoryASTTest ()
@property (nonatomic, retain) PKParserFactory *factory;
@end

@implementation TDParserFactoryASTTest

- (void)setUp {
    self.factory = [PKParserFactory factory];
}


- (void)tearDown {
    self.factory = nil;
}


- (void)testAlternationAST {
    NSString *g = @"@start=foo;foo=bar;bar=baz|bat;baz=Word;bat=Number;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (foo:SEQ (bar:SEQ (:| (baz:SEQ :Word) (bat:SEQ :Number)))))", [rootNode treeDescription]);
    //TDEqualObjects(@"(@start (foo (bar (| (baz Word) (bat Number)))))", [rootNode treeDescription]);
}



/*
 @start = foo; foo = Word|Number;
 
 (@start (foo (| Word Number)))
 (@start:SEQ (foo:SEQ (:| :Word :Number)))
 
 (@start (foo Word Number))
 (@start (foo:| :Word :Number))
 
 (foo Word Number)
 (@foo:| :Word :Number)
 
 */


- (void)testAlternationAST2 {
    NSString *g = @"@start=foo;foo=Word|Number;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (foo:SEQ (:| :Word :Number)))", [rootNode treeDescription]);
    //TDEqualObjects(@"(@start (foo (bar (| baz bat))))", [rootNode treeDescription]);
}


/*
 @start = foo; foo = bar|baz; bar=Word; baz=Number;
 
 (@start (foo (| (bar Word) (baz Number))))
 (@start:SEQ (foo:SEQ (:| (bar:SEQ Word) (baz:SEQ Number))))
 
 (@start (foo bar baz))
 (@start (foo:| bar:Word baz:Number))
 
 (@start bar baz)
 (@start:| bar:Word baz:Number)
 
 (foo bar baz)
 (foo:| bar:Word baz:Number)
 */


- (void)testAlternationAST3 {
    NSString *g = @"@start=foo;foo=bar|baz;bar=Word;baz=Number;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (foo:SEQ (:| (bar:SEQ :Word) (baz:SEQ :Number))))", [rootNode treeDescription]);
    //TDEqualObjects(@"(@start (foo (bar Word) (baz Number)))", [rootNode treeDescription]);
}


- (void)testSequenceAST {
    NSString *g = @"@start=foo;foo=QuotedString Number;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (foo:SEQ :QuotedString :Number))", [rootNode treeDescription]);
}


- (void)testSubExprSequenceAST {
    NSString *g = @"@start=foo;foo=(QuotedString Number);";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (foo:SEQ (:SEQ :QuotedString :Number)))", [rootNode treeDescription]);

    g = @"@start=foo;foo=( QuotedString Number );";
    
    err = nil;
    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (foo:SEQ (:SEQ :QuotedString :Number)))", [rootNode treeDescription]);

    g = @"@start=foo; foo = ( QuotedString Number );";
    
    err = nil;
    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (foo:SEQ (:SEQ :QuotedString :Number)))", [rootNode treeDescription]);
}


- (void)testDifferenceAST {
    NSString *g = @"@start=foo;foo=Any-Word;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (foo:SEQ (:- :Any :Word)))", [rootNode treeDescription]);

    g = @"@start=foo;foo=Any - Word;";
    
    err = nil;
    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (foo:SEQ (:- :Any :Word)))", [rootNode treeDescription]);

    g = @"@start=foo;foo=Any -Word;";
    
    err = nil;
    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (foo:SEQ (:- :Any :Word)))", [rootNode treeDescription]);

    g = @"@start=foo;foo=Any- Word;";
    
    err = nil;
    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (foo:SEQ (:- :Any :Word)))", [rootNode treeDescription]);
}


- (void)testIntersectionAST {
    NSString *g = @"@start=foo;foo=Word&LowercaseWord;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (foo:SEQ (:& :Word :LowercaseWord)))", [rootNode treeDescription]);
    
    g = @"@start=foo;foo=Word & LowercaseWord;";
    
    err = nil;
    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (foo:SEQ (:& :Word :LowercaseWord)))", [rootNode treeDescription]);
    
    g = @"@start=foo;foo=Word &LowercaseWord;";
    
    err = nil;
    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (foo:SEQ (:& :Word :LowercaseWord)))", [rootNode treeDescription]);
    
    g = @"@start=foo;foo=Word& LowercaseWord;";
    
    err = nil;
    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (foo:SEQ (:& :Word :LowercaseWord)))", [rootNode treeDescription]);
}


- (void)testStarAST {
    NSString *g = @"@start=foo;foo=Word*;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (foo:SEQ (:* :Word)))", [rootNode treeDescription]);
    
    g = @"@start=foo;foo=Word *;";
    
    err = nil;
    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (foo:SEQ (:* :Word)))", [rootNode treeDescription]);
}


- (void)testQuestionAST {
    NSString *g = @"@start=foo;foo=Word?;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (foo:SEQ (:? :Word)))", [rootNode treeDescription]);
    
    g = @"@start=foo;foo=Word ?;";
    
    err = nil;
    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (foo:SEQ (:? :Word)))", [rootNode treeDescription]);
}


- (void)testPlusAST {
    NSString *g = @"@start=foo;foo=Word+;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (foo:SEQ (:+ :Word)))", [rootNode treeDescription]);
    
    g = @"@start=foo;foo=Word +;";
    
    err = nil;
    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (foo:SEQ (:+ :Word)))", [rootNode treeDescription]);
}


- (void)testNegationAST {
    NSString *g = @"@start=foo;foo=~Word;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (foo:SEQ (:~ :Word)))", [rootNode treeDescription]);
    
    g = @"@start=foo;foo= ~Word;";
    
    err = nil;
    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (foo:SEQ (:~ :Word)))", [rootNode treeDescription]);

    g = @"@start=foo;foo= ~ Word;";
    
    err = nil;
    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (foo:SEQ (:~ :Word)))", [rootNode treeDescription]);
}


- (void)testPatternAST {
    NSString *g = @"@start=foo;foo=/\\w/;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (foo:SEQ :/\\w/))", [rootNode treeDescription]);
    
    g = @"@start=foo;foo = /\\w/;";
    
    err = nil;
    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (foo:SEQ :/\\w/))", [rootNode treeDescription]);
}


- (void)testSimplifyAST {
    NSString *g = @"@start=foo;foo=Symbol;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (foo:SEQ :Symbol))", [rootNode treeDescription]);
    
}


- (void)testSubExprAST {
    NSString *g = @"@start = (Number)*;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (:* :Number))", [rootNode treeDescription]);
    
}


- (void)testSeqRepAST {
    NSString *g = @"@start = (Word | Number)* QuotedString;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (:* (:| :Word :Number)) :QuotedString)", [rootNode treeDescription]);
    
}


- (void)testSeqRepAST2 {
    NSString *g = @"@start = foo; foo=(Word | Number)* QuotedString;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    
    TDNotNil(rootNode);
    //    TDEqualObjects(@"(@start (foo (* (| Word Number)) QuotedString))"), [rootNode treeDescription]);
    TDEqualObjects(@"(@start:SEQ (foo:SEQ (:* (:| :Word :Number)) :QuotedString))", [rootNode treeDescription]);

}


- (void)testAltPrecedenceAST {
    NSString *g = @"@start = foo; foo=Word | Number Symbol;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (foo:SEQ (:| :Word (:SEQ :Number :Symbol))))", [rootNode treeDescription]);
    
}


- (void)testAltPrecedenceAST2 {
    NSString *g = @"@start = foo; foo=Word Number | Symbol;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (foo:SEQ (:| (:SEQ :Word :Number) :Symbol)))", [rootNode treeDescription]);
    
}

@end
