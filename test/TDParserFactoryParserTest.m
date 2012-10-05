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
    PKParser *p = [_factory parserFromGrammar:g assembler:nil error:&err];

    TDNotNil(p);
    TDTrue([p isKindOfClass:[PKSequence class]]);
}

@end
