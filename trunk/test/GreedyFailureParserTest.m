
//
//  GreedyFailureParserTest.m
//  JavaScript
//
//  Created by Todd Ditchendorf on 3/27/13.
//
//

#import "GreedyFailureParserTest.h"
#import "PKParserFactory.h"
#import "PKSParserGenVisitor.h"
#import "PKRootNode.h"
#import "GreedyFailureParser.h"

@interface GreedyFailureParserTest ()
@property (nonatomic, retain) PKParserFactory *factory;
@property (nonatomic, retain) PKRootNode *root;
@property (nonatomic, retain) PKSParserGenVisitor *visitor;
@property (nonatomic, retain) GreedyFailureParser *parser;
@end

@implementation GreedyFailureParserTest

- (void)setUp {
    self.factory = [PKParserFactory factory];
    _factory.collectTokenKinds = YES;

    NSError *err = nil;
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"greedy_failure" ofType:@"grammar"];
    NSString *g = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&err];
    
    err = nil;
    self.root = (id)[_factory ASTFromGrammar:g error:&err];
    _root.grammarName = @"GreedyFailure";
    
    self.visitor = [[[PKSParserGenVisitor alloc] init] autorelease];
    _visitor.assemblerSettingBehavior = PKParserFactoryAssemblerSettingBehaviorAll;
    _visitor.enableAutomaticErrorRecovery = YES;
    _visitor.enableMemoization = NO;
    
    [_root visit:_visitor];
    
    self.parser = [[[GreedyFailureParser alloc] init] autorelease];

#if TD_EMIT
    path = [[NSString stringWithFormat:@"%s/test/GreedyFailureParser.h", getenv("PWD")] stringByExpandingTildeInPath];
    err = nil;
    if (![_visitor.interfaceOutputString writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&err]) {
        NSLog(@"%@", err);
    }

    path = [[NSString stringWithFormat:@"%s/test/GreedyFailureParser.m", getenv("PWD")] stringByExpandingTildeInPath];
    err = nil;
    if (![_visitor.implementationOutputString writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&err]) {
        NSLog(@"%@", err);
    }
#endif
}

- (void)tearDown {
    self.factory = nil;
}


- (void)testCompleteStruct {
    _parser.enableAutomaticErrorRecovery = YES;
    
    NSError *err = nil;
    PKAssembly *res = [_parser parseString:@"{'foo':bar}" assembler:self error:&err];
    TDEqualObjects(@"[{, 'foo', :, bar, }]{/'foo'/:/bar/}^", [res description]);
}

@end
