//
//  TDNewParserFactoryTest.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/3/12.
//
//

#import "TDNewParserFactoryTest.h"
#import "TDParserFactory.h"

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


- (void)testSomething {
    NSString *g = @"foo=bar;bar=baz|bat;baz=Word;bat=Number;";

    NSError *err = nil;
    PKParser *p = [_factory parserFromGrammar:g assembler:nil error:&err];
    TDNotNil(p);
    
    
    
}

@end
