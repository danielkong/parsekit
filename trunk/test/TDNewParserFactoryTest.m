//
//  TDNewParserFactoryTest.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/3/12.
//
//

#import "TDNewParserFactoryTest.h"
#import "TDParserFactory.h"
#import "PKAST.h"

@interface TDNewParserFactoryTest ()
@property (nonatomic, retain) TDParserFactory *factory;
@end

@implementation TDNewParserFactoryTest

- (void)setUp {
    self.factory = [TDParserFactory factory];
}


- (void)tearDown {
    self.factory = nil;
}


- (void)testAlternationSyntax {
    NSString *g = @"@start=foo;foo=bar;bar=baz|bat;baz=Word;bat=Num;";

    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g error:&err];
    TDNotNil(rootNode);
    TDEqualObjects([rootNode treeDescription], @"(@start (foo (bar (| (baz Word) (bat Num)))))");    
}


- (void)testSequenceSyntax {
    NSString *g = @"@start=foo;foo=QuotedString Num;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g error:&err];
    TDNotNil(rootNode);
    TDEqualObjects([rootNode treeDescription], @"(@start (foo QuotedString Num))");
}


- (void)testSubExprSequenceSyntax {
    NSString *g = @"@start=foo;foo=(QuotedString Num);";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g error:&err];
    TDNotNil(rootNode);
    TDEqualObjects([rootNode treeDescription], @"(@start (foo (SEQ QuotedString Num)))");

    g = @"@start=foo;foo=( QuotedString Num );";
    
    err = nil;
    rootNode = [_factory ASTFromGrammar:g error:&err];
    TDNotNil(rootNode);
    TDEqualObjects([rootNode treeDescription], @"(@start (foo (SEQ QuotedString Num)))");

    g = @"@start=foo; foo = ( QuotedString Num );";
    
    err = nil;
    rootNode = [_factory ASTFromGrammar:g error:&err];
    TDNotNil(rootNode);
    TDEqualObjects([rootNode treeDescription], @"(@start (foo (SEQ QuotedString Num)))");
}


- (void)testDifferenceSyntax {
    NSString *g = @"@start=foo;foo=Any-Word;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g error:&err];
    TDNotNil(rootNode);
    TDEqualObjects([rootNode treeDescription], @"(@start (foo (- Any Word)))");

    g = @"@start=foo;foo=Any - Word;";
    
    err = nil;
    rootNode = [_factory ASTFromGrammar:g error:&err];
    TDNotNil(rootNode);
    TDEqualObjects([rootNode treeDescription], @"(@start (foo (- Any Word)))");

    g = @"@start=foo;foo=Any -Word;";
    
    err = nil;
    rootNode = [_factory ASTFromGrammar:g error:&err];
    TDNotNil(rootNode);
    TDEqualObjects([rootNode treeDescription], @"(@start (foo (- Any Word)))");

    g = @"@start=foo;foo=Any- Word;";
    
    err = nil;
    rootNode = [_factory ASTFromGrammar:g error:&err];
    TDNotNil(rootNode);
    TDEqualObjects([rootNode treeDescription], @"(@start (foo (- Any Word)))");
}


- (void)testIntersectionSyntax {
    NSString *g = @"@start=foo;foo=Word&LowercaseWord;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g error:&err];
    TDNotNil(rootNode);
    TDEqualObjects([rootNode treeDescription], @"(@start (foo (& Word LowercaseWord)))");
    
    g = @"@start=foo;foo=Word & LowercaseWord;";
    
    err = nil;
    rootNode = [_factory ASTFromGrammar:g error:&err];
    TDNotNil(rootNode);
    TDEqualObjects([rootNode treeDescription], @"(@start (foo (& Word LowercaseWord)))");
    
    g = @"@start=foo;foo=Word &LowercaseWord;";
    
    err = nil;
    rootNode = [_factory ASTFromGrammar:g error:&err];
    TDNotNil(rootNode);
    TDEqualObjects([rootNode treeDescription], @"(@start (foo (& Word LowercaseWord)))");
    
    g = @"@start=foo;foo=Word& LowercaseWord;";
    
    err = nil;
    rootNode = [_factory ASTFromGrammar:g error:&err];
    TDNotNil(rootNode);
    TDEqualObjects([rootNode treeDescription], @"(@start (foo (& Word LowercaseWord)))");
}


- (void)testStarSyntax {
    NSString *g = @"@start=foo;foo=Word*;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g error:&err];
    TDNotNil(rootNode);
    TDEqualObjects([rootNode treeDescription], @"(@start (foo (* Word)))");
    
    g = @"@start=foo;foo=Word *;";
    
    err = nil;
    rootNode = [_factory ASTFromGrammar:g error:&err];
    TDNotNil(rootNode);
    TDEqualObjects([rootNode treeDescription], @"(@start (foo (* Word)))");
}


- (void)testQuestionSyntax {
    NSString *g = @"@start=foo;foo=Word?;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g error:&err];
    TDNotNil(rootNode);
    TDEqualObjects([rootNode treeDescription], @"(@start (foo (? Word)))");
    
    g = @"@start=foo;foo=Word ?;";
    
    err = nil;
    rootNode = [_factory ASTFromGrammar:g error:&err];
    TDNotNil(rootNode);
    TDEqualObjects([rootNode treeDescription], @"(@start (foo (? Word)))");
}


- (void)testPlusSyntax {
    NSString *g = @"@start=foo;foo=Word+;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g error:&err];
    TDNotNil(rootNode);
    TDEqualObjects([rootNode treeDescription], @"(@start (foo (+ Word)))");
    
    g = @"@start=foo;foo=Word +;";
    
    err = nil;
    rootNode = [_factory ASTFromGrammar:g error:&err];
    TDNotNil(rootNode);
    TDEqualObjects([rootNode treeDescription], @"(@start (foo (+ Word)))");
}


- (void)testNegationSyntax {
    NSString *g = @"@start=foo;foo=~Word;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g error:&err];
    TDNotNil(rootNode);
    TDEqualObjects([rootNode treeDescription], @"(@start (foo (~ Word)))");
    
    g = @"@start=foo;foo= ~Word;";
    
    err = nil;
    rootNode = [_factory ASTFromGrammar:g error:&err];
    TDNotNil(rootNode);
    TDEqualObjects([rootNode treeDescription], @"(@start (foo (~ Word)))");

    g = @"@start=foo;foo= ~ Word;";
    
    err = nil;
    rootNode = [_factory ASTFromGrammar:g error:&err];
    TDNotNil(rootNode);
    TDEqualObjects([rootNode treeDescription], @"(@start (foo (~ Word)))");
}

@end
