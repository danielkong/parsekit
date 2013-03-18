//
//  TDParserFactorySymbolTableTest.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/5/12.
//
//

#import "TDParserFactorySymbolTableTest.h"
#import "PKParserFactory.h"
#import "PKAST.h"

@interface TDParserFactorySymbolTableTest ()
@property (nonatomic, retain) PKParserFactory *factory;
@end

@implementation TDParserFactorySymbolTableTest

- (void)setUp {
    self.factory = [PKParserFactory factory];
}


- (void)tearDown {
    self.factory = nil;
}


- (void)testSimpleAST {
    NSString *g = @"@start=foo;foo=Word;";
    
    NSError *err = nil;    
    NSDictionary *symTab = [_factory symbolTableFromGrammar:g error:&err];
    TDNotNil(symTab);
    
    PKCollectionParser *start = symTab[@"@start"];
    TDNotNil(start);
    TDTrue([start isKindOfClass:[PKSequence class]]);
    
    PKParser *foo = symTab[@"foo"];
    TDNotNil(foo);
    TDTrue([foo isKindOfClass:[PKWord class]]);
    
    TDEquals(start.subparsers[0], foo);
    
    TDNil(foo.assembler);
    TDEquals((SEL)NULL, foo.assemblerSelector);
    TDNil(foo.assemblerBlock);
    TDNil(foo.preassembler);
    TDEquals((SEL)NULL, foo.preassemblerSelector);
    TDNil(foo.preassemblerBlock);
}


- (void)testAlternationAST {
    NSString *g = @"@start=foo;foo=Word|Number;";
    
    NSError *err = nil;
    NSDictionary *symTab = [_factory symbolTableFromGrammar:g error:&err];
    TDNotNil(symTab);
    
    PKCollectionParser *start = symTab[@"@start"];
    TDNotNil(start);
    TDTrue([start isKindOfClass:[PKSequence class]]);
    
    PKAlternation *foo = symTab[@"foo"];
    TDNotNil(foo);
    TDTrue([foo isKindOfClass:[PKAlternation class]]);
    
    TDEquals(start.subparsers[0], foo);
    TDTrue([foo.subparsers[0] isKindOfClass:[PKWord class]]);
    TDTrue([foo.subparsers[1] isKindOfClass:[PKNumber class]]);
}


- (void)testSequenceAST {
    NSString *g = @"@start=foo;foo=(Word|Number) Symbol;";
    
    NSError *err = nil;
    NSDictionary *symTab = [_factory symbolTableFromGrammar:g error:&err];
    TDNotNil(symTab);
    
    PKCollectionParser *start = symTab[@"@start"];
    TDNotNil(start);
    TDTrue([start isKindOfClass:[PKSequence class]]);
    
    PKSequence *foo = symTab[@"foo"];
    TDNotNil(foo);
    TDTrue([foo isKindOfClass:[PKSequence class]]);
    
    TDEquals(start.subparsers[0], foo);
    TDTrue([foo.subparsers[0] isKindOfClass:[PKAlternation class]]);
    TDTrue([foo.subparsers[1] isKindOfClass:[PKSymbol class]]);
}


- (void)testRepetitionAST {
    NSString *g = @"@start=foo;foo=Word* Symbol;";
    
    NSError *err = nil;
    NSDictionary *symTab = [_factory symbolTableFromGrammar:g error:&err];
    TDNotNil(symTab);
    
    PKCollectionParser *start = symTab[@"@start"];
    TDNotNil(start);
    TDTrue([start isKindOfClass:[PKSequence class]]);
    
    PKSequence *foo = symTab[@"foo"];
    TDNotNil(foo);
    TDTrue([foo isKindOfClass:[PKSequence class]]);
    
    TDEquals(start.subparsers[0], foo);
    TDTrue([foo.subparsers[0] isKindOfClass:[PKRepetition class]]);
    TDTrue([foo.subparsers[1] isKindOfClass:[PKSymbol class]]);
}


- (void)testOptionalAST {
    NSString *g = @"@start=foo;foo=Word?;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(ROOT (@start #foo) ($foo (? Word)))", [rootNode treeDescription]);
    
    err = nil;
    NSDictionary *symTab = [_factory symbolTableFromGrammar:g error:&err];
    TDNotNil(symTab);
    
    PKCollectionParser *start = symTab[@"@start"];
    TDNotNil(start);
    TDTrue([start isKindOfClass:[PKSequence class]]);
    
    PKAlternation *foo = symTab[@"foo"];
    TDNotNil(foo);
    TDTrue([foo isKindOfClass:[PKAlternation class]]);
    
    TDEquals(start.subparsers[0], foo);
    TDTrue([foo.subparsers[0] isKindOfClass:[PKWord class]]);
    TDTrue([foo.subparsers[1] isKindOfClass:[PKEmpty class]]);
}


- (void)testOptionalAST2 {
    NSString *g = @"@start=foo;foo=Symbol Word?;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(ROOT (@start #foo) ($foo (. Symbol (? Word))))", [rootNode treeDescription]);
    
    err = nil;
    NSDictionary *symTab = [_factory symbolTableFromGrammar:g error:&err];
    TDNotNil(symTab);
    
    PKCollectionParser *start = symTab[@"@start"];
    TDNotNil(start);
    TDTrue([start isKindOfClass:[PKSequence class]]);
    
    PKSequence *foo = symTab[@"foo"];
    TDNotNil(foo);
    TDTrue([foo isKindOfClass:[PKSequence class]]);
    
    TDEquals(start.subparsers[0], foo);
    TDTrue([foo.subparsers[0] isKindOfClass:[PKSymbol class]]);
    TDTrue([foo.subparsers[1] isKindOfClass:[PKAlternation class]]);
    
    PKAlternation *alt = foo.subparsers[1];
    TDTrue([alt.subparsers[0] isKindOfClass:[PKWord class]]);
    TDTrue([alt.subparsers[1] isKindOfClass:[PKEmpty class]]);
}


- (void)testMultiAST1 {
    NSString *g = @"@start=foo;foo=Word+;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(ROOT (@start #foo) ($foo (+ Word)))", [rootNode treeDescription]);
    
    err = nil;
    NSDictionary *symTab = [_factory symbolTableFromGrammar:g error:&err];
    TDNotNil(symTab);
    
    PKCollectionParser *start = symTab[@"@start"];
    TDNotNil(start);
    TDTrue([start isKindOfClass:[PKSequence class]]);
    
    PKSequence *foo = symTab[@"foo"];
    TDNotNil(foo);
    TDTrue([foo isKindOfClass:[PKSequence class]]);
    
    TDEquals(start.subparsers[0], foo);
    TDTrue([foo.subparsers[0] isKindOfClass:[PKWord class]]);
    TDTrue([foo.subparsers[1] isKindOfClass:[PKRepetition class]]);

    PKRepetition *rep = foo.subparsers[1];
    TDTrue([rep.subparser isKindOfClass:[PKWord class]]);
}


- (void)testMultiAST2 {
    NSString *g = @"@start=foo;foo=Symbol Word+;";
    
    NSError *err = nil;
    PKAST *rootNode = [_factory ASTFromGrammar:g error:&err];
    TDNotNil(rootNode);
    TDEqualObjects(@"(ROOT (@start #foo) ($foo (. Symbol (+ Word))))", [rootNode treeDescription]);
    
    err = nil;
    NSDictionary *symTab = [_factory symbolTableFromGrammar:g error:&err];
    TDNotNil(symTab);
    
    PKCollectionParser *start = symTab[@"@start"];
    TDNotNil(start);
    TDTrue([start isKindOfClass:[PKSequence class]]);
    
    PKSequence *foo = symTab[@"foo"];
    TDNotNil(foo);
    TDTrue([foo isKindOfClass:[PKSequence class]]);
    
    TDEquals(start.subparsers[0], foo);
    TDTrue([foo.subparsers[0] isKindOfClass:[PKSymbol class]]);
    TDTrue([foo.subparsers[1] isKindOfClass:[PKSequence class]]);
    
    PKSequence *seq = foo.subparsers[1];
    TDTrue([seq.subparsers[0] isKindOfClass:[PKWord class]]);
    TDTrue([seq.subparsers[1] isKindOfClass:[PKRepetition class]]);
    
    PKRepetition *rep = seq.subparsers[1];
    TDTrue([rep.subparser isKindOfClass:[PKWord class]]);
}


- (void)testLiteralAST {
    NSString *g = @"@start=foo;foo='bar' Symbol;";
    
    NSError *err = nil;
    NSDictionary *symTab = [_factory symbolTableFromGrammar:g error:&err];
    TDNotNil(symTab);
    
    PKCollectionParser *start = symTab[@"@start"];
    TDNotNil(start);
    TDTrue([start isKindOfClass:[PKSequence class]]);
    
    PKSequence *foo = symTab[@"foo"];
    TDNotNil(foo);
    TDTrue([foo isKindOfClass:[PKSequence class]]);
    
    TDEquals(start.subparsers[0], foo);
    TDTrue([foo.subparsers[0] isKindOfClass:[PKLiteral class]]);
    TDTrue([foo.subparsers[1] isKindOfClass:[PKSymbol class]]);
    
    PKLiteral *lit = foo.subparsers[0];
    TDEqualObjects(@"bar", lit.string);
}


- (void)parser:(PKParser *)p didMatchFoo:(PKAssembly *)a {}
- (void)testDefaultAssemblerSetting {
    NSString *g = @"@start=foo;foo=Word;";
    
    NSError *err = nil;
    PKCollectionParser *start = (id)[_factory parserFromGrammar:g assembler:self error:&err];
    TDNotNil(start);
    
    PKParser *foo = start.subparsers[0];
    TDNotNil(foo);
    TDTrue([foo isKindOfClass:[PKWord class]]);
    
    TDEquals(start.subparsers[0], foo);
    
    TDEqualObjects(self, foo.assembler);
    TDEquals(@selector(parser:didMatchFoo:), foo.assemblerSelector);
    TDNil(foo.assemblerBlock);
    TDNil(foo.preassembler);
    TDEquals((SEL)NULL, foo.preassemblerSelector);
    TDNil(foo.preassemblerBlock);
}


- (void)parser:(PKParser *)p willMatchFoo:(PKAssembly *)a {}
- (void)testDefaultPreassemblerSetting {
    NSString *g = @"@start=foo;foo=Word;";
    
    NSError *err = nil;
    PKCollectionParser *start = (id)[_factory parserFromGrammar:g assembler:self preassembler:self error:&err];
    TDNotNil(start);
    
    PKParser *foo = start.subparsers[0];
    TDNotNil(foo);
    TDTrue([foo isKindOfClass:[PKWord class]]);
    
    TDEquals(start.subparsers[0], foo);
    
    TDEqualObjects(self, foo.assembler);
    TDEquals(@selector(parser:didMatchFoo:), foo.assemblerSelector);
    TDNil(foo.assemblerBlock);
    TDEqualObjects(self, foo.preassembler);
    TDEquals(@selector(parser:willMatchFoo:), foo.preassemblerSelector);
    TDNil(foo.preassemblerBlock);
}


- (void)parser:(PKParser *)p didMatchSomething:(PKAssembly *)a {}
- (void)testCustomAssemblerSetting {
    NSString *g = @"@start=foo;foo(parser:didMatchSomething:)=Word;";
    
    NSError *err = nil;
    PKCollectionParser *start = (id)[_factory parserFromGrammar:g assembler:self error:&err];
    TDNotNil(start);
    
    PKParser *foo = start.subparsers[0];
    TDNotNil(foo);
    TDTrue([foo isKindOfClass:[PKWord class]]);
    
    TDEquals(start.subparsers[0], foo);
    
    TDEqualObjects(self, foo.assembler);
    TDEquals(@selector(parser:didMatchSomething:), foo.assemblerSelector);
    TDNil(foo.assemblerBlock);
    TDNil(foo.preassembler);
    TDEquals((SEL)NULL, foo.preassemblerSelector);
    TDNil(foo.preassemblerBlock);
}


- (void)testCustomPreassemblerSetting {
    NSString *g = @"@start=foo;foo(parser:didMatchSomething:)=Word;";
    
    NSError *err = nil;
    PKCollectionParser *start = (id)[_factory parserFromGrammar:g assembler:self preassembler:self error:&err];
    TDNotNil(start);
    
    PKParser *foo = start.subparsers[0];
    TDNotNil(foo);
    TDTrue([foo isKindOfClass:[PKWord class]]);
    
    TDEquals(start.subparsers[0], foo);
    
    TDEqualObjects(self, foo.assembler);
    TDEquals(@selector(parser:didMatchSomething:), foo.assemblerSelector);
    TDNil(foo.assemblerBlock);
    TDEqualObjects(self, foo.preassembler);
    TDEquals(@selector(parser:willMatchFoo:), foo.preassemblerSelector);
    TDNil(foo.preassemblerBlock);
}

@end
