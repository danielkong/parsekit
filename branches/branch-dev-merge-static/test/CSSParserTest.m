
//
//  CSSParserTest.m
//  CSS
//
//  Created by Todd Ditchendorf on 3/27/13.
//
//

#import "CSSParserTest.h"
#import "PKParserFactory.h"
#import "PKSParserGenVisitor.h"
#import "PKRootNode.h"
#import "CSSParser.h"

@interface CSSParserTest ()
@property (nonatomic, retain) PKParserFactory *factory;
@property (nonatomic, retain) PKRootNode *root;
@property (nonatomic, retain) PKSParserGenVisitor *visitor;
@property (nonatomic, retain) CSSParser *parser;
@end

@implementation CSSParserTest

- (void)setUp {
    self.factory = [PKParserFactory factory];
    _factory.collectTokenKinds = YES;

    NSError *err = nil;
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"css" ofType:@"grammar"];
    NSString *g = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&err];
    
    err = nil;
    self.root = (id)[_factory ASTFromGrammar:g error:&err];
    _root.grammarName = @"CSS";
    
    self.visitor = [[[PKSParserGenVisitor alloc] init] autorelease];
    [_root visit:_visitor];
    
    self.parser = [[[CSSParser alloc] init] autorelease];

#if TD_EMIT
    path = [@"~/work/parsekit/trunk/test/CSSParser.h" stringByExpandingTildeInPath];
    err = nil;
    if (![_visitor.interfaceOutputString writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&err]) {
        NSLog(@"%@", err);
    }

    path = [@"~/work/parsekit/trunk/test/CSSParser.m" stringByExpandingTildeInPath];
    err = nil;
    if (![_visitor.implementationOutputString writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&err]) {
        NSLog(@"%@", err);
    }
#endif
}

- (void)tearDown {
    self.factory = nil;
}

- (void)testVarFooColorRed {
    NSError *err = nil;
    PKAssembly *res = [_parser parseString:@"foo {color:red;}" assembler:nil error:&err];
    TDEqualObjects(@"[foo, {, color, :, red, ;, }]foo/{/color/:/red/;/}^", [res description]);
}

- (void)testVarFooColorRedImportant {
    NSError *err = nil;
    PKAssembly *res = [_parser parseString:@"foo {color:red !important;}" assembler:nil error:&err];
    TDEqualObjects(@"[foo, {, color, :, red, !, important, ;, }]foo/{/color/:/red/!/important/;/}^", [res description]);
}

@end
