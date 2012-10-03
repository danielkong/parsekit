//
//  TDNewParserFactoryTest.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/3/12.
//
//

#import "TDNewParserFactoryTest.h"
#import "TDParserFactory.h"
#import "PKParseTree.h"

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
    NSString *g = @"@start=foo;foo=bar;bar=baz|bat;baz=Word;bat=Num;";

    NSError *err = nil;
    PKParseTree *rootNode = [_factory syntaxTreeFromGrammar:g error:&err];
    TDNotNil(rootNode);
    TDEqualObjects([rootNode treeDescription], @"(@start (foo (bar (| (baz Word) (bat Num)))))");
    
    
}

@end
