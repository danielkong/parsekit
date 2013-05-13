//
//  JSRecoveryTest.m
//
//  Created by Todd Ditchendorf on 3/27/13.
//
//

#import "JSRecoveryTest.h"
#import "PKSParserGenVisitor.h"
#import "PKRootNode.h"
#import "JavaScriptParser.h"
#import <OCMock/OCMock.h>

#define VERIFY() @try { [_mock verify]; } @catch (NSException *ex) { STAssertTrue(0, [ex reason]); }

@interface JSRecoveryTest ()
@property (nonatomic, retain) JavaScriptParser *parser;
@property (nonatomic, retain) id mock;
@end

@implementation JSRecoveryTest

- (void)dealloc {
    self.parser = nil;
    self.mock = nil;
    [super dealloc];
}

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

    self.mock = [OCMockObject niceMockForClass:[JSRecoveryTest class]];
    
    // return YES to -respondsToSelector:
    [[[_mock stub] andReturnValue:OCMOCK_VALUE((BOOL){YES})] respondsToSelector:(SEL)OCMOCK_ANY];
}

- (void)tearDown {

}

- (void)testCorrectExpr {
    NSError *err = nil;
    PKAssembly *res = nil;
    NSString *input = nil;
    
    [[_mock expect] parser:_parser didMatchVar:OCMOCK_ANY];
    [[_mock expect] parser:_parser didMatchIdentifier:OCMOCK_ANY];
    [[_mock expect] parser:_parser didMatchSemi:OCMOCK_ANY];
    [[_mock expect] parser:_parser didMatchProgram:OCMOCK_ANY];
    
    input = @"var foo;";
    res = [_parser parseString:input assembler:_mock error:&err];
    TDEqualObjects(@"[var, foo, ;]var/foo/;^", [res description]);
    
    VERIFY();
}

- (void)testBorkedVarMissingSemi {
    NSError *err = nil;
    PKAssembly *res = nil;
    NSString *input = nil;
    
    [[_mock expect] parser:_parser didMatchVar:OCMOCK_ANY];
    [[_mock expect] parser:_parser didMatchIdentifier:OCMOCK_ANY];
    [[_mock expect] parser:_parser didMatchProgram:OCMOCK_ANY];
    
    input = @"var foo";
    res = [_parser parseString:input assembler:_mock error:&err];
    TDEqualObjects(@"[var, foo]var/foo^", [res description]);
    
    VERIFY();
}

- (void)testMissingVarIdentifier {
    NSError *err = nil;
    PKAssembly *res = nil;
    NSString *input = nil;
    
    [[_mock expect] parser:_parser didMatchVar:OCMOCK_ANY];
    [[_mock expect] parser:_parser didMatchSemi:OCMOCK_ANY];
    [[_mock expect] parser:_parser didMatchSemi:OCMOCK_ANY];
    [[_mock expect] parser:_parser didMatchProgram:OCMOCK_ANY];
    
    input = @"var;;";
    res = [_parser parseString:input assembler:_mock error:&err];
    TDEqualObjects(@"[var, ;, ;]var/;/;^", [res description]);
    
    VERIFY();
}



@end