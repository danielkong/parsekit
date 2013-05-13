//
//  JSRecoveryTest.m
//
//  Created by Todd Ditchendorf on 3/27/13.
//
//

#import "JSRecoveryTest.h"
#import "PKParserFactory.h"
#import "PKSParserGenVisitor.h"
#import "PKRootNode.h"
#import "JavaScriptParser.h"
#import <OCMock/OCMock.h>

@interface JSRecoveryTest ()
@property (nonatomic, retain) PKParserFactory *factory;
@property (nonatomic, retain) PKRootNode *root;
@property (nonatomic, retain) PKSParserGenVisitor *visitor;
@property (nonatomic, retain) JavaScriptParser *parser;
@end

@implementation JSRecoveryTest

- (void)parser:(PKSParser *)p didMatchVar:(PKAssembly *)a {}
- (void)parser:(PKSParser *)p didMatchIdentifier:(PKAssembly *)a {}
- (void)parser:(PKSParser *)p didMatchVariable:(PKAssembly *)a {}
- (void)parser:(PKSParser *)p didMatchVariables:(PKAssembly *)a {}
- (void)parser:(PKSParser *)p didMatchVarVariables:(PKAssembly *)a {}
- (void)parser:(PKSParser *)p didMatchVariablesOrExpr:(PKAssembly *)a {}
- (void)parser:(PKSParser *)p didMatchSemi:(PKAssembly *)a {}
- (void)parser:(PKSParser *)p didMatchVariablesOrExprStmt:(PKAssembly *)a {}
- (void)parser:(PKSParser *)p didMatchStmt:(PKAssembly *)a {}
- (void)parser:(PKSParser *)p didMatchElement:(PKAssembly *)a {}
- (void)parser:(PKSParser *)p didMatchProgram:(PKAssembly *)a {}

- (void)setUp {
    self.parser = [[[JavaScriptParser alloc] init] autorelease];
}

- (void)tearDown {
    self.factory = nil;
}

- (void)testCorrectExpr {
    NSError *err = nil;
    PKAssembly *res = nil;
    NSString *input = nil;
    
    id mock = [OCMockObject niceMockForClass:[JSRecoveryTest class]];

    // return YES to -respondsToSelector:
    [[[mock stub] andReturnValue:OCMOCK_VALUE((BOOL){YES})] respondsToSelector:(SEL)OCMOCK_ANY];

    [[mock expect] parser:_parser didMatchVar:OCMOCK_ANY];
    [[mock expect] parser:_parser didMatchIdentifier:OCMOCK_ANY];
    [[mock expect] parser:_parser didMatchSemi:OCMOCK_ANY];
    
    input = @"var foo;";
    res = [_parser parseString:input assembler:mock error:&err];
    TDEqualObjects(@"[var, foo, ;]var/foo/;^", [res description]);
    
    [mock verify];
}

@end