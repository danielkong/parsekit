//
//  ElementAssignParserTest.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 3/27/13.
//
//

#import "ElementAssignParserTest.h"
#import "PKParserFactory.h"
#import "PKSParserGenVisitor.h"
#import "PKRootNode.h"
#import "ElementAssignParser.h"

#define EMIT 0

@interface ElementAssignParserTest ()
@property (nonatomic, retain) PKParserFactory *factory;
@property (nonatomic, retain) PKRootNode *root;
@property (nonatomic, retain) PKSParserGenVisitor *visitor;
@end

@implementation ElementAssignParserTest

- (void)setUp {
    self.factory = [PKParserFactory factory];
    _factory.collectTokenKinds = YES;

    NSError *err = nil;
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"elementsAssign" ofType:@"grammar"];
    NSString *g = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&err];
    
    err = nil;
    self.root = (id)[_factory ASTFromGrammar:g error:&err];
    _root.grammarName = @"ElementAssign";
    
    self.visitor = [[[PKSParserGenVisitor alloc] init] autorelease];
    [_root visit:_visitor];
    
#if EMIT
    path = [@"~/work/parsekit/trunk/test/ElementAssignParser.h" stringByExpandingTildeInPath];
    err = nil;
    if (![_visitor.interfaceOutputString writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&err]) {
        NSLog(@"%@", err);
    }

    path = [@"~/work/parsekit/trunk/test/ElementAssignParser.m" stringByExpandingTildeInPath];
    err = nil;
    if (![_visitor.implementationOutputString writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&err]) {
        NSLog(@"%@", err);
    }
#endif
}


- (void)tearDown {
    self.factory = nil;
}


//- (void)testFoo {
//    ElementAssignParser *p = [[[ElementAssignParser alloc] init] autorelease];
//    p.assembler = self;
//    
//    PKAssembly *res = [p parse:@"[1, [2,3],4]" error:nil];
//    
//    TDEqualObjects(@"[[, 1, [, 2, 3, 4][/1/,/[/2/,/3/]/,/4/]^", [res description]);
//}


- (void)parser:(PKSParser *)p didMatchList:(PKAssembly *)a {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, a);
    
}


- (void)testAssign {
    ElementAssignParser *p = [[[ElementAssignParser alloc] init] autorelease];
    p.assembler = self;
    
    PKAssembly *res = [p parse:@"[1]=[2]" error:nil];
    
    TDEqualObjects(@"[[, 1, =, [, 2][/1/]/=/[/2/]^", [res description]);
}


@end
