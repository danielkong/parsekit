//  Copyright 2010 Todd Ditchendorf
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

#import "TDArithmeticParser.h"

/*
 expr           = term (plusTerm | minusTerm)*
 term           = factor (timesFactor | divFactor)*
 plusTerm       = '+' term
 minusTerm      = '-' term
 factor         = phrase exponentFactor | phrase
 timesFactor	= '*' factor
 divFactor      = '/' factor
 exponentFactor = '^' factor
 phrase         = '(' expr ')' | Number
*/

@interface PKParser (PKParserFactoryAdditionsFriend)
- (void)setTokenizer:(PKTokenizer *)t;
@end

@implementation TDArithmeticParser

- (id)init {
    self = [super init];
    if (self) {
        [self add:self.exprParser];
        self.tokenizer = [PKTokenizer tokenizer];
//        [self.tokenizer setTokenizerState:tokenizer.symbolState from:'-' to:'-'];
    }
    return self;
}


- (void)dealloc {
    self.exprParser = nil;
    self.termParser = nil;
    self.plusTermParser = nil;
    self.minusTermParser = nil;
    self.factorParser = nil;
    self.timesFactorParser = nil;
    self.divFactorParser = nil;
    self.exponentFactorParser = nil;
    self.phraseParser = nil;
    self.tokenizer = nil;
    [super dealloc];
}


- (double)parse:(NSString *)s {
    NSAssert(self.tokenizer, @"");
    self.tokenizer.string = s;
    PKAssembly *a = [PKTokenAssembly assemblyWithTokenizer:self.tokenizer];
    a = [self completeMatchFor:a];
//    NSLog(@"\n\na: %@\n\n", a);
    NSNumber *n = [a pop];
    double f = [n doubleValue];
    return f;
}


// expr            = term (plusTerm | minusTerm)*
- (PKCollectionParser *)exprParser {
    if (!exprParser) {
        self.exprParser = [PKSequence sequence];
        [exprParser add:self.termParser];
        
        PKAlternation *a = [PKAlternation alternation];
        [a add:self.plusTermParser];
        [a add:self.minusTermParser];
        
        [exprParser add:[PKRepetition repetitionWithSubparser:a]];
    }
    return exprParser;
}


// term            = factor (timesFactor | divFactor)*
- (PKCollectionParser *)termParser {
    if (!termParser) {
        self.termParser = [PKSequence sequence];
        [termParser add:self.factorParser];
        
        PKAlternation *a = [PKAlternation alternation];
        [a add:self.timesFactorParser];
        [a add:self.divFactorParser];
        
        [termParser add:[PKRepetition repetitionWithSubparser:a]];
    }
    return termParser;
}


// plusTerm        = '+' term
- (PKCollectionParser *)plusTermParser {
    if (!plusTermParser) {
        self.plusTermParser = [PKSequence sequence];
        [plusTermParser add:[[PKSymbol symbolWithString:@"+"] discard]];
        [plusTermParser add:self.termParser];
        [plusTermParser setAssembler:self selector:@selector(parser:didMatchPlus:)];
    }
    return plusTermParser;
}


// minusTerm    = '-' term
- (PKCollectionParser *)minusTermParser {
    if (!minusTermParser) {
        self.minusTermParser = [PKSequence sequence];
        [minusTermParser add:[[PKSymbol symbolWithString:@"-"] discard]];
        [minusTermParser add:self.termParser];
        [minusTermParser setAssembler:self selector:@selector(parser:didMatchMinus:)];
    }
    return minusTermParser;
}


// factor        = phrase exponentFactor | phrase
- (PKCollectionParser *)factorParser {
    if (!factorParser) {
        self.factorParser = [PKAlternation alternation];
        
        PKSequence *s = [PKSequence sequence];
        [s add:self.phraseParser];
        [s add:self.exponentFactorParser];
        
        [factorParser add:s];
        [factorParser add:self.phraseParser];
    }
    return factorParser;
}


// timesFactor    = '*' factor
- (PKCollectionParser *)timesFactorParser {
    if (!timesFactorParser) {
        self.timesFactorParser = [PKSequence sequence];
        [timesFactorParser add:[[PKSymbol symbolWithString:@"*"] discard]];
        [timesFactorParser add:self.factorParser];
        [timesFactorParser setAssembler:self selector:@selector(parser:didMatchTimes:)];
    }
    return timesFactorParser;
}


// divFactor    = '/' factor
- (PKCollectionParser *)divFactorParser {
    if (!divFactorParser) {
        self.divFactorParser = [PKSequence sequence];
        [divFactorParser add:[[PKSymbol symbolWithString:@"/"] discard]];
        [divFactorParser add:self.factorParser];
        [divFactorParser setAssembler:self selector:@selector(parser:didMatchDivide:)];
    }
    return divFactorParser;
}


// exponentFactor    = '^' factor
- (PKCollectionParser *)exponentFactorParser {
    if (!exponentFactorParser) {
        self.exponentFactorParser = [PKSequence sequence];
        [exponentFactorParser add:[[PKSymbol symbolWithString:@"^"] discard]];
        [exponentFactorParser add:self.factorParser];
        [exponentFactorParser setAssembler:self selector:@selector(parser:didMatchExp:)];
    }
    return exponentFactorParser;
}


// phrase        = '(' expr ')' | Number
- (PKCollectionParser *)phraseParser {
    if (!phraseParser) {
        self.phraseParser = [PKAlternation alternation];
        
        PKSequence *s = [PKSequence sequence];
        [s add:[[PKSymbol symbolWithString:@"("] discard]];
        [s add:self.exprParser];
        [s add:[[PKSymbol symbolWithString:@")"] discard]];
        
        [phraseParser add:s];
        
        PKNumber *n = [PKNumber number];
        [n setAssembler:self selector:@selector(parser:didMatchNumber:)];
        [phraseParser add:n];
    }
    return phraseParser;
}


#pragma mark -
#pragma mark Assembler

- (void)parser:(PKParser *)p didMatchNumber:(PKAssembly *)a {
    PKToken *tok = [a pop];
    [a push:[NSNumber numberWithDouble:tok.floatValue]];
}


- (void)parser:(PKParser *)p didMatchPlus:(PKAssembly *)a {
    NSNumber *n2 = [a pop];
    NSNumber *n1 = [a pop];
    [a push:[NSNumber numberWithDouble:[n1 doubleValue] + [n2 doubleValue]]];
}


- (void)parser:(PKParser *)p didMatchMinus:(PKAssembly *)a {
    NSNumber *n2 = [a pop];
    NSNumber *n1 = [a pop];
    [a push:[NSNumber numberWithDouble:[n1 doubleValue] - [n2 doubleValue]]];
}


- (void)parser:(PKParser *)p didMatchTimes:(PKAssembly *)a {
    NSNumber *n2 = [a pop];
    NSNumber *n1 = [a pop];
    [a push:[NSNumber numberWithDouble:[n1 doubleValue] * [n2 doubleValue]]];
}


- (void)parser:(PKParser *)p didMatchDivide:(PKAssembly *)a {
    NSNumber *n2 = [a pop];
    NSNumber *n1 = [a pop];
    [a push:[NSNumber numberWithDouble:[n1 doubleValue] / [n2 doubleValue]]];
}


- (void)parser:(PKParser *)p didMatchExp:(PKAssembly *)a {
    NSNumber *n2 = [a pop];
    NSNumber *n1 = [a pop];
    
    double d1 = [n1 doubleValue];
    double d2 = [n2 doubleValue];
    
    double res = d1;
    for (NSUInteger i = 1; i < d2; i++) {
        res *= d1;
    }
    
    [a push:[NSNumber numberWithDouble:res]];
}

@synthesize exprParser;
@synthesize termParser;
@synthesize plusTermParser;
@synthesize minusTermParser;
@synthesize factorParser;
@synthesize timesFactorParser;
@synthesize divFactorParser;
@synthesize exponentFactorParser;
@synthesize phraseParser;
@end
