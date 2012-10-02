//  Copyright 2012 Todd Ditchendorf
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

#import "TDRegexParserTest.h"

@implementation TDRegexParserTest

- (void)setUp {

    self.ass = [[[TDRegexAssembler alloc] init] autorelease];

    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"regex" ofType:@"grammar"];
    NSString *g = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];

    NSError *err = nil;
    self.regexParser = [[PKParserFactory factory] parserFromGrammar:g assembler:ass error:&err];
    if (err) {
        NSLog(@"%@", err);
    }
}


- (void)tearDown {
    PKReleaseSubparserTree(regexParser);
    self.regexParser = nil;
    self.ass = nil;
}


- (PKParser *)parserForRegex:(NSString *)regex {
    a = [PKCharacterAssembly assemblyWithString:s];
    a = (PKCharacterAssembly *)[regexParser completeMatchFor:a];
    return [a pop];
}


- (void)testAabPlus {
    s = @"aab+";
    
    p = [self parserForRegex:s];
    
    TDNotNil(p);
    TDTrue([p isKindOfClass:[PKSequence class]]);
    s = @"aabbbb";
    a = [PKCharacterAssembly assemblyWithString:s];
    res = (PKCharacterAssembly *)[p bestMatchFor:a];
    TDEqualObjects(@"[a, a, b, b, b, b]aabbbb^", [res description]);
}


- (void)testAabStar {
    s = @"aab*";
    p = [self parserForRegex:s];
    TDNotNil(p);
    TDTrue([p isKindOfClass:[PKSequence class]]);
    s = @"aabbbb";
    a = [PKCharacterAssembly assemblyWithString:s];
    res = (PKCharacterAssembly *)[p bestMatchFor:a];
    TDEqualObjects(@"[a, a, b, b, b, b]aabbbb^", [res description]);
}


- (void)testAabQuestion {
    s = @"aab?";
    p = [self parserForRegex:s];
    TDNotNil(p);
    TDTrue([p isKindOfClass:[PKSequence class]]);
    s = @"aabbbb";
    a = [PKCharacterAssembly assemblyWithString:s];
    res = (PKCharacterAssembly *)[p bestMatchFor:a];
    TDEqualObjects(@"[a, a, b]aab^bbb", [res description]);
}


- (void)testAb {
    s = @"ab";
    p = [self parserForRegex:s];

    TDNotNil(p);
    TDTrue([p isKindOfClass:[PKSequence class]]);
    s = @"ab";
    a = [PKCharacterAssembly assemblyWithString:s];
    res = (PKCharacterAssembly *)[p bestMatchFor:a];
    TDEqualObjects(@"[a, b]ab^", [res description]);
}


- (void)testAbc {
    s = @"abc";
    p = [self parserForRegex:s];

    TDNotNil(p);
    TDTrue([p isKindOfClass:[PKSequence class]]);
    s = @"abc";
    a = [PKCharacterAssembly assemblyWithString:s];
    res = (PKCharacterAssembly *)[p bestMatchFor:a];
    TDEqualObjects(@"[a, b, c]abc^", [res description]);
}


- (void)testAOrB {
    s = @"a|b";
    
    p = [self parserForRegex:s];
    TDNotNil(p);
    TDTrue([p isKindOfClass:[PKAlternation class]]);
    s = @"b";
    a = [PKCharacterAssembly assemblyWithString:s];
    res = (PKCharacterAssembly *)[p bestMatchFor:a];
    TDEqualObjects(@"[b]b^", [res description]);
}


- (void)test4Or7 {
    s = @"4|7";
    
    p = [self parserForRegex:s];
    TDNotNil(p);
    TDTrue([p isKindOfClass:[PKAlternation class]]);
    s = @"4";
    a = [PKCharacterAssembly assemblyWithString:s];
    res = (PKCharacterAssembly *)[p bestMatchFor:a];
    TDEqualObjects(@"[4]4^", [res description]);
}


- (void)testAOrBStar {
    s = @"a|b*";
    
    p = [self parserForRegex:s];
    TDNotNil(p);
    TDTrue([p isKindOfClass:[PKAlternation class]]);
    s = @"bbb";
    a = [PKCharacterAssembly assemblyWithString:s];
    res = (PKCharacterAssembly *)[p bestMatchFor:a];
    TDEqualObjects(@"[b, b, b]bbb^", [res description]);
}


- (void)testAOrBPlus {
    s = @"a|b+";
    
    p = [self parserForRegex:s];
    TDNotNil(p);
    TDTrue([p isKindOfClass:[PKAlternation class]]);
    s = @"bbb";
    a = [PKCharacterAssembly assemblyWithString:s];
    res = (PKCharacterAssembly *)[p bestMatchFor:a];
    TDEqualObjects(@"[b, b, b]bbb^", [res description]);
    
    s = @"abbb";
    a = [PKCharacterAssembly assemblyWithString:s];
    res = (PKCharacterAssembly *)[p bestMatchFor:a];
    TDEqualObjects(@"[a]a^bbb", [res description]);
}


- (void)testAOrBQuestion {
    s = @"a|b?";
    
    p = [self parserForRegex:s];
    TDNotNil(p);
    TDTrue([p isKindOfClass:[PKAlternation class]]);
    s = @"bbb";
    a = [PKCharacterAssembly assemblyWithString:s];
    res = (PKCharacterAssembly *)[p bestMatchFor:a];
    TDEqualObjects(@"[b]b^bb", [res description]);
    
    s = @"abbb";
    a = [PKCharacterAssembly assemblyWithString:s];
    res = (PKCharacterAssembly *)[p bestMatchFor:a];
    TDEqualObjects(@"[a]a^bbb", [res description]);
}


//- (void)testParenAOrBParenStar {
//    s = @"(a|b)*";
//    
//    p = [self parserForRegex:s];
//    TDNotNil(p);
//    TDTrue([p isKindOfClass:[PKRepetition class]]);
//    s = @"bbbaaa";
//    a = [PKCharacterAssembly assemblyWithString:s];
//    res = (PKCharacterAssembly *)[p bestMatchFor:a];
//    TDEqualObjects(@"[b, b, b, a, a, a]bbbaaa^", [res description]);
//}


//- (void)testParenAOrBParenPlus {
//    s = @"(a|b)+";
//    a = [PKCharacterAssembly assemblyWithString:s];
//    res = [p bestMatchFor:a];
//    TDNotNil(res);
//    TDEqualObjects(@"[Sequence](a|b)+^", [res description]);
//    PKSequence *seq = [res pop];
//    TDTrue([seq isMemberOfClass:[PKSequence class]]);
//    
//    TDEquals((NSUInteger)2, [seq.subparsers count]);
//    
//    PKAlternation *alt = [seq.subparsers objectAtIndex:0];
//    TDTrue([alt isMemberOfClass:[PKAlternation class]]);
//    TDEquals((NSUInteger)2, [alt.subparsers count]);
//    
//    PKSpecificChar *c = [alt.subparsers objectAtIndex:0];
//    TDTrue([c isMemberOfClass:[PKSpecificChar class]]);
//    TDEqualObjects(@"a", c.string);
//    
//    c = [alt.subparsers objectAtIndex:1];
//    TDTrue([c isMemberOfClass:[PKSpecificChar class]]);
//    TDEqualObjects(@"b", c.string);
//    
//    PKRepetition *rep = [seq.subparsers objectAtIndex:1];
//    TDTrue([rep isMemberOfClass:[PKRepetition class]]);
//    
//    alt = (PKAlternation *)rep.subparser;
//    TDEqualObjects([PKAlternation class], [alt class]);
//    
//    c = [alt.subparsers objectAtIndex:0];
//    TDTrue([c isMemberOfClass:[PKSpecificChar class]]);
//    TDEqualObjects(@"a", c.string);
//    
//    c = [alt.subparsers objectAtIndex:1];
//    TDTrue([c isMemberOfClass:[PKSpecificChar class]]);
//    TDEqualObjects(@"b", c.string);
//    
//    p = [self parserForRegex:s];
//    TDNotNil(p);
//    TDTrue([p isKindOfClass:[PKSequence class]]);
//    s = @"bbbaaa";
//    a = [PKCharacterAssembly assemblyWithString:s];
//    res = (PKCharacterAssembly *)[p bestMatchFor:a];
//    TDEqualObjects(@"[b, b, b, a, a, a]bbbaaa^", [res description]);
//}
//
//
//- (void)testParenAOrBParenQuestion {
//    s = @"(a|b)?";
//    a = [PKCharacterAssembly assemblyWithString:s];
//    res = [p bestMatchFor:a];
//    TDNotNil(res);
//    TDEqualObjects(@"[Alternation](a|b)?^", [res description]);
//    PKAlternation *alt = [res pop];
//    TDTrue([alt isMemberOfClass:[PKAlternation class]]);
//    
//    TDEquals((NSUInteger)2, [alt.subparsers count]);
//    PKEmpty *e = [alt.subparsers objectAtIndex:0];
//    TDTrue([PKEmpty class] == [e class]);
//    
//    alt = [alt.subparsers objectAtIndex:1];
//    TDTrue([alt isMemberOfClass:[PKAlternation class]]);
//    TDEquals((NSUInteger)2, [alt.subparsers count]);
//    
//    PKSpecificChar *c = [alt.subparsers objectAtIndex:0];
//    TDTrue([c isMemberOfClass:[PKSpecificChar class]]);
//    TDEqualObjects(@"a", c.string);
//    
//    c = [alt.subparsers objectAtIndex:1];
//    TDTrue([c isMemberOfClass:[PKSpecificChar class]]);
//    TDEqualObjects(@"b", c.string);
//    
//    p = [self parserForRegex:s];
//    TDNotNil(p);
//    TDTrue([p isKindOfClass:[PKAlternation class]]);
//    s = @"bbbaaa";
//    a = [PKCharacterAssembly assemblyWithString:s];
//    res = (PKCharacterAssembly *)[p bestMatchFor:a];
//    TDEqualObjects(@"[b]b^bbaaa", [res description]);
//}
//
//
//- (void)testOneInterval {
//    s = @"a{1}";
//    a = [PKCharacterAssembly assemblyWithString:s];
//    res = [p bestMatchFor:a];
//    TDNotNil(res);
//    TDEqualObjects(@"[Sequence]a{1}^", [res description]);
//    PKSequence *seq = [res pop];
//    TDTrue([seq isMemberOfClass:[PKSequence class]]);
//    
//    p = [self parserForRegex:s];
//    TDNotNil(p);
//    TDTrue([p isKindOfClass:[PKSequence class]]);
//    s = @"a";
//    a = [PKCharacterAssembly assemblyWithString:s];
//    res = (PKCharacterAssembly *)[p bestMatchFor:a];
//    TDEqualObjects(@"[a]a^", [res description]);
//    
//    s = @"aa";
//    a = [PKCharacterAssembly assemblyWithString:s];
//    res = (PKCharacterAssembly *)[p bestMatchFor:a];
//    TDEqualObjects(@"[a]a^a", [res description]);
//}
//
//
//- (void)testTwoInterval {
//    s = @"a{1,2}";
//    a = [PKCharacterAssembly assemblyWithString:s];
//    res = [p bestMatchFor:a];
//    TDNotNil(res);
//    TDEqualObjects(@"[Sequence]a{1,2}^", [res description]);
//    PKSequence *seq = [res pop];
//    TDTrue([seq isMemberOfClass:[PKSequence class]]);
//    
//    p = [self parserForRegex:s];
//    TDNotNil(p);
//    TDTrue([p isKindOfClass:[PKSequence class]]);
//    s = @"a";
//    a = [PKCharacterAssembly assemblyWithString:s];
//    res = (PKCharacterAssembly *)[p bestMatchFor:a];
//    TDEqualObjects(@"[a]a^", [res description]);
//    
//    s = @"aa";
//    a = [PKCharacterAssembly assemblyWithString:s];
//    res = (PKCharacterAssembly *)[p bestMatchFor:a];
//    TDEqualObjects(@"[a, a]aa^", [res description]);
//    
//    s = @"aaa";
//    a = [PKCharacterAssembly assemblyWithString:s];
//    res = (PKCharacterAssembly *)[p bestMatchFor:a];
//    TDEqualObjects(@"[a, a]aa^a", [res description]);
//}
//
//
//- (void)testDot {
//    s = @".";
//    a = [PKCharacterAssembly assemblyWithString:s];
//    res = [p bestMatchFor:a];
//    TDNotNil(res);
//    TDEqualObjects(@"[Negation].^", [res description]);
//    PKSequence *seq = [res pop];
//    TDTrue([seq isMemberOfClass:[PKSequence class]]);
//    
//    p = [self parserForRegex:s];
//    TDNotNil(p);
//    TDTrue([p isKindOfClass:[PKSequence class]]);
//    s = @"a";
//    a = [PKCharacterAssembly assemblyWithString:s];
//    res = (PKCharacterAssembly *)[p bestMatchFor:a];
//    TDEqualObjects(@"[a]a^", [res description]);
//    
//    s = @"aa";
//    a = [PKCharacterAssembly assemblyWithString:s];
//    res = (PKCharacterAssembly *)[p bestMatchFor:a];
//    TDEqualObjects(@"[a, a]aa^", [res description]);
//    
//    s = @"aaa";
//    a = [PKCharacterAssembly assemblyWithString:s];
//    res = (PKCharacterAssembly *)[p bestMatchFor:a];
//    TDEqualObjects(@"[a, a]aa^a", [res description]);
//}

@synthesize regexParser;
@synthesize ass;
@end
