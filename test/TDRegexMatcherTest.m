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

#import "TDRegexMatcherTest.h"
#import "TDRegexMatcher.h"

@interface TDRegexMatcher ()
@property (nonatomic, retain) PKParser *parser;
@end

@implementation TDRegexMatcherTest

//- (void)setUp {
//
//    self.ass = [[[TDRegexAssembler alloc] init] autorelease];
//
//    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"regex" ofType:@"grammar"];
//    NSString *g = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
//
//    NSError *err = nil;
//    self.regexParser = [[PKParserFactory factory] parserFromGrammar:g assembler:ass error:&err];
//    if (err) {
//        NSLog(@"%@", err);
//    }
//}
//
//
//- (void)tearDown {
//    PKReleaseSubparserTree(regexParser);
//    self.regexParser = nil;
//    self.ass = nil;
//}


- (TDRegexMatcher *)matcherForRegex:(NSString *)regex {
    TDRegexMatcher *m = [TDRegexMatcher matcherFromRegex:regex];
    return m;
}


- (void)testAabPlus {
    s = @"aab+";
    
    p = [self matcherForRegex:s];
    
    TDNotNil(p);
    TDTrue([p.parser isKindOfClass:[PKSequence class]]);
    s = @"aabbbb";
    res = [p bestMatchFor:s];
    TDEqualObjects(@"[a, a, b, b, b, b]aabbbb^", [res description]);
}


- (void)testAabStar {
    s = @"aab*";
    p = [self matcherForRegex:s];
    TDNotNil(p);
    TDTrue([p.parser isKindOfClass:[PKSequence class]]);
    s = @"aabbbb";
    res = [p bestMatchFor:s];
    TDEqualObjects(@"[a, a, b, b, b, b]aabbbb^", [res description]);
}


- (void)testAabQuestion {
    s = @"aab?";
    p = [self matcherForRegex:s];
    TDNotNil(p);
    TDTrue([p.parser isKindOfClass:[PKSequence class]]);
    s = @"aabbbb";
    res = [p bestMatchFor:s];
    TDEqualObjects(@"[a, a, b]aab^bbb", [res description]);
}


- (void)testAb {
    s = @"ab";
    p = [self matcherForRegex:s];

    TDNotNil(p);
    TDTrue([p.parser isKindOfClass:[PKSequence class]]);
    s = @"ab";
    res = [p bestMatchFor:s];
    TDEqualObjects(@"[a, b]ab^", [res description]);
}


- (void)testAbc {
    s = @"abc";
    p = [self matcherForRegex:s];

    TDNotNil(p);
    TDTrue([p.parser isKindOfClass:[PKSequence class]]);
    s = @"abc";
    res = [p bestMatchFor:s];
    TDEqualObjects(@"[a, b, c]abc^", [res description]);
}


- (void)testAOrB {
    s = @"a|b";
    
    p = [self matcherForRegex:s];
    TDNotNil(p);
    TDTrue([p.parser isKindOfClass:[PKAlternation class]]);
    s = @"b";
    res = [p bestMatchFor:s];
    TDEqualObjects(@"[b]b^", [res description]);
}


- (void)test4Or7 {
    s = @"4|7";
    
    p = [self matcherForRegex:s];
    TDNotNil(p);
    s = @"4";
    res = [p bestMatchFor:s];
    TDEqualObjects(@"[4]4^", [res description]);
}


- (void)testAOrBStar {
    s = @"a|b*";
    
    p = [self matcherForRegex:s];
    TDNotNil(p);
    TDTrue([p.parser isKindOfClass:[PKAlternation class]]);
    s = @"bbb";
    res = [p bestMatchFor:s];
    TDEqualObjects(@"[b, b, b]bbb^", [res description]);
}


- (void)testAOrBPlus {
    s = @"a|b+";
    
    p = [self matcherForRegex:s];
    TDNotNil(p);
    TDTrue([p.parser isKindOfClass:[PKAlternation class]]);
    s = @"bbb";
    res = [p bestMatchFor:s];
    TDEqualObjects(@"[b, b, b]bbb^", [res description]);
    
    s = @"abbb";
    res = [p bestMatchFor:s];
    TDEqualObjects(@"[a]a^bbb", [res description]);
}


- (void)testAOrBQuestion {
    s = @"a|b?";
    
    p = [self matcherForRegex:s];
    TDNotNil(p);
    TDTrue([p.parser isKindOfClass:[PKAlternation class]]);
    s = @"bbb";
    res = [p bestMatchFor:s];
    TDEqualObjects(@"[b]b^bb", [res description]);
    
    s = @"abbb";
    res = [p bestMatchFor:s];
    TDEqualObjects(@"[a]a^bbb", [res description]);
}


- (void)testParenAOrBParenStar {
    s = @"(a|b)*";
    
    p = [self matcherForRegex:s];
    TDNotNil(p);
    TDTrue([p.parser isKindOfClass:[PKRepetition class]]);
    s = @"bbbaaa";
    res = [p bestMatchFor:s];
    TDEqualObjects(@"[b, b, b, a, a, a]bbbaaa^", [res description]);
}


- (void)testParenAOrBParenPlus {
    s = @"(a|b)+";
    
    p = [self matcherForRegex:s];
    TDNotNil(p);
    TDTrue([p.parser isKindOfClass:[PKSequence class]]);
    s = @"bbbaaa";
    res = [p bestMatchFor:s];
    TDEqualObjects(@"[b, b, b, a, a, a]bbbaaa^", [res description]);
}


- (void)testParenAOrBParenQuestion {
    s = @"(a|b)?";
    
    p = [self matcherForRegex:s];
    TDNotNil(p);
    TDTrue([p.parser isKindOfClass:[PKAlternation class]]);
    s = @"bbbaaa";
    res = [p bestMatchFor:s];
    TDEqualObjects(@"[b]b^bbaaa", [res description]);
}


- (void)testOneInterval {
    s = @"a{1}";

    p = [self matcherForRegex:s];
    TDNotNil(p);
    TDTrue([p.parser isKindOfClass:[PKSequence class]]);
    s = @"a";
    res = [p bestMatchFor:s];
    TDEqualObjects(@"[a]a^", [res description]);
    
    s = @"aa";
    res = [p bestMatchFor:s];
    TDEqualObjects(@"[a]a^a", [res description]);
}


- (void)testTwoInterval {
    s = @"a{1,2}";
    
    p = [self matcherForRegex:s];
    TDNotNil(p);
    TDTrue([p.parser isKindOfClass:[PKSequence class]]);
    s = @"a";
    res = [p bestMatchFor:s];
    TDEqualObjects(@"[a]a^", [res description]);
    
    s = @"aa";
    res = [p bestMatchFor:s];
    TDEqualObjects(@"[a, a]aa^", [res description]);
    
    s = @"aaa";
    res = [p bestMatchFor:s];
    TDEqualObjects(@"[a, a]aa^a", [res description]);
}


- (void)testDot {
    s = @".";
    
    p = [self matcherForRegex:s];
    TDNotNil(p);
    TDTrue([p.parser isKindOfClass:[PKParser class]]);
    s = @"a";
    res = [p bestMatchFor:s];
    TDEqualObjects(@"[a]a^", [res description]);
    
    s = @"aa";
    res = [p bestMatchFor:s];
    TDEqualObjects(@"[a]a^a", [res description]);
    
    s = @"aaa";
    res = [p bestMatchFor:s];
    TDEqualObjects(@"[a]a^aa", [res description]);
}

@synthesize regexParser;
@synthesize ass;
@end
