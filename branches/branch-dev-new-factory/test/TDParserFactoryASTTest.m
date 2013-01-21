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
    TDEqualObjects(@"(@start:DEF (:SEQ (foo:DEF (:SEQ (bar:DEF (:| (:SEQ (baz:DEF (:SEQ :Word))) (:SEQ (bat:DEF (:SEQ :Number)))))))))", [rootNode fullTreeDescription:[_factory symbolTableFromGrammar:g error:nil]]);
    //TDEqualObjects(@"(@start (foo (bar (| (baz Word) (bat Number)))))", [rootNode fullTreeDescription:[_factory symbolTableFromGrammar:g error:nil]]);
}


/*
 @start = foo; foo = Word|Number;
 
 (@start (foo (| Word Number)))
 (@start:DEF (foo:DEF (:| :Word :Number)))
 
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
    TDEqualObjects(@"(@start:DEF (:SEQ (foo:DEF (:SEQ :Word))))", [rootNode fullTreeDescription:[_factory symbolTableFromGrammar:g error:nil]]);
    //TDEqualObjects(@"(@start (foo (bar (| baz bat))))", [rootNode fullTreeDescription:[_factory symbolTableFromGrammar:g error:nil]]);
}


- (void)testAlternationAST2_1 {
    NSString *g = @"@start=foo;foo=Word|Number;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:DEF (:SEQ (foo:DEF (:| (:SEQ :Word) (:SEQ :Number)))))", [rootNode fullTreeDescription:[_factory symbolTableFromGrammar:g error:nil]]);
    //TDEqualObjects(@"(@start (foo (bar (| baz bat))))", [rootNode fullTreeDescription:[_factory symbolTableFromGrammar:g error:nil]]);
}


- (void)testAlternationAST2_1_0 {
    NSString *g = @"@start=foo;foo=Word|Number Symbol;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:DEF (:SEQ (foo:DEF (:| (:SEQ :Word) (:SEQ :Number :Symbol)))))", [rootNode fullTreeDescription:[_factory symbolTableFromGrammar:g error:nil]]);
    //TDEqualObjects(@"(@start (foo (bar (| baz bat))))", [rootNode fullTreeDescription:[_factory symbolTableFromGrammar:g error:nil]]);
}


- (void)testAlternationAST2_1_1 {
    NSString *g = @"@start=foo;foo=Word Number|Symbol;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:DEF (:SEQ (foo:DEF (:| (:SEQ :Word :Number) (:SEQ :Symbol)))))", [rootNode fullTreeDescription:[_factory symbolTableFromGrammar:g error:nil]]);
    //TDEqualObjects(@"(@start (foo (bar (| baz bat))))", [rootNode fullTreeDescription:[_factory symbolTableFromGrammar:g error:nil]]);
}


- (void)testAlternationAST2_2 {
    NSString *g = @"@start=foo;foo=Word|Number Symbol QuotedString;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:DEF (:SEQ (foo:DEF (:| (:SEQ :Word) (:SEQ :Number :Symbol :QuotedString)))))", [rootNode fullTreeDescription:[_factory symbolTableFromGrammar:g error:nil]]);
    //TDEqualObjects(@"(@start (foo (bar (| baz bat))))", [rootNode fullTreeDescription:[_factory symbolTableFromGrammar:g error:nil]]);
}


- (void)testAlternationAST2_3 {
    NSString *g = @"@start=foo;foo=(Word Number);";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:DEF (:SEQ (foo:DEF (:SEQ (:SEQ :Word :Number)))))", [rootNode fullTreeDescription:[_factory symbolTableFromGrammar:g error:nil]]);
    //TDEqualObjects(@"(@start (foo (bar (| baz bat))))", [rootNode fullTreeDescription:[_factory symbolTableFromGrammar:g error:nil]]);
}


- (void)testAlternationAST2_4 {
    NSString *g = @"@start=foo;foo=(Word|Number);";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:DEF (:SEQ (foo:DEF (:SEQ (:| (:SEQ :Word) (:SEQ :Number))))))", [rootNode fullTreeDescription:[_factory symbolTableFromGrammar:g error:nil]]);
    //TDEqualObjects(@"(@start (foo (bar (| baz bat))))", [rootNode fullTreeDescription:[_factory symbolTableFromGrammar:g error:nil]]);
}


- (void)testAlternationAST2_5 {
    NSString *g = @"@start=foo;foo=(Word|Number Symbol);";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:DEF (:SEQ (foo:DEF (:SEQ (:| (:SEQ :Word) (:SEQ :Number :Symbol))))))", [rootNode fullTreeDescription:[_factory symbolTableFromGrammar:g error:nil]]);
    //TDEqualObjects(@"(@start (foo (bar (| baz bat))))", [rootNode fullTreeDescription:[_factory symbolTableFromGrammar:g error:nil]]);
}


- (void)testAlternationAST2_6 {
    NSString *g = @"@start=foo;foo=Word|(Number Symbol);";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:DEF (:SEQ (foo:DEF (:| (:SEQ :Word) (:SEQ (:SEQ :Number :Symbol))))))", [rootNode fullTreeDescription:[_factory symbolTableFromGrammar:g error:nil]]);
    //TDEqualObjects(@"(@start (foo (bar (| baz bat))))", [rootNode fullTreeDescription:[_factory symbolTableFromGrammar:g error:nil]]);
}


/*
 @start = foo; foo = bar|baz; bar=Word; baz=Number;
 
 (@start (foo (| (bar Word) (baz Number))))
 (@start:DEF (foo:DEF (:| (bar:DEF Word) (baz:DEF Number))))
 
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
    TDEqualObjects(@"(@start:DEF (:SEQ (foo:DEF (:| (:SEQ (bar:DEF (:SEQ :Word))) (:SEQ (baz:DEF (:SEQ :Number)))))))", [rootNode fullTreeDescription:[_factory symbolTableFromGrammar:g error:nil]]);
    //TDEqualObjects(@"(@start (foo (bar Word) (baz Number)))", [rootNode fullTreeDescription:[_factory symbolTableFromGrammar:g error:nil]]);
}


- (void)testSequenceAST {
    NSString *g = @"@start=foo;foo=QuotedString Number;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:DEF (:SEQ (foo:DEF (:SEQ :QuotedString :Number))))", [rootNode fullTreeDescription:[_factory symbolTableFromGrammar:g error:nil]]);
}


- (void)testSubExprSequenceAST {
    NSString *g = @"@start=foo;foo=(QuotedString Number);";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:DEF (:SEQ (foo:DEF (:SEQ (:SEQ :QuotedString :Number)))))", [rootNode fullTreeDescription:[_factory symbolTableFromGrammar:g error:nil]]);

    g = @"@start=foo;foo=( QuotedString Number );";
    
    err = nil;
    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:DEF (:SEQ (foo:DEF (:SEQ (:SEQ :QuotedString :Number)))))", [rootNode fullTreeDescription:[_factory symbolTableFromGrammar:g error:nil]]);

    g = @"@start=foo; foo = ( QuotedString Number );";
    
    err = nil;
    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:DEF (:SEQ (foo:DEF (:SEQ (:SEQ :QuotedString :Number)))))", [rootNode fullTreeDescription:[_factory symbolTableFromGrammar:g error:nil]]);
}


- (void)testDifferenceAST {
    NSString *g = @"@start=foo;foo=Any-Word;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:DEF (:SEQ (foo:DEF (:SEQ (:- :Any :Word)))))", [rootNode fullTreeDescription:[_factory symbolTableFromGrammar:g error:nil]]);

    g = @"@start=foo;foo=Any - Word;";
    
    err = nil;
    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:DEF (:SEQ (foo:DEF (:SEQ (:- :Any :Word)))))", [rootNode fullTreeDescription:[_factory symbolTableFromGrammar:g error:nil]]);

    g = @"@start=foo;foo=Any -Word;";
    
    err = nil;
    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:DEF (:SEQ (foo:DEF (:SEQ (:- :Any :Word)))))", [rootNode fullTreeDescription:[_factory symbolTableFromGrammar:g error:nil]]);

    g = @"@start=foo;foo=Any- Word;";
    
    err = nil;
    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:DEF (:SEQ (foo:DEF (:SEQ (:- :Any :Word)))))", [rootNode fullTreeDescription:[_factory symbolTableFromGrammar:g error:nil]]);
}


- (void)testIntersectionAST {
    NSString *g = @"@start=foo;foo=Word&LowercaseWord;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:DEF (:SEQ (foo:DEF (:SEQ (:& :Word :LowercaseWord)))))", [rootNode fullTreeDescription:[_factory symbolTableFromGrammar:g error:nil]]);
    
    g = @"@start=foo;foo=Word & LowercaseWord;";
    
    err = nil;
    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:DEF (:SEQ (foo:DEF (:SEQ (:& :Word :LowercaseWord)))))", [rootNode fullTreeDescription:[_factory symbolTableFromGrammar:g error:nil]]);
    
    g = @"@start=foo;foo=Word &LowercaseWord;";
    
    err = nil;
    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:DEF (:SEQ (foo:DEF (:SEQ (:& :Word :LowercaseWord)))))", [rootNode fullTreeDescription:[_factory symbolTableFromGrammar:g error:nil]]);
    
    g = @"@start=foo;foo=Word& LowercaseWord;";
    
    err = nil;
    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:DEF (:SEQ (foo:DEF (:SEQ (:& :Word :LowercaseWord)))))", [rootNode fullTreeDescription:[_factory symbolTableFromGrammar:g error:nil]]);
}


- (void)testStarAST {
    NSString *g = @"@start=foo;foo=Word*;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:DEF (:SEQ (foo:DEF (:SEQ (:* :Word)))))", [rootNode fullTreeDescription:[_factory symbolTableFromGrammar:g error:nil]]);
    
    g = @"@start=foo;foo=Word *;";
    
    err = nil;
    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:DEF (:SEQ (foo:DEF (:SEQ (:* :Word)))))", [rootNode fullTreeDescription:[_factory symbolTableFromGrammar:g error:nil]]);
}


- (void)testQuestionAST {
    NSString *g = @"@start=foo;foo=Word?;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:DEF (:SEQ (foo:DEF (:SEQ (:? :Word)))))", [rootNode fullTreeDescription:[_factory symbolTableFromGrammar:g error:nil]]);
    
    g = @"@start=foo;foo=Word ?;";
    
    err = nil;
    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:DEF (:SEQ (foo:DEF (:SEQ (:? :Word)))))", [rootNode fullTreeDescription:[_factory symbolTableFromGrammar:g error:nil]]);
}


- (void)testPlusAST {
    NSString *g = @"@start=foo;foo=Word+;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:DEF (:SEQ (foo:DEF (:SEQ (:+ :Word)))))", [rootNode fullTreeDescription:[_factory symbolTableFromGrammar:g error:nil]]);
    
    g = @"@start=foo;foo=Word +;";
    
    err = nil;
    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:DEF (:SEQ (foo:DEF (:SEQ (:+ :Word)))))", [rootNode fullTreeDescription:[_factory symbolTableFromGrammar:g error:nil]]);
}


- (void)testNegationAST {
    NSString *g = @"@start=foo;foo=~Word;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:DEF (:SEQ (foo:DEF (:SEQ (:~ :Word)))))", [rootNode fullTreeDescription:[_factory symbolTableFromGrammar:g error:nil]]);
    
    g = @"@start=foo;foo= ~Word;";
    
    err = nil;
    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:DEF (:SEQ (foo:DEF (:SEQ (:~ :Word)))))", [rootNode fullTreeDescription:[_factory symbolTableFromGrammar:g error:nil]]);

    g = @"@start=foo;foo= ~ Word;";
    
    err = nil;
    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:DEF (:SEQ (foo:DEF (:SEQ (:~ :Word)))))", [rootNode fullTreeDescription:[_factory symbolTableFromGrammar:g error:nil]]);
}


- (void)testPatternAST {
    NSString *g = @"@start=foo;foo=/\\w/;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:DEF (:SEQ (foo:DEF (:SEQ :/\\w/))))", [rootNode fullTreeDescription:[_factory symbolTableFromGrammar:g error:nil]]);
    
    g = @"@start=foo;foo = /\\w/;";
    
    err = nil;
    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:DEF (:SEQ (foo:DEF (:SEQ :/\\w/))))", [rootNode fullTreeDescription:[_factory symbolTableFromGrammar:g error:nil]]);
}


- (void)testSimplifyAST {
    NSString *g = @"@start=foo;foo=Symbol;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:DEF (:SEQ (foo:DEF (:SEQ :Symbol))))", [rootNode fullTreeDescription:[_factory symbolTableFromGrammar:g error:nil]]);
    
}


- (void)testSubExprAST {
    NSString *g = @"@start = (Number)*;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:DEF (:SEQ (:* (:SEQ :Number))))", [rootNode fullTreeDescription:[_factory symbolTableFromGrammar:g error:nil]]);
    
}


- (void)testSeqRepAST {
    NSString *g = @"@start = (Word | Number)* QuotedString;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:DEF (:SEQ (:* (:| (:SEQ :Word) (:SEQ :Number))) :QuotedString))", [rootNode fullTreeDescription:[_factory symbolTableFromGrammar:g error:nil]]);
    
}


- (void)testSeqRepAST2 {
    NSString *g = @"@start = foo; foo=(Word | Number)* QuotedString;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    
    TDNotNil(rootNode);
    //    TDEqualObjects(@"(@start (foo (* (| Word Number)) QuotedString))"), [rootNode fullTreeDescription:[_factory symbolTableFromGrammar:g error:nil]]);
    TDEqualObjects(@"(@start:DEF (:SEQ (foo:DEF (:SEQ (:* (:| (:SEQ :Word) (:SEQ :Number))) :QuotedString))))", [rootNode fullTreeDescription:[_factory symbolTableFromGrammar:g error:nil]]);
    
}


- (void)testSeqRepAST3 {
    NSString *g = @"@start = foo; foo=(Word | Number)* QuotedString Symbol;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    
    TDNotNil(rootNode);
    //    TDEqualObjects(@"(@start (foo (* (| Word Number)) QuotedString))"), [rootNode fullTreeDescription:[_factory symbolTableFromGrammar:g error:nil]]);
    TDEqualObjects(@"(@start:DEF (:SEQ (foo:DEF (:SEQ (:* (:| (:SEQ :Word) (:SEQ :Number))) :QuotedString :Symbol))))", [rootNode fullTreeDescription:[_factory symbolTableFromGrammar:g error:nil]]);
    
}


- (void)testAltPrecedenceAST {
    NSString *g = @"@start = foo; foo=Word | Number Symbol;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:DEF (:SEQ (foo:DEF (:| (:SEQ :Word) (:SEQ :Number :Symbol)))))", [rootNode fullTreeDescription:[_factory symbolTableFromGrammar:g error:nil]]);
    
}


- (void)testAltPrecedenceAST2 {
    NSString *g = @"@start = foo; foo=Word Number | Symbol;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:DEF (:SEQ (foo:DEF (:| (:SEQ :Word :Number) (:SEQ :Symbol)))))", [rootNode fullTreeDescription:[_factory symbolTableFromGrammar:g error:nil]]);
    
}


- (void)testLiteral {
    NSString *g = @"@start = '$' '%';";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:DEF (:SEQ :'$' :'%'))", [rootNode fullTreeDescription:[_factory symbolTableFromGrammar:g error:nil]]);
    
}


- (void)testLiteral2 {
    NSString *g = @"@start = ('$' '%')+;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:DEF (:SEQ (:+ (:SEQ :'$' :'%'))))", [rootNode fullTreeDescription:[_factory symbolTableFromGrammar:g error:nil]]);
    
}


- (void)testLiteral3 {
    NSString *g = @"@start = ((Word | Number)* | ('$' '%')) QuotedString+;";

    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];

    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:DEF (:SEQ (:| (:SEQ (:* (:| (:SEQ :Word) (:SEQ :Number)))) (:SEQ (:SEQ :'$' :'%'))) (:+ :QuotedString)))", [rootNode fullTreeDescription:[_factory symbolTableFromGrammar:g error:nil]]);

}


- (void)testLiteral3_1 {
    NSString *g = @"@start = Word QuotedString+;";

    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];

    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:DEF (:SEQ :Word (:+ :QuotedString)))", [rootNode fullTreeDescription:[_factory symbolTableFromGrammar:g error:nil]]);

}


- (void)testLiteral6 {
    NSString *g = @"@start = QuotedString+;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:DEF (:SEQ (:+ :QuotedString)))", [rootNode fullTreeDescription:[_factory symbolTableFromGrammar:g error:nil]]);
    
}


- (void)testLiteral4 {
    NSString *g = @"@start = ((Word | Number)* | ('$' '%')+);";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:DEF (:SEQ (:| (:SEQ (:* (:| (:SEQ :Word) (:SEQ :Number)))) (:SEQ (:+ (:SEQ :'$' :'%'))))))", [rootNode fullTreeDescription:[_factory symbolTableFromGrammar:g error:nil]]);
    
}


- (void)testLiteral5 {
    NSString *g = @"@start = ((Word | Number)* | ('$' '%')+) QuotedString;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    
    TDNotNil(rootNode);
    TDEqualObjects(@"(@start:DEF (:SEQ (:| (:SEQ (:* (:| (:SEQ :Word) (:SEQ :Number)))) (:SEQ (:+ (:SEQ :'$' :'%')))) :QuotedString))", [rootNode fullTreeDescription:[_factory symbolTableFromGrammar:g error:nil]]);
    
}

@end
