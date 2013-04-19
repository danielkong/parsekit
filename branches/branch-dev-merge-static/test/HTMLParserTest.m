
//
//  HTMLParserTest.m
//  HTML
//
//  Created by Todd Ditchendorf on 3/27/13.
//
//

#import "HTMLParserTest.h"
#import "PKParserFactory.h"
#import "PKSParserGenVisitor.h"
#import "PKRootNode.h"
#import "HTMLParser.h"

@interface HTMLParserTest ()
@property (nonatomic, retain) PKParserFactory *factory;
@property (nonatomic, retain) PKRootNode *root;
@property (nonatomic, retain) PKSParserGenVisitor *visitor;
@property (nonatomic, retain) HTMLParser *parser;
@end

@implementation HTMLParserTest

- (void)setUp {
    self.factory = [PKParserFactory factory];
    _factory.collectTokenKinds = YES;

    NSError *err = nil;
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"html" ofType:@"grammar"];
    NSString *g = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&err];
    
    err = nil;
    self.root = (id)[_factory ASTFromGrammar:g error:&err];
    _root.grammarName = @"HTML";
    
    self.visitor = [[[PKSParserGenVisitor alloc] init] autorelease];
    [_root visit:_visitor];
    
    self.parser = [[[HTMLParser alloc] init] autorelease];

#if TD_EMIT
    path = [@"~/work/parsekit/trunk/test/HTMLParser.h" stringByExpandingTildeInPath];
    err = nil;
    if (![_visitor.interfaceOutputString writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&err]) {
        NSLog(@"%@", err);
    }

    path = [@"~/work/parsekit/trunk/test/HTMLParser.m" stringByExpandingTildeInPath];
    err = nil;
    if (![_visitor.implementationOutputString writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&err]) {
        NSLog(@"%@", err);
    }
#endif
}

- (void)tearDown {
    self.factory = nil;
}

- (void)testPHi {
    NSError *err = nil;
    PKAssembly *res = [_parser parseString:@"<p>hi" assembler:nil error:&err];
    TDEqualObjects(@"[<, p, >]</p/>^", [res description]);
}

- (void)testPHiP {
    NSError *err = nil;
    PKAssembly *res = [_parser parseString:@"<p>hi</p>" assembler:nil error:&err];
    TDEqualObjects(@"[<, p, >]</p/>^", [res description]);
}

@end
