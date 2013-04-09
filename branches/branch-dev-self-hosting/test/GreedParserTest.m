
//
//  GreedParserTest.m
//  Greed
//
//  Created by Todd Ditchendorf on 3/27/13.
//
//

#import "GreedParserTest.h"
#import "PKParserFactory.h"
#import "PKSParserGenVisitor.h"
#import "PKRootNode.h"
#import "GreedParser.h"

@interface GreedParser ()
- (id)_doParseWithTokenizer:(PKTokenizer *)t assembler:(id)a error:(NSError **)outError;
@end

@interface GreedParserTest ()
@property (nonatomic, retain) PKParserFactory *factory;
@property (nonatomic, retain) PKRootNode *root;
@property (nonatomic, retain) PKSParserGenVisitor *visitor;
@property (nonatomic, retain) GreedParser *parser;
@end

@implementation GreedParserTest

- (void)setUp {
    self.factory = [PKParserFactory factory];
    _factory.collectTokenKinds = YES;

    NSError *err = nil;
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"greed" ofType:@"grammar"];
    NSString *g = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&err];
    
    err = nil;
    self.root = (id)[_factory ASTFromGrammar:g error:&err];
    _root.grammarName = @"Greed";
    
    self.visitor = [[[PKSParserGenVisitor alloc] init] autorelease];
    [_root visit:_visitor];
    
    self.parser = [[[GreedParser alloc] init] autorelease];

#if TD_EMIT
    path = [@"~/work/parsekit/trunk/test/GreedParser.h" stringByExpandingTildeInPath];
    err = nil;
    if (![_visitor.interfaceOutputString writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&err]) {
        NSLog(@"%@", err);
    }

    path = [@"~/work/parsekit/trunk/test/GreedParser.m" stringByExpandingTildeInPath];
    err = nil;
    if (![_visitor.implementationOutputString writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&err]) {
        NSLog(@"%@", err);
    }
#endif
}

- (void)tearDown {
    self.factory = nil;
}

- (void)testABABA {
    NSError *err = nil;
    PKAssembly *res = [_parser parseString:@"a b a b a" assembler:nil error:&err];
    
//    TDEqualObjects(@"[a, b, a, b, a]a/b/a/b/a^", [res description]);
    TDNil(res);
}

- (void)testABA {
    NSError *err = nil;
    PKAssembly *res = [_parser parseString:@"a b a" assembler:nil error:&err];
    
    TDEqualObjects(@"[a, b, a]a/b/a^", [res description]);
}

@end
