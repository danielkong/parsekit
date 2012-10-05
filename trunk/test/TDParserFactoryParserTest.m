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
    PKCollectionParser *bar = [p.subparsers objectAtIndex:0];
    TDTrue([bar isKindOfClass:[PKCollectionParser class]]);
    
    TDTrue(2 == [bar.subparsers count]);
    PKCollectionParser *baz = [p.subparsers objectAtIndex:0];
    TDTrue([baz isKindOfClass:[PKCollectionParser class]]);
    
    PKCollectionParser *bat = [p.subparsers objectAtIndex:1];
    TDTrue([bat isKindOfClass:[PKCollectionParser class]]);
    
}

@end
