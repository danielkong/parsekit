//
//  TDParserFactoryParserTest.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/5/12.
//
//

#import "TDParserFactoryParserTest.h"
#import "PKParserFactory.h"
#import "PKAST.h"

@interface TDParserFactoryParserTest ()
@property (nonatomic, retain) PKParserFactory *factory;
@end

@implementation TDParserFactoryParserTest

- (void)setUp {
    self.factory = [PKParserFactory factory];
}


- (void)tearDown {
    self.factory = nil;
}


- (void)testDifferenceAST {
    NSString *g = @"@start=Number - '1';";
    //    NSString *g = @"@start=foo foo foo? foo?;foo=Number;";
    
    NSError *err = nil;
    PKCollectionParser *p = (PKCollectionParser *)[_factory parserFromGrammar:g assembler:nil error:&err];
    
    TDNotNil(p);
    TDTrue([p isKindOfClass:[PKParser class]]);
    
    NSString *input = @"1";
    PKAssembly *a = [PKTokenAssembly assemblyWithString:input];
    a = [p completeMatchFor:a];
    
    TDNil(a);
    
    input = @"2 2";
    a = [PKTokenAssembly assemblyWithString:input];
    a = [p bestMatchFor:a];
    
    TDEqualObjects([a description], @"[2]2^2");
}


- (void)testNegationAST {
    NSString *g = @"@start=~Word;";
    //    NSString *g = @"@start=foo foo foo? foo?;foo=Number;";
    
    NSError *err = nil;
    PKCollectionParser *p = (PKCollectionParser *)[_factory parserFromGrammar:g assembler:nil error:&err];
    
    TDNotNil(p);
    TDTrue([p isKindOfClass:[PKParser class]]);
    
    NSString *input = @"foo";
    PKAssembly *a = [PKTokenAssembly assemblyWithString:input];
    a = [p completeMatchFor:a];
    
    TDNil(a);
    
    input = @"2 2";
    a = [PKTokenAssembly assemblyWithString:input];
    a = [p bestMatchFor:a];
    
    TDEqualObjects([a description], @"[2]2^2");
}


- (void)testDelimitAST {
    NSString *g = @"@symbols='<?=';@start=%{'<?=', '>'};";
    //    NSString *g = @"@start=foo foo foo? foo?;foo=Number;";
    
    NSError *err = nil;
    PKCollectionParser *p = (PKCollectionParser *)[_factory parserFromGrammar:g assembler:nil error:&err];
    
    TDNotNil(p);
    TDTrue([p isKindOfClass:[PKParser class]]);
    
    NSString *input = @"<?= foobar baz >";
    PKAssembly *a = [PKTokenAssembly assemblyWithString:input];
    a = [p completeMatchFor:a];

    TDEqualObjects(@"[<?=, foobar, baz, >]<?=/foobar/baz/>^", [a description]);
}


- (void)testCardinalAST {
    NSString *g = @"@start=Word|foo{2,4};foo=Number;";
    //    NSString *g = @"@start=foo foo foo? foo?;foo=Number;";
    
    NSError *err = nil;
    PKCollectionParser *p = (PKCollectionParser *)[_factory parserFromGrammar:g assembler:nil error:&err];
    
    TDNotNil(p);
    TDTrue([p isKindOfClass:[PKParser class]]);
    
    NSString *input = @"1";
    PKAssembly *a = [PKTokenAssembly assemblyWithString:input];
    a = [p completeMatchFor:a];
    
    TDNil(a);
    
    input = @"1 2";
    a = [PKTokenAssembly assemblyWithString:input];
    a = [p bestMatchFor:a];
    
    TDEqualObjects([a description], @"[1, 2]1/2^");
    
    input = @"1 2 3";
    a = [PKTokenAssembly assemblyWithString:input];
    a = [p bestMatchFor:a];
    
    TDEqualObjects([a description], @"[1, 2, 3]1/2/3^");
    
    input = @"1 2 3 4";
    a = [PKTokenAssembly assemblyWithString:input];
    a = [p bestMatchFor:a];
    
    TDEqualObjects([a description], @"[1, 2, 3, 4]1/2/3/4^");
    
    input = @"1 2 3 4 5";
    a = [PKTokenAssembly assemblyWithString:input];
    a = [p bestMatchFor:a];
    
    TDEqualObjects([a description], @"[1, 2, 3, 4]1/2/3/4^5");
    
    input = @"1 2 3 4 5 6";
    a = [PKTokenAssembly assemblyWithString:input];
    a = [p bestMatchFor:a];
    
    TDEqualObjects([a description], @"[1, 2, 3, 4]1/2/3/4^5/6");
    
}


- (void)testCardinalAST2 {
    NSString *g = @"@start=foo{2,4};foo=Number;";
    //    NSString *g = @"@start=foo foo foo? foo?;foo=Number;";
    
    NSError *err = nil;
    PKCollectionParser *p = (PKCollectionParser *)[_factory parserFromGrammar:g assembler:nil error:&err];
    
    TDNotNil(p);
    TDTrue([p isKindOfClass:[PKParser class]]);
    
    NSString *input = @"1";
    PKAssembly *a = [PKTokenAssembly assemblyWithString:input];
    a = [p completeMatchFor:a];
    
    TDNil(a);
    
    input = @"1 2";
    a = [PKTokenAssembly assemblyWithString:input];
    a = [p bestMatchFor:a];
    
    TDEqualObjects(@"[1, 2]1/2^", [a description]);
    
    input = @"1 2 3";
    a = [PKTokenAssembly assemblyWithString:input];
    a = [p bestMatchFor:a];
    
    TDEqualObjects(@"[1, 2, 3]1/2/3^", [a description]);
    
    input = @"1 2 3 4";
    a = [PKTokenAssembly assemblyWithString:input];
    a = [p bestMatchFor:a];
    
    TDEqualObjects(@"[1, 2, 3, 4]1/2/3/4^", [a description]);
    
    input = @"1 2 3 4 5";
    a = [PKTokenAssembly assemblyWithString:input];
    a = [p bestMatchFor:a];
    
    TDEqualObjects(@"[1, 2, 3, 4]1/2/3/4^5", [a description]);
    
    input = @"1 2 3 4 5 6";
    a = [PKTokenAssembly assemblyWithString:input];
    a = [p bestMatchFor:a];
    
    TDEqualObjects(@"[1, 2, 3, 4]1/2/3/4^5/6", [a description]);
    
}


- (void)testTokDirectiveAST {
    NSString *g = @"@symbols='!==';@start=foo;foo=Symbol;";
    
    NSError *err = nil;
    PKCollectionParser *p = (PKCollectionParser *)[_factory parserFromGrammar:g assembler:nil error:&err];
    
    TDNotNil(p);
    TDTrue([p isKindOfClass:[PKSequence class]]);
    
    NSString *input = @"!==";
    p.tokenizer.string = input;
    PKAssembly *a = [PKTokenAssembly assemblyWithTokenizer:p.tokenizer];
    a = [p bestMatchFor:a];
    
    TDEqualObjects([a description], @"[!==]!==^");
}



////- (void)testAlternationAST {
////    NSString *g = @"@start=foo;foo=bar;bar=baz|bat;baz=Word;bat=Number;";
////
////    PKAST *rootNode = [_factory ASTFromGrammar:g simplify:NO error:nil];
////    TDNotNil(rootNode);
////    TDEqualObjects(@"(@start:SEQ (foo:SEQ (bar:| baz:Word bat:Number)))", [rootNode fullTreeDescription:[_factory symbolTableFromGrammar:g error:nil]]);
////
////    NSError *err = nil;
////    PKCollectionParser *p = (PKCollectionParser *)[_factory parserFromGrammar:g assembler:nil error:&err];
////
////    TDNotNil(p);
////    TDTrue([p isKindOfClass:[PKSequence class]]);
////
////    TDTrue(1 == [p.subparsers count]);
////    PKCollectionParser *foo = [p.subparsers objectAtIndex:0];
////    TDTrue([foo isKindOfClass:[PKCollectionParser class]]);
////
////    TDTrue(1 == [foo.subparsers count]);
////    PKCollectionParser *bar = [foo.subparsers objectAtIndex:0];
////    TDTrue([bar isKindOfClass:[PKCollectionParser class]]);
////
//////    TDTrue(1 == [bar.subparsers count]);
//////    PKAlternation *alt = [bar.subparsers objectAtIndex:0];
//////    TDTrue(2 == [alt.subparsers count]);
//////
//////    PKCollectionParser *baz = [alt.subparsers objectAtIndex:0];
//////    TDTrue([baz isKindOfClass:[PKCollectionParser class]]);
//////
//////    PKCollectionParser *bat = [alt.subparsers objectAtIndex:1];
//////    TDTrue([bat isKindOfClass:[PKCollectionParser class]]);
////
////    NSString *input = @"hello";
////    PKAssembly *a = [PKTokenAssembly assemblyWithString:input];
////    a = [p completeMatchFor:a];
////
////    TDEqualObjects(@"[hello]hello^", [a description]);
////
////    input = @"22.3";
////    a = [PKTokenAssembly assemblyWithString:input];
////    a = [p completeMatchFor:a];
////
////    TDEqualObjects(@"[22.3]22.3^", [a description]);
////
////    input = @"##";
////    a = [PKTokenAssembly assemblyWithString:input];
////    a = [p completeMatchFor:a];
////
////    TDNil(a);
////
////    input = @"'asdf'";
////    a = [PKTokenAssembly assemblyWithString:input];
////    a = [p completeMatchFor:a];
////
////    TDNil(a);
////
////}
//
@end
