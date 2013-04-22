
//
//  RecoverySymbolInsertionTest.m
//  JSON
//
//  Created by Todd Ditchendorf on 3/27/13.
//
//

#import "RecoverySymbolInsertionTest.h"
#import "PKParserFactory.h"
#import "PKSParserGenVisitor.h"
#import "PKRootNode.h"
#import "ElementAssignParser.h"

@interface RecoverySymbolInsertionTest ()
@property (nonatomic, retain) PKParserFactory *factory;
@property (nonatomic, retain) PKRootNode *root;
@property (nonatomic, retain) PKSParserGenVisitor *visitor;
@property (nonatomic, retain) ElementAssignParser *parser;
@end

@implementation RecoverySymbolInsertionTest

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

- (void)testMissingBracket {
    NSError *err = nil;
    PKAssembly *res = nil;
    NSString *input = nil;
    
    _parser.enableAutomaticErrorRecovery = NO;
    
    input = @"[3;";
    res = [_parser parseString:input assembler:nil error:&err];
    TDNotNil(err);
    TDNil(res);
}

- (void)testMissingBracketWithRecovery {
    NSError *err = nil;
    PKAssembly *res = nil;
    NSString *input = nil;
    
    _parser.enableAutomaticErrorRecovery = YES;
    
    input = @"[3;";
    res = [_parser parseString:input assembler:nil error:&err];
    TDEqualObjects(@"[[, 3, ;][/3/;^", [res description]);
}

- (void)testMissingBracketWithRecovery2 {
    NSError *err = nil;
    PKAssembly *res = nil;
    NSString *input = nil;
    
    _parser.enableAutomaticErrorRecovery = YES;
    
    input = @"[3[";
    res = [_parser parseString:input assembler:nil error:&err];
    TDNotNil(err);
    TDNil(res);
}

@end
