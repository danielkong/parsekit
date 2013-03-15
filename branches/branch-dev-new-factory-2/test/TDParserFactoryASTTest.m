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


//- (void)testAlternationAST {
//    NSString *g = @"@start=foo;foo=bar;bar=baz|bat;baz=Word;bat=Number;";
//    
//    NSError *err = nil;
//    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    TDNotNil(rootNode);
//    TDEqualObjects(@"(@start:SEQ (foo:SEQ (bar:| baz:Word bat:Number)))", [rootNode treeDescription]);
//    //TDEqualObjects(@"(@start (foo (bar (| (baz Word) (bat Number)))))", [rootNode treeDescription]);
//}


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
    NSString *g = @"@start=foo;foo=Word;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(ROOT (@start:DEF foo:REF) (foo:DEF :Word))", [rootNode treeDescription]);
    //TDEqualObjects(@"(@start:SEQ foo:Word)", [rootNode treeDescription]);
    //TDEqualObjects(@"(@start (foo (bar (| baz bat))))", [rootNode treeDescription]);
}


- (void)testAlternationAST2_1 {
    NSString *g = @"@start=foo;foo=Word|Number;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(ROOT (@start:DEF foo:REF) (foo:DEF (:| :Word :Number)))", [rootNode treeDescription]);
    //TDEqualObjects(@"(@start:SEQ (foo:| :Word :Number))", [rootNode treeDescription]);
    //TDEqualObjects(@"(@start (foo (bar (| baz bat))))", [rootNode treeDescription]);
}


- (void)testAlternationAST2_1_0 {
    NSString *g = @"@start=foo;foo=Word|Number Symbol;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(ROOT (@start:DEF foo:REF) (foo:DEF (:| :Word (:SEQ :Number :Symbol))))", [rootNode treeDescription]);
    //TDEqualObjects(@"(@start:SEQ (foo:| :Word (:SEQ :Number :Symbol)))", [rootNode treeDescription]);
    //TDEqualObjects(@"(@start (foo (bar (| baz bat))))", [rootNode treeDescription]);
}


- (void)testAlternationAST2_1_1 {
    NSString *g = @"@start=foo;foo=Word Number|Symbol;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(ROOT (@start:DEF foo:REF) (foo:DEF (:| (:SEQ :Word :Number) :Symbol)))", [rootNode treeDescription]);
    //TDEqualObjects(@"(@start:SEQ (foo:| (:SEQ :Word :Number) :Symbol))", [rootNode treeDescription]);
    //TDEqualObjects(@"(@start (foo (bar (| baz bat))))", [rootNode treeDescription]);
}


//- (void)testAlternationAST2_2 {
//    NSString *g = @"@start=foo;foo=Word|Number Symbol QuotedString;";
//    
//    NSError *err = nil;
//    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    TDNotNil(rootNode);
//    TDEqualObjects(@"(@start:SEQ (foo:| :Word (:SEQ :Number :Symbol :QuotedString)))", [rootNode treeDescription]);
//    //TDEqualObjects(@"(@start (foo (bar (| baz bat))))", [rootNode treeDescription]);
//}
//
//
//- (void)testAlternationAST2_3 {
//    NSString *g = @"@start=foo;foo=(Word Number);";
//    
//    NSError *err = nil;
//    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    TDNotNil(rootNode);
//    TDEqualObjects(@"(@start:SEQ (foo:SEQ :Word :Number))", [rootNode treeDescription]);
//    //TDEqualObjects(@"(@start (foo (bar (| baz bat))))", [rootNode treeDescription]);
//}
//
//
//- (void)testAlternationAST2_4 {
//    NSString *g = @"@start=foo;foo=(Word Number) Symbol;";
//    
//    NSError *err = nil;
//    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    TDNotNil(rootNode);
//    TDEqualObjects(@"(@start:SEQ (foo:SEQ (:SEQ :Word :Number) :Symbol))", [rootNode treeDescription]);
//    //TDEqualObjects(@"(@start (foo (bar (| baz bat))))", [rootNode treeDescription]);
//}
//
//
//- (void)testAlternationAST2_5 {
//    NSString *g = @"@start=foo;foo=Symbol (Word Number);";
//    
//    NSError *err = nil;
//    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    TDNotNil(rootNode);
//    TDEqualObjects(@"(@start:SEQ (foo:SEQ :Symbol (:SEQ :Word :Number)))", [rootNode treeDescription]);
//    //TDEqualObjects(@"(@start (foo (bar (| baz bat))))", [rootNode treeDescription]);
//}
//
//
//- (void)testAlternationAST2_6 {
//    NSString *g = @"@start=foo;foo=(Word|Number);";
//    
//    NSError *err = nil;
//    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    TDNotNil(rootNode);
//    TDEqualObjects(@"(@start:SEQ (foo:| :Word :Number))", [rootNode treeDescription]);
//    //TDEqualObjects(@"(@start (foo (bar (| baz bat))))", [rootNode treeDescription]);
//}
//
//
//- (void)testAlternationAST2_7 {
//    NSString *g = @"@start=foo;foo=Symbol (Word|Number);";
//    
//    NSError *err = nil;
//    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    TDNotNil(rootNode);
//    TDEqualObjects(@"(@start:SEQ (foo:SEQ :Symbol (:| :Word :Number)))", [rootNode treeDescription]);
//    //TDEqualObjects(@"(@start (foo (bar (| baz bat))))", [rootNode treeDescription]);
//}
//
//
//- (void)testAlternationAST2_8 {
//    NSString *g = @"@start=foo;foo=(Word|Number) Symbol;";
//    
//    NSError *err = nil;
//    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    TDNotNil(rootNode);
//    TDEqualObjects(@"(@start:SEQ (foo:SEQ (:| :Word :Number) :Symbol))", [rootNode treeDescription]);
//    //TDEqualObjects(@"(@start (foo (bar (| baz bat))))", [rootNode treeDescription]);
//}
//
//
//- (void)testAlternationAST2_9 {
//    NSString *g = @"@start=foo;foo=Word|Number Symbol;";
//    
//    NSError *err = nil;
//    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    TDNotNil(rootNode);
//    TDEqualObjects(@"(@start:SEQ (foo:| :Word (:SEQ :Number :Symbol)))", [rootNode treeDescription]);
//    //TDEqualObjects(@"(@start (foo (bar (| baz bat))))", [rootNode treeDescription]);
//}
//
//
//- (void)testAlternationAST2_10 {
//    NSString *g = @"@start=foo;foo=(Word|Number Symbol);";
//    
//    NSError *err = nil;
//    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    TDNotNil(rootNode);
//    TDEqualObjects(@"(@start:SEQ (foo:| :Word (:SEQ :Number :Symbol)))", [rootNode treeDescription]);
//    //TDEqualObjects(@"(@start (foo (bar (| baz bat))))", [rootNode treeDescription]);
//}
//
//
//- (void)testAlternationAST2_11 {
//    NSString *g = @"@start=foo;foo=Word|(Number Symbol);";
//    
//    NSError *err = nil;
//    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    TDNotNil(rootNode);
//    TDEqualObjects(@"(@start:SEQ (foo:| :Word (:SEQ :Number :Symbol)))", [rootNode treeDescription]);
//    //TDEqualObjects(@"(@start (foo (bar (| baz bat))))", [rootNode treeDescription]);
//}
//
//
///*
// @start = foo; foo = bar|baz; bar=Word; baz=Number;
// 
// (@start (foo (| (bar Word) (baz Number))))
// (@start:SEQ (foo:SEQ (:| (bar:SEQ Word) (baz:SEQ Number))))
// 
// (@start (foo bar baz))
// (@start (foo:| bar:Word baz:Number))
// 
// (@start bar baz)
// (@start:| bar:Word baz:Number)
// 
// (foo bar baz)
// (foo:| bar:Word baz:Number)
// */
//
//- (void)testAlternationAST3 {
//    NSString *g = @"@start=foo;foo=bar|baz;bar=Word;baz=Number;";
//    
//    NSError *err = nil;
//    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    TDNotNil(rootNode);
//    TDEqualObjects(@"(@start:SEQ (foo:| bar:Word baz:Number))", [rootNode treeDescription]);
//    //TDEqualObjects(@"(@start (foo (bar Word) (baz Number)))", [rootNode treeDescription]);
//}
//
//
//- (void)testSequenceAST {
//    NSString *g = @"@start=foo;foo=QuotedString Number;";
//    
//    NSError *err = nil;
//    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    TDNotNil(rootNode);
//    TDEqualObjects(@"(@start:SEQ (foo:SEQ :QuotedString :Number))", [rootNode treeDescription]);
//}
//
//
//- (void)testSubExprSequenceAST {
//    NSString *g = @"@start=foo;foo=(QuotedString Number);";
//    
//    NSError *err = nil;
//    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    TDNotNil(rootNode);
//    TDEqualObjects(@"(@start:SEQ (foo:SEQ :QuotedString :Number))", [rootNode treeDescription]);
//    
//    g = @"@start=foo;foo=( QuotedString Number );";
//    
//    err = nil;
//    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    TDNotNil(rootNode);
//    TDEqualObjects(@"(@start:SEQ (foo:SEQ :QuotedString :Number))", [rootNode treeDescription]);
//    
//    g = @"@start=foo; foo = ( QuotedString Number );";
//    
//    err = nil;
//    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    TDNotNil(rootNode);
//    TDEqualObjects(@"(@start:SEQ (foo:SEQ :QuotedString :Number))", [rootNode treeDescription]);
//}
//
//
//- (void)testDifferenceAST {
//    NSString *g = @"@start=foo;foo=Any-Word;";
//    
//    NSError *err = nil;
//    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    TDNotNil(rootNode);
//    TDEqualObjects(@"(@start:SEQ (foo:- :Any :Word))", [rootNode treeDescription]);
//    
//    g = @"@start=foo;foo=Any - Word;";
//    
//    err = nil;
//    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    TDNotNil(rootNode);
//    TDEqualObjects(@"(@start:SEQ (foo:- :Any :Word))", [rootNode treeDescription]);
//    
//    g = @"@start=foo;foo=Any -Word;";
//    
//    err = nil;
//    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    TDNotNil(rootNode);
//    TDEqualObjects(@"(@start:SEQ (foo:- :Any :Word))", [rootNode treeDescription]);
//    
//    g = @"@start=foo;foo=Any- Word;";
//    
//    err = nil;
//    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    TDNotNil(rootNode);
//    TDEqualObjects(@"(@start:SEQ (foo:- :Any :Word))", [rootNode treeDescription]);
//}
//
//
//- (void)testIntersectionAST {
//    NSString *g = @"@start=foo;foo=Word&LowercaseWord;";
//    
//    NSError *err = nil;
//    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    TDNotNil(rootNode);
//    TDEqualObjects(@"(@start:SEQ (foo:& :Word :LowercaseWord))", [rootNode treeDescription]);
//    
//    g = @"@start=foo;foo=Word & LowercaseWord;";
//    
//    err = nil;
//    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    TDNotNil(rootNode);
//    TDEqualObjects(@"(@start:SEQ (foo:& :Word :LowercaseWord))", [rootNode treeDescription]);
//    
//    g = @"@start=foo;foo=Word &LowercaseWord;";
//    
//    err = nil;
//    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    TDNotNil(rootNode);
//    TDEqualObjects(@"(@start:SEQ (foo:& :Word :LowercaseWord))", [rootNode treeDescription]);
//    
//    g = @"@start=foo;foo=Word& LowercaseWord;";
//    
//    err = nil;
//    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    TDNotNil(rootNode);
//    TDEqualObjects(@"(@start:SEQ (foo:& :Word :LowercaseWord))", [rootNode treeDescription]);
//}
//
//
//- (void)testStarAST {
//    NSString *g = @"@start=foo;foo=Word*;";
//    
//    NSError *err = nil;
//    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    TDNotNil(rootNode);
//    TDEqualObjects(@"(@start:SEQ (foo:* :Word))", [rootNode treeDescription]);
//    
//    g = @"@start=foo;foo=Word *;";
//    
//    err = nil;
//    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    TDNotNil(rootNode);
//    TDEqualObjects(@"(@start:SEQ (foo:* :Word))", [rootNode treeDescription]);
//}
//
//
//- (void)testQuestionAST {
//    NSString *g = @"@start=foo;foo=Word?;";
//    
//    NSError *err = nil;
//    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    TDNotNil(rootNode);
//    TDEqualObjects(@"(@start:SEQ (foo:? :Word))", [rootNode treeDescription]);
//    
//    g = @"@start=foo;foo=Word ?;";
//    
//    err = nil;
//    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    TDNotNil(rootNode);
//    TDEqualObjects(@"(@start:SEQ (foo:? :Word))", [rootNode treeDescription]);
//}
//
//
//- (void)testPlusAST {
//    NSString *g = @"@start=foo;foo=Word+;";
//    
//    NSError *err = nil;
//    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    TDNotNil(rootNode);
//    TDEqualObjects(@"(@start:SEQ (foo:+ :Word))", [rootNode treeDescription]);
//    
//    g = @"@start=foo;foo=Word +;";
//    
//    err = nil;
//    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    TDNotNil(rootNode);
//    TDEqualObjects(@"(@start:SEQ (foo:+ :Word))", [rootNode treeDescription]);
//}
//
//
//- (void)testNegationAST {
//    NSString *g = @"@start=foo;foo=~Word;";
//    
//    NSError *err = nil;
//    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    TDNotNil(rootNode);
//    TDEqualObjects(@"(@start:SEQ (foo:~ :Word))", [rootNode treeDescription]);
//    
//    g = @"@start=foo;foo= ~Word;";
//    
//    err = nil;
//    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    TDNotNil(rootNode);
//    TDEqualObjects(@"(@start:SEQ (foo:~ :Word))", [rootNode treeDescription]);
//    
//    g = @"@start=foo;foo= ~ Word;";
//    
//    err = nil;
//    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    TDNotNil(rootNode);
//    TDEqualObjects(@"(@start:SEQ (foo:~ :Word))", [rootNode treeDescription]);
//}
//
//
//- (void)testPatternAST {
//    NSString *g = @"@start=foo;foo=/\\w/;";
//    
//    NSError *err = nil;
//    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    TDNotNil(rootNode);
//    TDEqualObjects(@"(@start:SEQ foo:/\\w/)", [rootNode treeDescription]);
//    
//    g = @"@start=foo;foo = /\\w/;";
//    
//    err = nil;
//    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    TDNotNil(rootNode);
//    TDEqualObjects(@"(@start:SEQ foo:/\\w/)", [rootNode treeDescription]);
//}
//
//
//- (void)testSimplifyAST {
//    NSString *g = @"@start=foo;foo=Symbol;";
//    
//    NSError *err = nil;
//    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    
//    TDNotNil(rootNode);
//    TDEqualObjects(@"(@start:SEQ foo:Symbol)", [rootNode treeDescription]);
//}
//
//
//- (void)testSubExprAST {
//    NSString *g = @"@start = (Number)*;";
//    
//    NSError *err = nil;
//    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    
//    TDNotNil(rootNode);
//    TDEqualObjects(@"(@start:* :Number)", [rootNode treeDescription]);
//    
//}
//
//
//- (void)testSubExprAST1 {
//    NSString *g = @"@start = Number*;";
//    
//    NSError *err = nil;
//    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    
//    TDNotNil(rootNode);
//    TDEqualObjects(@"(@start:* :Number)", [rootNode treeDescription]);
//    
//}
//
//
//- (void)testSubExprAST2 {
//    NSString *g = @"@start = (Number)+;";
//    
//    NSError *err = nil;
//    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    
//    TDNotNil(rootNode);
//    TDEqualObjects(@"(@start:+ :Number)", [rootNode treeDescription]);
//    
//}
//
//
//- (void)testSubExprAST3 {
//    NSString *g = @"@start = Number+;";
//    
//    NSError *err = nil;
//    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    
//    TDNotNil(rootNode);
//    TDEqualObjects(@"(@start:+ :Number)", [rootNode treeDescription]);
//    
//}
//
//
//- (void)testSubExprAST4 {
//    NSString *g = @"@start = (Number)?;";
//    
//    NSError *err = nil;
//    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    
//    TDNotNil(rootNode);
//    TDEqualObjects(@"(@start:? :Number)", [rootNode treeDescription]);
//    
//}
//
//
//- (void)testSubExprAST5 {
//    NSString *g = @"@start = Number?;";
//    
//    NSError *err = nil;
//    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    
//    TDNotNil(rootNode);
//    TDEqualObjects(@"(@start:? :Number)", [rootNode treeDescription]);
//    
//}
//
//
//- (void)testSubExprAST6 {
//    NSString *g = @"@start = ~(Number);";
//    
//    NSError *err = nil;
//    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    
//    TDNotNil(rootNode);
//    TDEqualObjects(@"(@start:~ :Number)", [rootNode treeDescription]);
//    
//}
//
//
//- (void)testSubExprAST7 {
//    NSString *g = @"@start = ~Number;";
//    
//    NSError *err = nil;
//    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    
//    TDNotNil(rootNode);
//    TDEqualObjects(@"(@start:~ :Number)", [rootNode treeDescription]);
//    
//}
//
//
//- (void)testSubExprAST8 {
//    NSString *g = @"@start = ~(Word Number);";
//    
//    NSError *err = nil;
//    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    
//    TDNotNil(rootNode);
//    TDEqualObjects(@"(@start:~ (:SEQ :Word :Number))", [rootNode treeDescription]);
//    
//}
//
//
//- (void)testSubExprAST9 {
//    NSString *g = @"@start = (Word Number)+;";
//    
//    NSError *err = nil;
//    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    
//    TDNotNil(rootNode);
//    TDEqualObjects(@"(@start:+ (:SEQ :Word :Number))", [rootNode treeDescription]);
//    
//}
//
//
//- (void)testSubExprAST10 {
//    NSString *g = @"@start = (Word Number)*;";
//    
//    NSError *err = nil;
//    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    
//    TDNotNil(rootNode);
//    TDEqualObjects(@"(@start:* (:SEQ :Word :Number))", [rootNode treeDescription]);
//    
//}
//
//
//- (void)testSubExprAST11 {
//    NSString *g = @"@start = (Word Number)?;";
//    
//    NSError *err = nil;
//    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    
//    TDNotNil(rootNode);
//    TDEqualObjects(@"(@start:? (:SEQ :Word :Number))", [rootNode treeDescription]);
//    
//}
//
//
//- (void)testSeqRepAST {
//    NSString *g = @"@start = (Word | Number)* QuotedString;";
//    
//    NSError *err = nil;
//    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    
//    TDNotNil(rootNode);
//    TDEqualObjects(@"(@start:SEQ (:* (:| :Word :Number)) :QuotedString)", [rootNode treeDescription]);
//    
//}
//
//
//- (void)testSeqRepAST2 {
//    NSString *g = @"@start = foo; foo=(Word | Number)* QuotedString;";
//    
//    NSError *err = nil;
//    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    
//    TDNotNil(rootNode);
//    //    TDEqualObjects(@"(@start (foo (* (| Word Number)) QuotedString))"), [rootNode treeDescription]);
//    TDEqualObjects(@"(@start:SEQ (foo:SEQ (:* (:| :Word :Number)) :QuotedString))", [rootNode treeDescription]);
//    
//}
//
//
//- (void)testSeqRepAST3 {
//    NSString *g = @"@start = foo; foo=(Word | Number)* QuotedString Symbol;";
//    
//    NSError *err = nil;
//    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    
//    TDNotNil(rootNode);
//    //    TDEqualObjects(@"(@start (foo (* (| Word Number)) QuotedString))"), [rootNode treeDescription]);
//    TDEqualObjects(@"(@start:SEQ (foo:SEQ (:* (:| :Word :Number)) :QuotedString :Symbol))", [rootNode treeDescription]);
//    
//}
//
//
//- (void)testAltPrecedenceAST {
//    NSString *g = @"@start = foo; foo=Word | Number Symbol;";
//    
//    NSError *err = nil;
//    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    
//    TDNotNil(rootNode);
//    TDEqualObjects(@"(@start:SEQ (foo:| :Word (:SEQ :Number :Symbol)))", [rootNode treeDescription]);
//    
//}
//
//
//- (void)testAltPrecedenceAST2 {
//    NSString *g = @"@start = foo; foo=Word Number | Symbol;";
//    
//    NSError *err = nil;
//    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    
//    TDNotNil(rootNode);
//    TDEqualObjects(@"(@start:SEQ (foo:| (:SEQ :Word :Number) :Symbol))", [rootNode treeDescription]);
//    
//}
//
//
//- (void)testLiteral {
//    NSString *g = @"@start = '$' '%';";
//    
//    NSError *err = nil;
//    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    
//    TDNotNil(rootNode);
//    TDEqualObjects(@"(@start:SEQ :'$' :'%')", [rootNode treeDescription]);
//    
//}
//
//
//- (void)testLiteral2 {
//    NSString *g = @"@start = ('$' '%')+;";
//    
//    NSError *err = nil;
//    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    
//    TDNotNil(rootNode);
//    TDEqualObjects(@"(@start:+ (:SEQ :'$' :'%'))", [rootNode treeDescription]);
//    
//}
//
//
//- (void)testLiteral3 {
//    NSString *g = @"@start = ((Word | Number)* | ('$' '%')) QuotedString+;";
//    
//    NSError *err = nil;
//    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    
//    TDNotNil(rootNode);
//    TDEqualObjects(@"(@start:SEQ (:| (:* (:| :Word :Number)) (:SEQ :'$' :'%')) (:+ :QuotedString))", [rootNode treeDescription]);
//    
//}
//
//
//- (void)testLiteral3_1 {
//    NSString *g = @"@start = Word QuotedString+;";
//    
//    NSError *err = nil;
//    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    
//    TDNotNil(rootNode);
//    TDEqualObjects(@"(@start:SEQ :Word (:+ :QuotedString))", [rootNode treeDescription]);
//    
//}
//
//
//- (void)testLiteral6 {
//    NSString *g = @"@start = QuotedString+;";
//    
//    NSError *err = nil;
//    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    
//    TDNotNil(rootNode);
//    TDEqualObjects(@"(@start:+ :QuotedString)", [rootNode treeDescription]);
//    
//}
//
//
//- (void)testLiteral4 {
//    NSString *g = @"@start = ((Word | Number)* | ('$' '%')+);";
//    
//    NSError *err = nil;
//    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    
//    TDNotNil(rootNode);
//    TDEqualObjects(@"(@start:| (:* (:| :Word :Number)) (:+ (:SEQ :'$' :'%')))", [rootNode treeDescription]);
//    
//}
//
//
//- (void)testLiteral5 {
//    NSString *g = @"@start = ((Word | Number)* | ('$' '%')+) QuotedString;";
//    
//    NSError *err = nil;
//    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    
//    TDNotNil(rootNode);
//    TDEqualObjects(@"(@start:SEQ (:| (:* (:| :Word :Number)) (:+ (:SEQ :'$' :'%'))) :QuotedString)", [rootNode treeDescription]);
//    
//}
//
//
//- (void)testCardinal {
//    NSString *g = @"@start=Number{1,2};";
//    
//    NSError *err = nil;
//    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    
//    TDNotNil(rootNode);
//    TDEqualObjects(@"(@start:{ :Number)", [rootNode treeDescription]);
//    
//}
//
//
//- (void)testCardinal2 {
//    NSString *g = @"@start=foo{2,4};foo=Number;";
//    
//    NSError *err = nil;
//    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    
//    TDNotNil(rootNode);
//    TDEqualObjects(@"(@start:{ foo:Number)", [rootNode treeDescription]);
//    
//}

@end
