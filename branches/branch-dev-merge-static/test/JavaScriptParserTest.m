
//
//  JavaScriptParserTest.m
//  JavaScript
//
//  Created by Todd Ditchendorf on 3/27/13.
//
//

#import "JavaScriptParserTest.h"
#import "PKParserFactory.h"
#import "PKSParserGenVisitor.h"
#import "PKRootNode.h"
#import "JavaScriptParser.h"

@interface JavaScriptParser ()
- (id)_doParseWithTokenizer:(PKTokenizer *)t assembler:(id)a error:(NSError **)outError;
@end

@interface JavaScriptParserTest ()
@property (nonatomic, retain) PKParserFactory *factory;
@property (nonatomic, retain) PKRootNode *root;
@property (nonatomic, retain) PKSParserGenVisitor *visitor;
@property (nonatomic, retain) JavaScriptParser *parser;
@end

@implementation JavaScriptParserTest

- (void)setUp {
    self.factory = [PKParserFactory factory];
    _factory.collectTokenKinds = YES;

    NSError *err = nil;
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"javascript" ofType:@"grammar"];
    NSString *g = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&err];
    
    err = nil;
    self.root = (id)[_factory ASTFromGrammar:g error:&err];
    _root.grammarName = @"JavaScript";
    
    self.visitor = [[[PKSParserGenVisitor alloc] init] autorelease];
    [_root visit:_visitor];
    
    self.parser = [[[JavaScriptParser alloc] init] autorelease];

#if TD_EMIT
    path = [@"~/work/parsekit/trunk/test/JavaScriptParser.h" stringByExpandingTildeInPath];
    err = nil;
    if (![_visitor.interfaceOutputString writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&err]) {
        NSLog(@"%@", err);
    }

    path = [@"~/work/parsekit/trunk/test/JavaScriptParser.m" stringByExpandingTildeInPath];
    err = nil;
    if (![_visitor.implementationOutputString writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&err]) {
        NSLog(@"%@", err);
    }
#endif
}

- (void)tearDown {
    self.factory = nil;
}

- (void)testVarFooEqBar {
    NSError *err = nil;
    PKAssembly *res = [_parser parseString:@"var foo = 'bar';" assembler:nil error:&err];
    TDEqualObjects(@"[var, foo, =, 'bar', ;]var/foo/=/'bar'/;^", [res description]);
}

@end
