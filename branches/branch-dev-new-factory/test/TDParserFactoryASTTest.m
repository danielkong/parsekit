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
    TDEqualObjects([rootNode treeDescription], @"(@start:SEQ (foo:SEQ (bar:SEQ (nil:| (baz:SEQ nil:Word) (bat:SEQ nil:Number)))))");
    //TDEqualObjects([rootNode treeDescription], @"(@start (foo (bar (| (baz Word) (bat Number)))))");
}



/*
 @start = foo; foo = Word|Number;
 
 (@start (foo (| Word Number)))
 (@start:SEQ (foo:SEQ (nil:| nil:Word nil:Number)))
 
 (@start (foo Word Number))
 (@start (foo:| nil:Word nil:Number))
 
 (foo Word Number)
 (@foo:| nil:Word nil:Number)
 
 */


- (void)testAlternationAST2 {
    NSString *g = @"@start=foo;foo=Word|Number;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects([rootNode treeDescription], @"(@start:SEQ (foo:SEQ (nil:| nil:Word nil:Number)))");
    //TDEqualObjects([rootNode treeDescription], @"(@start (foo (bar (| baz bat))))");
}


/*
 @start = foo; foo = bar|baz; bar=Word; baz=Number;
 
 (@start (foo (| (bar Word) (baz Number))))
 (@start:SEQ (foo:SEQ (nil:| (bar:SEQ Word) (baz:SEQ Number))))
 
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
    TDEqualObjects([rootNode treeDescription], @"(@start:SEQ (foo:SEQ (nil:| (bar:SEQ nil:Word) (baz:SEQ nil:Number))))");
    //TDEqualObjects([rootNode treeDescription], @"(@start (foo (bar Word) (baz Number)))");
}


- (void)testSequenceAST {
    NSString *g = @"@start=foo;foo=QuotedString Number;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects([rootNode treeDescription], @"(@start:SEQ (foo:SEQ nil:QuotedString nil:Number))");
}


- (void)testSubExprSequenceAST {
    NSString *g = @"@start=foo;foo=(QuotedString Number);";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects([rootNode treeDescription], @"(@start:SEQ (foo:SEQ (nil:SEQ nil:QuotedString nil:Number)))");

    g = @"@start=foo;foo=( QuotedString Number );";
    
    err = nil;
    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects([rootNode treeDescription], @"(@start:SEQ (foo:SEQ (nil:SEQ nil:QuotedString nil:Number)))");

    g = @"@start=foo; foo = ( QuotedString Number );";
    
    err = nil;
    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects([rootNode treeDescription], @"(@start:SEQ (foo:SEQ (nil:SEQ nil:QuotedString nil:Number)))");
}


- (void)testDifferenceAST {
    NSString *g = @"@start=foo;foo=Any-Word;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects([rootNode treeDescription], @"(@start:SEQ (foo:SEQ (nil:- nil:Any nil:Word)))");

    g = @"@start=foo;foo=Any - Word;";
    
    err = nil;
    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects([rootNode treeDescription], @"(@start:SEQ (foo:SEQ (nil:- nil:Any nil:Word)))");

    g = @"@start=foo;foo=Any -Word;";
    
    err = nil;
    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects([rootNode treeDescription], @"(@start:SEQ (foo:SEQ (nil:- nil:Any nil:Word)))");

    g = @"@start=foo;foo=Any- Word;";
    
    err = nil;
    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
    TDNotNil(rootNode);
    TDEqualObjects([rootNode treeDescription], @"(@start:SEQ (foo:SEQ (nil:- nil:Any nil:Word)))");
}


//- (void)testIntersectionAST {
//    NSString *g = @"@start=foo;foo=Word&LowercaseWord;";
//    
//    NSError *err = nil;
//    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    TDNotNil(rootNode);
//    TDEqualObjects([rootNode treeDescription], @"(@start (foo (& Word LowercaseWord)))");
//    
//    g = @"@start=foo;foo=Word & LowercaseWord;";
//    
//    err = nil;
//    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    TDNotNil(rootNode);
//    TDEqualObjects([rootNode treeDescription], @"(@start (foo (& Word LowercaseWord)))");
//    
//    g = @"@start=foo;foo=Word &LowercaseWord;";
//    
//    err = nil;
//    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    TDNotNil(rootNode);
//    TDEqualObjects([rootNode treeDescription], @"(@start (foo (& Word LowercaseWord)))");
//    
//    g = @"@start=foo;foo=Word& LowercaseWord;";
//    
//    err = nil;
//    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    TDNotNil(rootNode);
//    TDEqualObjects([rootNode treeDescription], @"(@start (foo (& Word LowercaseWord)))");
//}
//
//
//- (void)testStarAST {
//    NSString *g = @"@start=foo;foo=Word*;";
//    
//    NSError *err = nil;
//    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    TDNotNil(rootNode);
//    TDEqualObjects([rootNode treeDescription], @"(@start (foo (* Word)))");
//    
//    g = @"@start=foo;foo=Word *;";
//    
//    err = nil;
//    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    TDNotNil(rootNode);
//    TDEqualObjects([rootNode treeDescription], @"(@start (foo (* Word)))");
//}
//
//
//- (void)testQuestionAST {
//    NSString *g = @"@start=foo;foo=Word?;";
//    
//    NSError *err = nil;
//    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    TDNotNil(rootNode);
//    TDEqualObjects([rootNode treeDescription], @"(@start (foo (? Word)))");
//    
//    g = @"@start=foo;foo=Word ?;";
//    
//    err = nil;
//    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    TDNotNil(rootNode);
//    TDEqualObjects([rootNode treeDescription], @"(@start (foo (? Word)))");
//}
//
//
//- (void)testPlusAST {
//    NSString *g = @"@start=foo;foo=Word+;";
//    
//    NSError *err = nil;
//    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    TDNotNil(rootNode);
//    TDEqualObjects([rootNode treeDescription], @"(@start (foo (+ Word)))");
//    
//    g = @"@start=foo;foo=Word +;";
//    
//    err = nil;
//    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    TDNotNil(rootNode);
//    TDEqualObjects([rootNode treeDescription], @"(@start (foo (+ Word)))");
//}
//
//
//- (void)testNegationAST {
//    NSString *g = @"@start=foo;foo=~Word;";
//    
//    NSError *err = nil;
//    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    TDNotNil(rootNode);
//    TDEqualObjects([rootNode treeDescription], @"(@start (foo (~ Word)))");
//    
//    g = @"@start=foo;foo= ~Word;";
//    
//    err = nil;
//    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    TDNotNil(rootNode);
//    TDEqualObjects([rootNode treeDescription], @"(@start (foo (~ Word)))");
//
//    g = @"@start=foo;foo= ~ Word;";
//    
//    err = nil;
//    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    TDNotNil(rootNode);
//    TDEqualObjects([rootNode treeDescription], @"(@start (foo (~ Word)))");
//}
//
//
//- (void)testPatternAST {
//    NSString *g = @"@start=foo;foo=/\\w/;";
//    
//    NSError *err = nil;
//    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    TDNotNil(rootNode);
//    TDEqualObjects([rootNode treeDescription], @"(@start (foo /\\w/))");
//    
//    g = @"@start=foo;foo = /\\w/;";
//    
//    err = nil;
//    rootNode = [_factory ASTFromGrammar:g simplify:NO error:&err];
//    TDNotNil(rootNode);
//    TDEqualObjects([rootNode treeDescription], @"(@start (foo /\\w/))");
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
//    //    TDEqualObjects([rootNode treeDescription], @"(@start foo)");
//    TDEqualObjects([rootNode treeDescription], @"(@start (foo Symbol))");
//    
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
//    TDEqualObjects([rootNode treeDescription], @"(@start (* Number))");
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
//    //    TDEqualObjects([rootNode treeDescription], @"(@start (* (| Word Number)) QuotedString)");
//    TDEqualObjects([rootNode treeDescription], @"(@start (SEQ (* (| Word Number)) QuotedString))");
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
//    //    TDEqualObjects([rootNode treeDescription], @"(@start (foo (* (| Word Number)) QuotedString))");
//    TDEqualObjects([rootNode treeDescription], @"(@start (foo (SEQ (* (| Word Number)) QuotedString)))");
//    
//}

@end
