//
//  TDParserGenTest.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/3/12.
//
//

#import "TDParserGenTest.h"
#import "PKParserFactory.h"
#import "PKSParserGenVisitor.h"
#import "PKBaseNode.h"

@interface TDParserGenTest ()
@property (nonatomic, retain) PKParserFactory *factory;
@property (nonatomic, retain) PKBaseNode *root;
@property (nonatomic, retain) PKSParserGenVisitor *visitor;
@property (nonatomic, retain) NSString *output;
@end

@implementation TDParserGenTest

- (void)setUp {
    self.factory = [PKParserFactory factory];
    
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"expression" ofType:@"grammar"];
    NSString *g = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    
    self.root = (id)[_factory ASTFromGrammar:g error:nil];
    
    self.visitor = [[[PKSParserGenVisitor alloc] init] autorelease];
    [_root visit:_visitor];
    
    self.output = _visitor.outputString;
}


- (void)tearDown {
    self.factory = nil;
}


- (void)testFoo {
    TDTrue([_output length]);
}

@end
