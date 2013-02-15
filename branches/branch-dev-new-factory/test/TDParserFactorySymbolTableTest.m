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

@interface PKParserFactory ()
- (PKAST *)ASTFromGrammar:(NSString *)g error:(NSError **)outError;
- (PKAST *)ASTFromGrammar:(NSString *)g simplify:(BOOL)simplify error:(NSError **)outError;
@end

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

    TDEqualObjects(@"(@start:SEQ num:REF word:REF)", [tab[@"@start"] treeDescription]);
    TDEqualObjects(@"num:Number", [tab[@"num"] treeDescription]);
    TDEqualObjects(@"word:Word", [tab[@"word"] treeDescription]);

    TDTrue([tab[@"num"] isKindOfClass:[PKAST class]]);
    
    PKAST *rootNode = tab[@"@start"];
    TDNotNil(rootNode);
    TDTrue([rootNode isKindOfClass:[PKAST class]]);
    TDEqualObjects(@"(@start:SEQ num:REF word:REF)", [rootNode treeDescription]);
    
    id p = [_factory parserFromGrammar:g assembler:nil error:&err];
    TDNotNil(p);
    TDTrue([p isKindOfClass:[PKSequence class]]);

//    id seq = [p subparsers][0];
//    TDTrue([p isKindOfClass:[PKSequence class]]);
//    
//    id num = [seq subparsers][0];
//    TDTrue([num isKindOfClass:[PKNumber class]]);
//
//    id word = [seq subparsers][1];
//    TDTrue([word isKindOfClass:[PKWord class]]);
    
    NSString *s = @"2 foo";
    PKAssembly *a = [PKTokenAssembly assemblyWithString:s];
    id res = [p bestMatchFor:a];
    TDNotNil(res);
    TDEqualObjects(@"[2, foo]2/foo^", [res description]);
    
//    TDEqualObjects(@"(@start:SEQ (:SEQ (foo:SEQ (:SEQ (bar:SEQ (:| (:SEQ (baz:SEQ (:SEQ :Word))) (:SEQ (bat:SEQ (:SEQ :Number)))))))))", [rootNode treeDescription]);
    //TDEqualObjects(@"(@start (foo (bar (| (baz Word) (bat Number)))))", [rootNode treeDescription]);
}


- (void)testSequenceSymbolTable2 {
    NSString *g = @"@start=num word;num=Number;word=Word num;";
    
    NSError *err = nil;
    NSDictionary *tab = [_factory symbolTableFromGrammar:g simplify:NO error:&err];
    TDNotNil(tab);
    
    TDEquals((NSUInteger)3, [tab count]);
    TDNotNil(tab[@"@start"]);
    TDNotNil(tab[@"num"]);
    TDNotNil(tab[@"word"]);
    
    TDEqualObjects(@"(@start:SEQ num:REF word:REF)", [tab[@"@start"] treeDescription]);
    TDEqualObjects(@"num:Number", [tab[@"num"] treeDescription]);
    TDEqualObjects(@"(word:SEQ :Word num:REF)", [tab[@"word"] treeDescription]);
       
    id p = [_factory parserFromGrammar:g assembler:nil error:&err];
    TDNotNil(p);
    //TDTrue([p isKindOfClass:[PKSequence class]]);
    
    NSString *s = @"2 foo 1";
    PKAssembly *a = [PKTokenAssembly assemblyWithString:s];
    id res = [p bestMatchFor:a];
    TDNotNil(res);
    TDEqualObjects(@"[2, foo, 1]2/foo/1^", [res description]);
    
    //    TDEqualObjects(@"(@start:SEQ (:SEQ (foo:SEQ (:SEQ (bar:SEQ (:| (:SEQ (baz:SEQ (:SEQ :Word))) (:SEQ (bat:SEQ (:SEQ :Number)))))))))", [rootNode treeDescription]);
    //TDEqualObjects(@"(@start (foo (bar (| (baz Word) (bat Number)))))", [rootNode treeDescription]);
}

@end