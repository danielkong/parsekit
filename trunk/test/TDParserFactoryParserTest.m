//
//  TDParserFactoryParserTest.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/5/12.
//
//

#import "TDParserFactoryParserTest.h"
#import "TDParserFactory.h"
#import "PKAST.h"

@interface TDParserFactoryParserTest ()
@property (nonatomic, retain) TDParserFactory *factory;
@end

@implementation TDParserFactoryParserTest

- (void)setUp {
    self.factory = [TDParserFactory factory];
}


- (void)tearDown {
    self.factory = nil;
}


- (void)testAlternationAST {
    NSString *g = @"@start=foo;foo=bar;bar=baz|bat;baz=Word;bat=Number;";
    
    NSError *err = nil;
    PKCollectionParser *p = (PKCollectionParser *)[_factory parserFromGrammar:g assembler:nil error:&err];

    TDNotNil(p);
    TDTrue([p isKindOfClass:[PKSequence class]]);
    
    TDTrue(1 == [p.subparsers count]);
    PKCollectionParser *foo = [p.subparsers objectAtIndex:0];
    TDTrue([foo isKindOfClass:[PKCollectionParser class]]);
    
    TDTrue(1 == [foo.subparsers count]);
    PKCollectionParser *bar = [foo.subparsers objectAtIndex:0];
    TDTrue([bar isKindOfClass:[PKCollectionParser class]]);
    
    TDTrue(1 == [bar.subparsers count]);
    PKAlternation *alt = [bar.subparsers objectAtIndex:0];
    TDTrue(2 == [alt.subparsers count]);
    
    PKCollectionParser *baz = [alt.subparsers objectAtIndex:0];
    TDTrue([baz isKindOfClass:[PKCollectionParser class]]);
    
    PKCollectionParser *bat = [alt.subparsers objectAtIndex:1];
    TDTrue([bat isKindOfClass:[PKCollectionParser class]]);
    
    NSString *input = @"hello";
    PKAssembly *a = [PKTokenAssembly assemblyWithString:input];
    a = [p completeMatchFor:a];
    
    TDEqualObjects([a description], @"[hello]hello^");
    
    input = @"22.3";
    a = [PKTokenAssembly assemblyWithString:input];
    a = [p completeMatchFor:a];
    
    TDEqualObjects([a description], @"[22.3]22.3^");
    
    input = @"##";
    a = [PKTokenAssembly assemblyWithString:input];
    a = [p completeMatchFor:a];
    
    TDNil(a);
    
    input = @"'asdf'";
    a = [PKTokenAssembly assemblyWithString:input];
    a = [p completeMatchFor:a];
    
    TDNil(a);
    
}

@end
