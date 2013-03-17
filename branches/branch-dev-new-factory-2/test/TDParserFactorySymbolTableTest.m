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


//- (void)testSequenceAST {
//    NSString *g = @"@start=foo;foo=(Word|Number) Symbol;";
//    
//    NSError *err = nil;
//    PKSymbolTable *symTab = [_factory symbolTableFromGrammar:g error:&err];
//    TDNotNil(symTab);
//    
//    PKBaseSymbol *start = [symTab resolve:@"@start"];
//    TDNotNil(start);
//    TDTrue([start isKindOfClass:[PKVariableSymbol class]]);
//    
//    TDNotNil(start.type);
//    TDTrue([start.type isKindOfClass:[PKBuiltInTypeSymbol class]]);
//    TDEqualObjects(@"Sequence", start.type.name);
//    
//    PKBaseSymbol *foo = [symTab resolve:@"foo"];
//    TDNotNil(foo);
//    TDTrue([foo isKindOfClass:[PKVariableSymbol class]]);
//    
//    TDNotNil(foo.type);
//    TDTrue([foo.type isKindOfClass:[PKBuiltInTypeSymbol class]]);
//    TDEqualObjects(@"Sequence", foo.type.name);
//}

@end
