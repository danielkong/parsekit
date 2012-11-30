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
    TDEqualObjects(@"(@start:SEQ (:SEQ (foo:SEQ (:SEQ (bar:SEQ (:| (:SEQ (baz:SEQ (:SEQ :Word))) (:SEQ (bat:SEQ (:SEQ :Number)))))))))", [rootNode treeDescription]);
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
    NSString *g = @"@start=foo;foo=Word;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (:SEQ (foo:SEQ (:SEQ :Word))))", [rootNode treeDescription]);
    //TDEqualObjects(@"(@start (foo (bar (| baz bat))))", [rootNode treeDescription]);
}


- (void)testAlternationAST2_1 {
    NSString *g = @"@start=foo;foo=Word|Number;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (:SEQ (foo:SEQ (:| (:SEQ :Word) (:SEQ :Number)))))", [rootNode treeDescription]);
    //TDEqualObjects(@"(@start (foo (bar (| baz bat))))", [rootNode treeDescription]);
}


- (void)testAlternationAST2_1_0 {
    NSString *g = @"@start=foo;foo=Word|Number Symbol;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (:SEQ (foo:SEQ (:| (:SEQ :Word) (:SEQ :Number :Symbol)))))", [rootNode treeDescription]);
    //TDEqualObjects(@"(@start (foo (bar (| baz bat))))", [rootNode treeDescription]);
}


- (void)testAlternationAST2_1_1 {
    NSString *g = @"@start=foo;foo=Word Number|Symbol;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (:SEQ (foo:SEQ (:| (:SEQ :Word :Number) (:SEQ :Symbol)))))", [rootNode treeDescription]);
    //TDEqualObjects(@"(@start (foo (bar (| baz bat))))", [rootNode treeDescription]);
}


- (void)testAlternationAST2_2 {
    NSString *g = @"@start=foo;foo=Word|Number Symbol QuotedString;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (:SEQ (foo:SEQ (:| (:SEQ :Word) (:SEQ :Number :Symbol :QuotedString)))))", [rootNode treeDescription]);
    //TDEqualObjects(@"(@start (foo (bar (| baz bat))))", [rootNode treeDescription]);
}


- (void)testAlternationAST2_3 {
    NSString *g = @"@start=foo;foo=(Word Number);";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (:SEQ (foo:SEQ (:SEQ (:SEQ :Word :Number)))))", [rootNode treeDescription]);
    //TDEqualObjects(@"(@start (foo (bar (| baz bat))))", [rootNode treeDescription]);
}


- (void)testAlternationAST2_4 {
    NSString *g = @"@start=foo;foo=(Word|Number);";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (:SEQ (foo:SEQ (:SEQ (:| (:SEQ :Word) (:SEQ :Number))))))", [rootNode treeDescription]);
    //TDEqualObjects(@"(@start (foo (bar (| baz bat))))", [rootNode treeDescription]);
}


- (void)testAlternationAST2_5 {
    NSString *g = @"@start=foo;foo=(Word|Number Symbol);";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (:SEQ (foo:SEQ (:SEQ (:| (:SEQ :Word) (:SEQ :Number :Symbol))))))", [rootNode treeDescription]);
    //TDEqualObjects(@"(@start (foo (bar (| baz bat))))", [rootNode treeDescription]);
}


- (void)testAlternationAST2_6 {
    NSString *g = @"@start=foo;foo=Word|(Number Symbol);";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (:SEQ (foo:SEQ (:| (:SEQ :Word) (:SEQ (:SEQ :Number :Symbol))))))", [rootNode treeDescription]);
    //TDEqualObjects(@"(@start (foo (bar (| baz bat))))", [rootNode treeDescription]);
}


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
//
- (void)testAlternationAST3 {
    NSString *g = @"@start=foo;foo=bar|baz;bar=Word;baz=Number;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (:SEQ (foo:SEQ (:| (:SEQ (bar:SEQ (:SEQ :Word))) (:SEQ (baz:SEQ (:SEQ :Number)))))))", [rootNode treeDescription]);
    //TDEqualObjects(@"(@start (foo (bar Word) (baz Number)))", [rootNode treeDescription]);
}


- (void)testSequenceAST {
    NSString *g = @"@start=foo;foo=QuotedString Number;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (:SEQ (foo:SEQ (:SEQ :QuotedString :Number))))", [rootNode treeDescription]);
}


- (void)testSubExprSequenceAST {
    NSString *g = @"@start=foo;foo=(QuotedString Number);";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (:SEQ (foo:SEQ (:SEQ (:SEQ :QuotedString :Number)))))", [rootNode treeDescription]);

    g = @"@start=foo;foo=( QuotedString Number );";
    
    err = nil;
    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (:SEQ (foo:SEQ (:SEQ (:SEQ :QuotedString :Number)))))", [rootNode treeDescription]);

    g = @"@start=foo; foo = ( QuotedString Number );";
    
    err = nil;
    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (:SEQ (foo:SEQ (:SEQ (:SEQ :QuotedString :Number)))))", [rootNode treeDescription]);
}


- (void)testDifferenceAST {
    NSString *g = @"@start=foo;foo=Any-Word;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (:SEQ (foo:SEQ (:SEQ (:- :Any :Word)))))", [rootNode treeDescription]);

    g = @"@start=foo;foo=Any - Word;";
    
    err = nil;
    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (:SEQ (foo:SEQ (:SEQ (:- :Any :Word)))))", [rootNode treeDescription]);

    g = @"@start=foo;foo=Any -Word;";
    
    err = nil;
    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (:SEQ (foo:SEQ (:SEQ (:- :Any :Word)))))", [rootNode treeDescription]);

    g = @"@start=foo;foo=Any- Word;";
    
    err = nil;
    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (:SEQ (foo:SEQ (:SEQ (:- :Any :Word)))))", [rootNode treeDescription]);
}


- (void)testIntersectionAST {
    NSString *g = @"@start=foo;foo=Word&LowercaseWord;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (:SEQ (foo:SEQ (:SEQ (:& :Word :LowercaseWord)))))", [rootNode treeDescription]);
    
    g = @"@start=foo;foo=Word & LowercaseWord;";
    
    err = nil;
    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (:SEQ (foo:SEQ (:SEQ (:& :Word :LowercaseWord)))))", [rootNode treeDescription]);
    
    g = @"@start=foo;foo=Word &LowercaseWord;";
    
    err = nil;
    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (:SEQ (foo:SEQ (:SEQ (:& :Word :LowercaseWord)))))", [rootNode treeDescription]);
    
    g = @"@start=foo;foo=Word& LowercaseWord;";
    
    err = nil;
    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (:SEQ (foo:SEQ (:SEQ (:& :Word :LowercaseWord)))))", [rootNode treeDescription]);
}


- (void)testStarAST {
    NSString *g = @"@start=foo;foo=Word*;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (:SEQ (foo:SEQ (:SEQ (:* :Word)))))", [rootNode treeDescription]);
    
    g = @"@start=foo;foo=Word *;";
    
    err = nil;
    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (:SEQ (foo:SEQ (:SEQ (:* :Word)))))", [rootNode treeDescription]);
}


- (void)testQuestionAST {
    NSString *g = @"@start=foo;foo=Word?;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (:SEQ (foo:SEQ (:SEQ (:? :Word)))))", [rootNode treeDescription]);
    
    g = @"@start=foo;foo=Word ?;";
    
    err = nil;
    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (:SEQ (foo:SEQ (:SEQ (:? :Word)))))", [rootNode treeDescription]);
}


- (void)testPlusAST {
    NSString *g = @"@start=foo;foo=Word+;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (:SEQ (foo:SEQ (:SEQ (:+ :Word)))))", [rootNode treeDescription]);
    
    g = @"@start=foo;foo=Word +;";
    
    err = nil;
    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (:SEQ (foo:SEQ (:SEQ (:+ :Word)))))", [rootNode treeDescription]);
}


- (void)testNegationAST {
    NSString *g = @"@start=foo;foo=~Word;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (:SEQ (foo:SEQ (:SEQ (:~ :Word)))))", [rootNode treeDescription]);
    
    g = @"@start=foo;foo= ~Word;";
    
    err = nil;
    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (:SEQ (foo:SEQ (:SEQ (:~ :Word)))))", [rootNode treeDescription]);

    g = @"@start=foo;foo= ~ Word;";
    
    err = nil;
    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (:SEQ (foo:SEQ (:SEQ (:~ :Word)))))", [rootNode treeDescription]);
}


- (void)testPatternAST {
    NSString *g = @"@start=foo;foo=/\\w/;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (:SEQ (foo:SEQ (:SEQ :/\\w/))))", [rootNode treeDescription]);
    
    g = @"@start=foo;foo = /\\w/;";
    
    err = nil;
    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (:SEQ (foo:SEQ (:SEQ :/\\w/))))", [rootNode treeDescription]);
}


- (void)testSimplifyAST {
    NSString *g = @"@start=foo;foo=Symbol;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (:SEQ (foo:SEQ (:SEQ :Symbol))))", [rootNode treeDescription]);
    
}


- (void)testSubExprAST {
    NSString *g = @"@start = (Number)*;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (:SEQ (:* (:SEQ :Number))))", [rootNode treeDescription]);
    
}


- (void)testSeqRepAST {
    NSString *g = @"@start = (Word | Number)* QuotedString;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (:SEQ (:* (:| (:SEQ :Word) (:SEQ :Number))) :QuotedString))", [rootNode treeDescription]);
    
}


- (void)testSeqRepAST2 {
    NSString *g = @"@start = foo; foo=(Word | Number)* QuotedString;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    
    TDNotNil(rootNode);
    //    TDEqualObjects(@"(@start (foo (* (| Word Number)) QuotedString))"), [rootNode treeDescription]);
    TDEqualObjects(@"(@start:SEQ (:SEQ (foo:SEQ (:SEQ (:* (:| (:SEQ :Word) (:SEQ :Number))) :QuotedString))))", [rootNode treeDescription]);
    
}


- (void)testSeqRepAST3 {
    NSString *g = @"@start = foo; foo=(Word | Number)* QuotedString Symbol;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    
    TDNotNil(rootNode);
    //    TDEqualObjects(@"(@start (foo (* (| Word Number)) QuotedString))"), [rootNode treeDescription]);
    TDEqualObjects(@"(@start:SEQ (:SEQ (foo:SEQ (:SEQ (:* (:| (:SEQ :Word) (:SEQ :Number))) :QuotedString :Symbol))))", [rootNode treeDescription]);
    
}


- (void)testAltPrecedenceAST {
    NSString *g = @"@start = foo; foo=Word | Number Symbol;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (:SEQ (foo:SEQ (:| (:SEQ :Word) (:SEQ :Number :Symbol)))))", [rootNode treeDescription]);
    
}


- (void)testAltPrecedenceAST2 {
    NSString *g = @"@start = foo; foo=Word Number | Symbol;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (:SEQ (foo:SEQ (:| (:SEQ :Word :Number) (:SEQ :Symbol)))))", [rootNode treeDescription]);
    
}


- (void)testLiteral {
    NSString *g = @"@start = '$' '%';";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (:SEQ :'$' :'%'))", [rootNode treeDescription]);
    
}


- (void)testLiteral2 {
    NSString *g = @"@start = ('$' '%')+;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (:SEQ (:+ (:SEQ :'$' :'%'))))", [rootNode treeDescription]);
    
}


//- (void)testLiteral3 {
//    NSString *g = @"@start = ((Word | Number)* | ('$' '%')) QuotedString+;";
//    
//    NSError *err = nil;
//    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    
//    TDNotNil(rootNode);
//    TDEqualObjects(@"(@start:SEQ (:SEQ (:| (:SEQ (:* (:| (:SEQ :Word) (:SEQ :Number)))) (:SEQ (:SEQ :'$' :'%'))) (:+ :QuotedString)))", [rootNode treeDescription]);
//    
//}


- (void)testLiteral6 {
    NSString *g = @"@start = QuotedString+;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:SEQ (:SEQ (:+ :QuotedString)))", [rootNode treeDescription]);
    
}


//- (void)testLiteral4 {
//    NSString *g = @"@start = ((Word | Number)* | ('$' '%')+);";
//    
//    NSError *err = nil;
//    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    
//    TDNotNil(rootNode);
//    TDEqualObjects(@"(@start:SEQ (:| (:* (:| :Word :Number)) (:+ (:SEQ :'$' :'%'))))", [rootNode treeDescription]);
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

@end
