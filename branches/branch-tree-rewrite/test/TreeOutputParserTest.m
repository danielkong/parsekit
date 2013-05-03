
//
//  TreeOutputParserTest.m
//  TreeOutput
//
//  Created by Todd Ditchendorf on 3/27/13.
//
//

#import "TreeOutputParserTest.h"
#import "PKParserFactory.h"
#import "PKSParserGenVisitor.h"
#import "PKRootNode.h"
#import "TreeOutputParser.h"

@interface TreeOutputParserTest ()
@property (nonatomic, retain) PKParserFactory *factory;
@property (nonatomic, retain) PKRootNode *root;
@property (nonatomic, retain) PKSParserGenVisitor *visitor;
@property (nonatomic, retain) TreeOutputParser *parser;
@end

@implementation TreeOutputParserTest

- (void)setUp {
    self.factory = [PKParserFactory factory];
    _factory.collectTokenKinds = YES;

    NSError *err = nil;
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"tree_output" ofType:@"grammar"];
    NSString *g = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&err];
    
    err = nil;
    self.root = (id)[_factory ASTFromGrammar:g error:&err];
    _root.grammarName = @"TreeOutput";
    
    self.visitor = [[[PKSParserGenVisitor alloc] init] autorelease];
    _visitor.assemblerSettingBehavior = PKParserFactoryAssemblerSettingBehaviorTerminals;
    _visitor.enableMemoization = NO;
    _visitor.outputType = PKSParserGenOutputTypeAST;
    [_root visit:_visitor];
#if TD_EMIT
    path = [@"~/work/parsekit/trunk/test/TreeOutputParser.h" stringByExpandingTildeInPath];
    err = nil;
    if (![_visitor.interfaceOutputString writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&err]) {
        NSLog(@"%@", err);
    }

    path = [@"~/work/parsekit/trunk/test/TreeOutputParser.m" stringByExpandingTildeInPath];
    err = nil;
    if (![_visitor.implementationOutputString writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&err]) {
        NSLog(@"%@", err);
    }
#endif

    self.parser = [[[TreeOutputParser alloc] init] autorelease];
}

- (void)tearDown {
    self.factory = nil;
}

//- (void)testWord {
//    NSError *err = nil;
//    PKAST *res = nil;
//    NSString *input = nil;
//    
//    input = @"hello";
//    res = [_parser parseString:input assembler:nil error:&err];
//    TDNotNil(res);
//    TDTrue([res isKindOfClass:[PKAST class]]);
//    TDEqualObjects(@"hello", [res treeDescription]);
//}
//
//- (void)testLiteral {
//    NSError *err = nil;
//    PKAST *res = nil;
//    NSString *input = nil;
//    
//    input = @"baz";
//    res = [_parser parseString:input assembler:nil error:&err];
//    TDNotNil(res);
//    TDTrue([res isKindOfClass:[PKAST class]]);
//    TDEqualObjects(@"baz", [res treeDescription]);
//}
//
//- (void)testTree {
//    NSError *err = nil;
//    PKAST *res = nil;
//    NSString *input = nil;
//    
//    input = @"int x;";
//    res = [_parser parseString:input assembler:nil error:&err];
//    //TDEqualObjects(@"[]int/x/;^", [_parser.assembly description]);
//    
//    TDNotNil(res);
//    TDTrue([res isKindOfClass:[PKAST class]]);
//    TDEqualObjects(@"(int x)", [res treeDescription]);
//}

- (void)testSubTree {
    NSError *err = nil;
    PKAST *res = nil;
    NSString *input = nil;
    
    input = @"array [1];";
    res = [_parser parseString:input assembler:nil error:&err];
    //TDEqualObjects(@"[]int/x/;^", [_parser.assembly description]);
    
    TDNotNil(res);
    TDTrue([res isKindOfClass:[PKAST class]]);
    TDEqualObjects(@"(array ([ 1))", [res treeDescription]);
}

@end
