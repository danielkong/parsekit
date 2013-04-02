//
//  TDNSPredicateParserTest.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 3/27/13.
//
//

#import "TDNSPredicateParserTest.h"
#import "PKParserFactory.h"
#import "PKSParserGenVisitor.h"
#import "PKRootNode.h"
#import "TDNSPredicateParser.h"

@interface TDNSPredicateParserTest ()
@property (nonatomic, retain) PKParserFactory *factory;
@property (nonatomic, retain) PKRootNode *root;
@property (nonatomic, retain) PKSParserGenVisitor *visitor;
@property (nonatomic, retain) TDNSPredicateParser *parser;
@end

@implementation TDNSPredicateParserTest

- (void)setUp {
    self.factory = [PKParserFactory factory];
    _factory.collectTokenKinds = YES;

    NSError *err = nil;
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"nspredicate2" ofType:@"grammar"];
    NSString *g = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&err];
    
    err = nil;
    self.root = (id)[_factory ASTFromGrammar:g error:&err];
    _root.grammarName = @"TDNSPredicate";
    
    self.visitor = [[[PKSParserGenVisitor alloc] init] autorelease];
    [_root visit:_visitor];
    
    self.parser = [[[TDNSPredicateParser alloc] init] autorelease];

#if TD_EMIT
    path = [@"~/work/parsekit/trunk/test/TDNSPredicateParser.h" stringByExpandingTildeInPath];
    err = nil;
    if (![_visitor.interfaceOutputString writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&err]) {
        NSLog(@"%@", err);
    }

    path = [@"~/work/parsekit/trunk/test/TDNSPredicateParser.m" stringByExpandingTildeInPath];
    err = nil;
    if (![_visitor.implementationOutputString writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&err]) {
        NSLog(@"%@", err);
    }
#endif
}


- (void)tearDown {
    self.factory = nil;
}


- (void)testYes {
    NSError *err = nil;
    PKAssembly *res = [_parser parseString:@"yes" assembler:nil error:&err];
    NSLog(@"%@", err);
    TDEqualObjects(@"[1]yes^", [res description]);
}

- (void)testYES {
    NSError *err = nil;
    PKAssembly *res = [_parser parseString:@"YES" assembler:nil error:&err];
    NSLog(@"%@", err);
    TDNotNil(err);
    TDNil(res);
}

- (void)testNo {
    PKAssembly *res = [_parser parseString:@"no" assembler:nil error:nil];
    TDEqualObjects(@"[0]no^", [res description]);
}

- (void)testNO {
    NSError *err = nil;
    PKAssembly *res = [_parser parseString:@"NO" assembler:nil error:&err];
    NSLog(@"%@", err);
    TDNotNil(err);
    TDNil(res);
}

- (void)testYesOrNo {
    PKAssembly *res = [_parser parseString:@"yes or no" assembler:nil error:nil];
    TDEqualObjects(@"[1]yes/or/no^", [res description]);
}

- (void)testNoOrYes {
    PKAssembly *res = [_parser parseString:@"no or yes" assembler:nil error:nil];
    TDEqualObjects(@"[1]no/or/yes^", [res description]);
}

- (void)testYesAndNo {
    PKAssembly *res = [_parser parseString:@"yes and no" assembler:nil error:nil];
    TDEqualObjects(@"[0]yes/and/no^", [res description]);
}

- (void)testNoAndNo {
    PKAssembly *res = [_parser parseString:@"no and no" assembler:nil error:nil];
    TDEqualObjects(@"[0]no/and/no^", [res description]);
}

- (void)testYesAndYes {
    PKAssembly *res = [_parser parseString:@"yes and yes" assembler:nil error:nil];
    TDEqualObjects(@"[1]yes/and/yes^", [res description]);
}

- (void)test42 {
    PKAssembly *res = [_parser parseString:@"42" assembler:nil error:nil];
    TDEqualObjects(@"[42]42^", [res description]);
}

- (void)test42GE43 {
    PKAssembly *res = [_parser parseString:@"42 >= 43" assembler:nil error:nil];
    TDEqualObjects(@"[0]42/>=/43^", [res description]);
}

- (void)test42LE43 {
    PKAssembly *res = [_parser parseString:@"42 <= 43" assembler:nil error:nil];
    TDEqualObjects(@"[1]42/<=/43^", [res description]);
}

- (void)test42LT43 {
    PKAssembly *res = [_parser parseString:@"42 < 43" assembler:nil error:nil];
    TDEqualObjects(@"[1]42/</43^", [res description]);
}


- (void)parser:(PKSParser *)p didMatchArgList:(PKAssembly *)a {
    //NSLog(@"%s %@", __PRETTY_FUNCTION__, a);
    
}

@end
