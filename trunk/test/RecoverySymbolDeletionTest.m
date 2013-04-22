
//
//  RecoverySymbolDeletionTest.m
//  JSON
//
//  Created by Todd Ditchendorf on 3/27/13.
//
//

#import "RecoverySymbolDeletionTest.h"
#import "PKParserFactory.h"
#import "PKSParserGenVisitor.h"
#import "PKRootNode.h"
#import "ElementAssignParser.h"

@interface RecoverySymbolDeletionTest ()
@property (nonatomic, retain) PKParserFactory *factory;
@property (nonatomic, retain) PKRootNode *root;
@property (nonatomic, retain) PKSParserGenVisitor *visitor;
@property (nonatomic, retain) ElementAssignParser *parser;
@end

@implementation RecoverySymbolDeletionTest

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

- (void)testExtraParen {
    NSError *err = nil;
    PKAssembly *res = nil;
    NSString *input = nil;
    
    input = @"[3]];";
    res = [_parser parseString:input assembler:nil error:&err];
    TDEqualObjects(@"[[, 3, ;][/3/]/;^", [res description]);
}

@end
