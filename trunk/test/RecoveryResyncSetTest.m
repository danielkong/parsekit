//
//  RecoveryResyncSetTest.m
//
//  Created by Todd Ditchendorf on 3/27/13.
//
//

#import "RecoveryResyncSetTest.h"
#import "PKParserFactory.h"
#import "PKSParserGenVisitor.h"
#import "PKRootNode.h"
#import "ElementAssignParser.h"

@interface RecoveryResyncSetTest ()
@property (nonatomic, retain) PKParserFactory *factory;
@property (nonatomic, retain) PKRootNode *root;
@property (nonatomic, retain) PKSParserGenVisitor *visitor;
@property (nonatomic, retain) ElementAssignParser *parser;
@end

@implementation RecoveryResyncSetTest

- (void)setUp {
    self.parser = [[[ElementAssignParser alloc] init] autorelease];
}

- (void)tearDown {
    self.factory = nil;
}

- (void)testCorrectExpr {
    NSError *err = nil;
    PKAssembly *res = nil;
    NSString *input = nil;
    
    input = @"[3];";
    res = [_parser parseString:input assembler:nil error:&err];
    TDEqualObjects(@"[[, 3, ;][/3/]/;^", [res description]);
}

- (void)testMissingElement {
    NSError *err = nil;
    PKAssembly *res = nil;
    NSString *input = nil;
    
    _parser.enableAutomaticErrorRecovery = YES;
    
    input = @"[];";
    res = [_parser parseString:input assembler:nil error:&err];
    TDEqualObjects(@"[[, ;][/]/;^", [res description]);
}

- (void)testMissingRbracketInAssign {
    NSError *err = nil;
    PKAssembly *res = nil;
    NSString *input = nil;
    
    _parser.enableAutomaticErrorRecovery = YES;
    
    input = @"[=[2].";
    res = [_parser parseString:input assembler:nil error:&err];
    TDEqualObjects(@"[[, =, [, 2, .][/=/[/2/]/.^", [res description]);
}

- (void)testMissingLbracketInAssign {
    NSError *err = nil;
    PKAssembly *res = nil;
    NSString *input = nil;
    
    _parser.enableAutomaticErrorRecovery = YES;
    
    input = @"]=[2].";
    res = [_parser parseString:input assembler:nil error:&err];
    TDEqualObjects(@"[=, [, 2, .]]/=/[/2/]/.^", [res description]);
}

@end
