//
//  TDParserFactorySymbolTableTest.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 1/21/13.
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


- (void)testSequenceSymbolTable {
    NSString *g = @"@start=num word;num=Number;word=Word;";
    
    NSError *err = nil;
    NSDictionary *tab = [_factory symbolTableFromGrammar:g simplify:NO error:&err];
    TDNotNil(tab);
    
    TDEquals((NSUInteger)3, [tab count]);
    TDNotNil(tab[@"@start"]);
    TDNotNil(tab[@"num"]);
    TDNotNil(tab[@"word"]);

    TDEqualObjects([tab[@"@start"] treeDescription], @"(@start:DEF (:SEQ num:REF word:REF))");
    TDEqualObjects([tab[@"num"] treeDescription], @"(num:DEF (:SEQ :Number))");
    TDEqualObjects([tab[@"word"] treeDescription], @"(word:DEF (:SEQ :Word))");

    TDTrue([tab[@"num"] isKindOfClass:[PKAST class]]);
    
    PKAST *rootNode = [_factory ASTFromGrammar:g error:nil];
    TDNotNil(rootNode);
    TDTrue([rootNode isKindOfClass:[PKAST class]]);
    TDEqualObjects([rootNode treeDescription], @"(@start:DEF (:SEQ num:REF word:REF))");
    
    id p = [_factory parserFromGrammar:g assembler:nil error:&err];
    TDNotNil(p);
    TDTrue([p isKindOfClass:[PKSequence class]]);

    id seq = [p subparsers][0];
    TDTrue([p isKindOfClass:[PKSequence class]]);
    
    id num = [seq subparsers][0];
    TDTrue([num isKindOfClass:[PKSequence class]]);
    TDEquals((NSUInteger)1, [[num subparsers] count]);

    id word = [seq subparsers][1];
    TDTrue([word isKindOfClass:[PKSequence class]]);
    TDEquals((NSUInteger)1, [[word subparsers] count]);
    
    id numnum = [[num subparsers][0] subparsers][0];
    TDTrue([numnum isKindOfClass:[PKNumber class]]);

    id wordword = [[word subparsers][0] subparsers][0];
    TDTrue([wordword isKindOfClass:[PKWord class]]);
    
    
    NSString *s = @"2 foo";
    PKAssembly *a = [PKTokenAssembly assemblyWithString:s];
    id res = [p bestMatchFor:a];
    TDNotNil(res);
    TDEqualObjects(@"[2, foo]2/foo^", [res description]);
    
//    TDEqualObjects(@"(@start:SEQ (:SEQ (foo:SEQ (:SEQ (bar:SEQ (:| (:SEQ (baz:SEQ (:SEQ :Word))) (:SEQ (bat:SEQ (:SEQ :Number)))))))))", [rootNode treeDescription]);
    //TDEqualObjects(@"(@start (foo (bar (| (baz Word) (bat Number)))))", [rootNode treeDescription]);
}

@end