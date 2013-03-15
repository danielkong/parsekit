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

#import "PKGrammarParser.h"
#import <ParseKit/ParseKit.h>

@interface NSObject (PKGrammarParserAdditions)
- (void)parser:(PKParser *)p didMatchTokenizerDirective:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchDecl:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchCallback:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchSubExpr:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchExpression:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchStartProduction:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchVarProduction:(PKAssembly *)a;
- (void)parser:(PKParser *)p willMatchAnd:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchAnd:(PKAssembly *)a;
//- (void)parser:(PKParser *)p didMatchTrack:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchIntersection:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchDifference:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchPatternOptions:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchPattern:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchDiscard:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchLiteral:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchVariable:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchConstant:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchSpace:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchSpecificConstant:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchDelimitedString:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchNum:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchStar:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchPlus:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchQuestion:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchPhraseCardinality:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchCardinality:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchOr:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchNegation:(PKAssembly *)a;
@end

@interface PKGrammarParser ()
- (PKAlternation *)zeroOrOne:(PKParser *)p;
- (PKSequence *)oneOrMore:(PKParser *)p;
@end

@implementation PKGrammarParser

- (id)initWithAssembler:(id)a {
    self = [super init];
    if (self) {
        assembler = a;
    }
    return self;
}


- (void)dealloc {
    PKReleaseSubparserTree(self.parser);

    self.parser = nil;
    self.statementParser = nil;
    self.tokenizerDirectiveParser = nil;
    self.declParser = nil;
    self.productionParser = nil;
    self.varProductionParser = nil;
    self.startProductionParser = nil;
    self.tokenizerDirectiveParser = nil;
    self.callbackParser = nil;
    self.selectorParser = nil;
    self.exprParser = nil;
    self.termParser = nil;
    self.orTermParser = nil;
    self.factorParser = nil;
    self.nextFactorParser = nil;
    self.phraseParser = nil;
    self.phraseStarParser = nil;
    self.phrasePlusParser = nil;
    self.phraseQuestionParser = nil;
    self.phraseCardinalityParser = nil;
    self.cardinalityParser = nil;
    self.primaryExprParser = nil;
    self.negatedPrimaryExprParser = nil;
    self.barePrimaryExprParser = nil;
    self.predicateParser = nil;
    self.intersectionParser = nil;
    self.differenceParser = nil;
    self.atomicValueParser = nil;
    self.parserParser = nil;
    self.discardParser = nil;
    self.patternParser = nil;
    self.delimitedStringParser = nil;
    self.literalParser = nil;
    self.variableParser = nil;
    self.constantParser = nil;
    self.specificConstantParser = nil;
    [super dealloc];
}


- (PKAlternation *)zeroOrOne:(PKParser *)p {
    PKAlternation *a = [PKAlternation alternation];
    [a add:[PKEmpty empty]];
    [a add:p];
    return a;
}


- (PKSequence *)oneOrMore:(PKParser *)p {
    PKSequence *s = [PKSequence sequence];
    [s add:p];
    [s add:[PKRepetition repetitionWithSubparser:p]];
    return s;
}


// @start               = statement*;
// statement            = tokenizerDirective | decl;
// tokenizerDirective   = S* (/@.+/ - '@start') S* '=' (S! | ~';')+ ';'!;
// decl                 = S* production S* callback? S* '=' expr ';'!;
// production           = startProduction | varProduction;
// startProduction      = '@start';
// varProduction        = Word - startProduction;
// callback             = S* '(' S* selector S* ')';
// selector             = Word ':';
// expr                 = term orTerm* S*;
// term                 = factor nextFactor*;
// orTerm               = S* '|' S* term;
// factor               = phrase | phraseStar | phrasePlus | phraseQuestion | phraseCardinality;
// nextFactor           = S factor;

// phrase               = primaryExpr predicate*;
// phraseStar           = phrase S* '*';
// phrasePlus           = phrase S* '+';
// phraseQuestion       = phrase S* '?';
// phraseCardinality    = phrase S* cardinality;
// cardinality          = '{' S* Number (S* ',' S* Number)? S* '}';

// predicate            = S* (intersection | difference);
// intersection         = '&' S* primaryExpr;
// difference           = '-' S* primaryExpr;

// primaryExpr          = negatedPrimaryExpr | barePrimaryExpr;
// negatedPrimaryExpr   = '~' barePrimaryExpr;
// barePrimaryExpr      = atomicValue | subSeqExpr | subTrackExpr;
// subSeqExpr           = '(' expr ')';
// subTrackExpr         = '[' expr ']';
// atomicValue          = parser discard?;
// parser               = pattern | literal | variable | constant | specificConstant | delimitedString;
// discard              = S* '!';
// pattern              = DelimitedString('/', '/') (Word & /[imxsw]+/)?;
// delimitedString      = 'DelimitedString' S* '(' S* QuotedString (S* ',' QuotedString)? S* ')';
// literal              = QuotedString;
// variable             = LowercaseWord;
// constant             = UppercaseWord;


- (PKCompositeParser *)parser {
    if (!parser) {
        self.parser = [PKRepetition repetitionWithSubparser:self.statementParser];
    }
    return parser;
}


// statement            = tokenizerDirective | decl;
- (PKCollectionParser *)statementParser {
    if (!statementParser) {
        self.statementParser = [PKAlternation alternation];
        statementParser.name = @"statement";
        [statementParser add:self.tokenizerDirectiveParser];
        [statementParser add:self.declParser];
    }
    return statementParser;
}


// tokenizerDirective   = S* ((Word & /@.+/) - '@start') S* '=' (S! | ~';')+ ';'!;
- (PKCollectionParser *)tokenizerDirectiveParser {
    if (!tokenizerDirectiveParser) {
        self.tokenizerDirectiveParser = [PKSequence sequence];
        tokenizerDirectiveParser.name = @"tokenizerDirective";
        [tokenizerDirectiveParser add:self.optionalWhitespaceParser];
        
        PKPattern *regex = [PKPattern patternWithString:@"@.+"];
        PKIntersection *dir = [PKIntersection intersectionWithSubparsers:[PKWord word], regex, nil];
        PKParser *notStart = [PKDifference differenceWithSubparser:dir minus:[PKLiteral literalWithString:@"@start"]];
        [tokenizerDirectiveParser add:notStart];
        [tokenizerDirectiveParser add:self.optionalWhitespaceParser];
        [tokenizerDirectiveParser add:[PKSymbol symbolWithString:@"="]];
        
        PKParser *notSemi = [PKNegation negationWithSubparser:[PKSymbol symbolWithString:@";"]];
        PKAlternation *alt = [PKAlternation alternation];
        [alt add:[[PKWhitespace whitespace] discard]];
        [alt add:notSemi];
        
        [tokenizerDirectiveParser add:[self oneOrMore:alt]];
        [tokenizerDirectiveParser add:[[PKSymbol symbolWithString:@";"] discard]];
        
        [tokenizerDirectiveParser setAssembler:assembler selector:@selector(parser:didMatchTokenizerDirective:)];
    }
    return tokenizerDirectiveParser;
}


// decl                 = S* production S* callback? S* '=' expr ';'!;
- (PKCollectionParser *)declParser {
    if (!declParser) {
        self.declParser = [PKSequence sequence];
        declParser.name = @"decl";
        [declParser add:self.optionalWhitespaceParser];
        [declParser add:self.productionParser];
        [declParser add:self.optionalWhitespaceParser];
        [declParser add:[self zeroOrOne:self.callbackParser]];
        [declParser add:self.optionalWhitespaceParser];
        [declParser add:[PKSymbol symbolWithString:@"="]];
        [declParser add:self.exprParser];
        [declParser add:[[PKSymbol symbolWithString:@";"] discard]];
        
        [declParser setAssembler:assembler selector:@selector(parser:didMatchDecl:)];
    }
    return declParser;
}


// productionParser              = varProduction | startProduction;
- (PKCollectionParser *)productionParser {
    if (!productionParser) {
        self.productionParser = [PKAlternation alternation];
        productionParser.name = @"production";
        [productionParser add:self.varProductionParser];
        [productionParser add:self.startProductionParser];
    }
    return productionParser;
}


// startProduction              = '@start';
- (PKCollectionParser *)startProductionParser {
    if (!startProductionParser) {
        self.startProductionParser = [PKSequence sequence];
        startProductionParser.name = @"startProduction";
        [startProductionParser add:[PKLiteral literalWithString:@"@start"]];
        [startProductionParser setAssembler:assembler selector:@selector(parser:didMatchStartProduction:)];
    }
    return startProductionParser;
}


// varProduction        = Word - startProduction;
- (PKCollectionParser *)varProductionParser {
    if (!varProductionParser) {
        self.varProductionParser = [PKSequence sequence];
        varProductionParser.name = @"varProduction";
        [varProductionParser add:[PKDifference differenceWithSubparser:[PKWord word] minus:self.startProductionParser]];
        [varProductionParser setAssembler:assembler selector:@selector(parser:didMatchVarProduction:)];
    }
    return varProductionParser;
}


// callback             = S* '(' S* selector S* ')';
- (PKCollectionParser *)callbackParser {
    if (!callbackParser) {
        self.callbackParser = [PKSequence sequence];
        callbackParser.name = @"callback";
        [callbackParser add:self.optionalWhitespaceParser];
        
        PKTrack *tr = [PKTrack track];
        [tr add:[[PKSymbol symbolWithString:@"("] discard]];
        [tr add:self.optionalWhitespaceParser];
        [tr add:self.selectorParser];
        [tr add:self.optionalWhitespaceParser];
        [tr add:[[PKSymbol symbolWithString:@")"] discard]];
        
        [callbackParser add:tr];
        [callbackParser setAssembler:assembler selector:@selector(parser:didMatchCallback:)];
    }
    return callbackParser;
}


// selector             = LowercaseWord ':' LowercaseWord ':';
- (PKCollectionParser *)selectorParser {
    if (!selectorParser) {
        self.selectorParser = [PKTrack track];
        selectorParser.name = @"selector";
        [selectorParser add:[PKLowercaseWord word]];
        [selectorParser add:[[PKSymbol symbolWithString:@":"] discard]];
        [selectorParser add:[PKLowercaseWord word]];
        [selectorParser add:[[PKSymbol symbolWithString:@":"] discard]];
    }
    return selectorParser;
}


// expr        = S* term orTerm* S*;
- (PKCollectionParser *)exprParser {
    if (!exprParser) {
        self.exprParser = [PKSequence sequence];
        exprParser.name = @"expr";
        [exprParser add:self.optionalWhitespaceParser];
        [exprParser add:self.termParser];
        [exprParser add:[PKRepetition repetitionWithSubparser:self.orTermParser]];
        [exprParser add:self.optionalWhitespaceParser];
        [exprParser setAssembler:assembler selector:@selector(parser:didMatchExpression:)];
    }
    return exprParser;
}


// term                = factor nextFactor*;
- (PKCollectionParser *)termParser {
    if (!termParser) {
        self.termParser = [PKSequence sequence];
        termParser.name = @"term";
        [termParser add:self.factorParser];
        [termParser add:[PKRepetition repetitionWithSubparser:self.nextFactorParser]];
        
//        [termParser setAssembler:assembler selector:@selector(parser:didMatchAnd:)];
    }
    return termParser;
}


// orTerm               = S* '|' S* term;
- (PKCollectionParser *)orTermParser {
    if (!orTermParser) {
        self.orTermParser = [PKSequence sequence];
        orTermParser.name = @"orTerm";
        [orTermParser add:self.optionalWhitespaceParser];
        
        PKTrack *tr = [PKTrack track];
        [tr add:[PKSymbol symbolWithString:@"|"]]; // preserve as fence
        [tr add:self.optionalWhitespaceParser];
        [tr add:self.termParser];
        
        [orTermParser add:tr];
        [orTermParser setAssembler:assembler selector:@selector(parser:didMatchOr:)];
    }
    return orTermParser;
}


// factor               = phrase | phraseStar | phrasePlus | phraseQuestion | phraseCardinality;
- (PKCollectionParser *)factorParser {
    if (!factorParser) {
        self.factorParser = [PKAlternation alternation];
        factorParser.name = @"factor";
        [factorParser add:self.phraseParser];
        [factorParser add:self.phraseStarParser];
        [factorParser add:self.phrasePlusParser];
        [factorParser add:self.phraseQuestionParser];
        [factorParser add:self.phraseCardinalityParser];
    }
    return factorParser;
}


// nextFactor           = S factor;
- (PKCollectionParser *)nextFactorParser {
    if (!nextFactorParser) {
        self.nextFactorParser = [PKSequence sequence];
        nextFactorParser.name = @"nextFactor";
        
        PKParser *space = self.whitespaceParser;
        [space setAssembler:assembler selector:@selector(parser:willMatchAnd:)];
        [nextFactorParser add:space];
        
        PKAlternation *a = [PKAlternation alternation];
        [a add:self.phraseParser];
        [a add:self.phraseStarParser];
        [a add:self.phrasePlusParser];
        [a add:self.phraseQuestionParser];
        [a add:self.phraseCardinalityParser];
        
        [nextFactorParser add:a];

        [nextFactorParser setAssembler:assembler selector:@selector(parser:didMatchAnd:)];
}
    return nextFactorParser;
}


// phrase               = primaryExpr predicate*;
- (PKCollectionParser *)phraseParser {
    if (!phraseParser) {
        self.phraseParser = [PKSequence sequence];
        phraseParser.name = @"phrase";
        [phraseParser add:self.primaryExprParser];
        [phraseParser add:[PKRepetition repetitionWithSubparser:self.predicateParser]];
    }
    return phraseParser;
}


// primaryExpr          = negatedPrimaryExpr | barePrimaryExpr;
- (PKCollectionParser *)primaryExprParser {
    if (!primaryExprParser) {
        self.primaryExprParser = [PKAlternation alternation];
        primaryExprParser.name = @"primaryExpr";
        [primaryExprParser add:self.negatedPrimaryExprParser];
        [primaryExprParser add:self.barePrimaryExprParser];
    }
    return primaryExprParser;
}


// negatedPrimaryExpr   = '~' barePrimaryExpr;
- (PKCollectionParser *)negatedPrimaryExprParser {
    if (!negatedPrimaryExprParser) {
        self.negatedPrimaryExprParser = [PKSequence sequence];
        negatedPrimaryExprParser.name = @"negatedPrimaryExpr";
        [negatedPrimaryExprParser add:[[PKLiteral literalWithString:@"~"] discard]];
        [negatedPrimaryExprParser add:self.barePrimaryExprParser];
        [negatedPrimaryExprParser setAssembler:assembler selector:@selector(parser:didMatchNegation:)];
    }
    return negatedPrimaryExprParser;
}


// barePrimaryExpr      = atomicValue | subSeqExpr | subTrackExpr;
// subSeqExpr           = '(' expr ')';
// subTrackExpr         = '[' expr ']';
- (PKCollectionParser *)barePrimaryExprParser {
    if (!barePrimaryExprParser) {
        self.barePrimaryExprParser = [PKAlternation alternation];
        barePrimaryExprParser.name = @"barePrimaryExpr";
        [barePrimaryExprParser add:self.atomicValueParser];
        
        PKSequence *s = [PKSequence sequence];
        [s add:[PKSymbol symbolWithString:@"("]];
        [s add:self.exprParser];
        [s add:[[PKSymbol symbolWithString:@")"] discard]];
        [barePrimaryExprParser add:s];

        PKTrack *tr = [PKTrack track];
        [tr add:[PKSymbol symbolWithString:@"["]];
        [tr add:self.exprParser];
        [tr add:[[PKSymbol symbolWithString:@"]"] discard]];
        [barePrimaryExprParser add:tr];
    }
    return barePrimaryExprParser;
}


// predicate            = S* (intersection | difference);
- (PKCollectionParser *)predicateParser {
    if (!predicateParser) {
        self.predicateParser = [PKSequence sequence];
        predicateParser.name = @"predicate";
        [predicateParser add:self.optionalWhitespaceParser];
        
        PKAlternation *a = [PKAlternation alternation];
        [a add:self.intersectionParser];
        [a add:self.differenceParser];
        
        [predicateParser add:a];
    }
    return predicateParser;
}


// intersection         = '&' S* primaryExpr;
- (PKCollectionParser *)intersectionParser {
    if (!intersectionParser) {
        self.intersectionParser = [PKTrack track];
        intersectionParser.name = @"intersection";
        
        PKTrack *tr = [PKTrack track];
        [tr add:[[PKSymbol symbolWithString:@"&"] discard]];
        [tr add:self.optionalWhitespaceParser];
        [tr add:self.primaryExprParser];
        
        [intersectionParser add:tr];
        [intersectionParser setAssembler:assembler selector:@selector(parser:didMatchIntersection:)];
    }
    return intersectionParser;
}


// difference            = '-' S* primaryExpr;
- (PKCollectionParser *)differenceParser {
    if (!differenceParser) {
        self.differenceParser = [PKTrack track];
        differenceParser.name = @"difference";
        
        PKTrack *tr = [PKTrack track];
        [tr add:[[PKSymbol symbolWithString:@"-"] discard]];
        [tr add:self.optionalWhitespaceParser];
        [tr add:self.primaryExprParser];
        
        [differenceParser add:tr];
        [differenceParser setAssembler:assembler selector:@selector(parser:didMatchDifference:)];
    }
    return differenceParser;
}


// phraseStar           = phrase S* '*';
- (PKCollectionParser *)phraseStarParser {
    if (!phraseStarParser) {
        self.phraseStarParser = [PKSequence sequence];
        phraseStarParser.name = @"phraseStar";
        [phraseStarParser add:self.phraseParser];
        [phraseStarParser add:self.optionalWhitespaceParser];
        [phraseStarParser add:[[PKSymbol symbolWithString:@"*"] discard]];
        [phraseStarParser setAssembler:assembler selector:@selector(parser:didMatchStar:)];
    }
    return phraseStarParser;
}


// phrasePlus           = phrase S* '+';
- (PKCollectionParser *)phrasePlusParser {
    if (!phrasePlusParser) {
        self.phrasePlusParser = [PKSequence sequence];
        phrasePlusParser.name = @"phrasePlus";
        [phrasePlusParser add:self.phraseParser];
        [phrasePlusParser add:self.optionalWhitespaceParser];
        [phrasePlusParser add:[[PKSymbol symbolWithString:@"+"] discard]];
        [phrasePlusParser setAssembler:assembler selector:@selector(parser:didMatchPlus:)];
    }
    return phrasePlusParser;
}


// phraseQuestion       = phrase S* '?';
- (PKCollectionParser *)phraseQuestionParser {
    if (!phraseQuestionParser) {
        self.phraseQuestionParser = [PKSequence sequence];
        phraseQuestionParser.name = @"phraseQuestion";
        [phraseQuestionParser add:self.phraseParser];
        [phraseQuestionParser add:self.optionalWhitespaceParser];
        [phraseQuestionParser add:[[PKSymbol symbolWithString:@"?"] discard]];
        [phraseQuestionParser setAssembler:assembler selector:@selector(parser:didMatchQuestion:)];
    }
    return phraseQuestionParser;
}


// phraseCardinality    = phrase S* cardinality;
- (PKCollectionParser *)phraseCardinalityParser {
    if (!phraseCardinalityParser) {
        self.phraseCardinalityParser = [PKSequence sequence];
        phraseCardinalityParser.name = @"phraseCardinality";
        [phraseCardinalityParser add:self.phraseParser];
        [phraseCardinalityParser add:self.optionalWhitespaceParser];
        [phraseCardinalityParser add:self.cardinalityParser];
        [phraseCardinalityParser setAssembler:assembler selector:@selector(parser:didMatchPhraseCardinality:)];
    }
    return phraseCardinalityParser;
}


// cardinality          = '{' S* Number (S* ',' S* Number)? S* '}';
- (PKCollectionParser *)cardinalityParser {
    if (!cardinalityParser) {
        self.cardinalityParser = [PKSequence sequence];
        cardinalityParser.name = @"cardinality";
        
        PKSequence *commaNum = [PKSequence sequence];
        [commaNum add:self.optionalWhitespaceParser];
        [commaNum add:[[PKSymbol symbolWithString:@","] discard]];
        [commaNum add:self.optionalWhitespaceParser];
        [commaNum add:[PKNumber number]];
        
        PKTrack *tr = [PKTrack track];
        [tr add:[PKSymbol symbolWithString:@"{"]]; // serves as fence. dont discard
        [tr add:self.optionalWhitespaceParser];
        [tr add:[PKNumber number]];
        [tr add:[self zeroOrOne:commaNum]];
        [tr add:self.optionalWhitespaceParser];
        [tr add:[[PKSymbol symbolWithString:@"}"] discard]];
        
        [cardinalityParser add:tr];
        [cardinalityParser setAssembler:assembler selector:@selector(parser:didMatchCardinality:)];
    }
    return cardinalityParser;
}


// atomicValue          = parser discard?;
- (PKCollectionParser *)atomicValueParser {
    if (!atomicValueParser) {
        self.atomicValueParser = [PKSequence sequence];
        atomicValueParser.name = @"atomicValue";
        [atomicValueParser add:self.parserParser];
        [atomicValueParser add:[self zeroOrOne:self.discardParser]];
    }
    return atomicValueParser;
}


// parser               = pattern | literal | variable | constant | specificConstant | delimitedString;
- (PKCollectionParser *)parserParser {
    if (!parserParser) {
        self.parserParser = [PKAlternation alternation];
        parserParser.name = @"parser";
        [parserParser add:self.patternParser];
        [parserParser add:self.literalParser];
        [parserParser add:self.variableParser];
        [parserParser add:self.constantParser];
        [parserParser add:self.specificConstantParser];
        [parserParser add:self.delimitedStringParser];
    }
    return parserParser;
}


// discard              = S* '!';
- (PKCollectionParser *)discardParser {
    if (!discardParser) {
        self.discardParser = [PKSequence sequence];
        discardParser.name = @"discard";
        [discardParser add:self.optionalWhitespaceParser];
        [discardParser add:[[PKSymbol symbolWithString:@"!"] discard]];
        [discardParser setAssembler:assembler selector:@selector(parser:didMatchDiscard:)];
    }
    return discardParser;
}


// pattern              = DelimitedString('/', '/') (Word & /[imxsw]+/)?;
- (PKCollectionParser *)patternParser {
    if (!patternParser) {
        patternParser.name = @"pattern";
        self.patternParser = [PKSequence sequence];
        [patternParser add:[PKDelimitedString delimitedStringWithStartMarker:@"/" endMarker:@"/"]];
        
        PKParser *opts = [PKPattern patternWithString:@"[imxsw]+" options:PKPatternOptionsNone];
        PKIntersection *inter = [PKIntersection intersection];
        [inter add:[PKWord word]];
        [inter add:opts];
        [inter setAssembler:assembler selector:@selector(parser:didMatchPatternOptions:)];
        
        [patternParser add:[self zeroOrOne:inter]];
        [patternParser setAssembler:assembler selector:@selector(parser:didMatchPattern:)];
    }
    return patternParser;
}


// delimitedString      = 'DelimitedString' S* '(' S* QuotedString (S* ',' QuotedString)? S* ')';
- (PKCollectionParser *)delimitedStringParser {
    if (!delimitedStringParser) {
        self.delimitedStringParser = [PKTrack track];
        delimitedStringParser.name = @"delimitedString";
        
        PKSequence *secondArg = [PKSequence sequence];
        [secondArg add:self.optionalWhitespaceParser];
        
        PKTrack *tr = [PKTrack track];
        [tr add:[[PKSymbol symbolWithString:@","] discard]];
        [tr add:self.optionalWhitespaceParser];
        [tr add:[PKQuotedString quotedString]]; // endMarker
        [secondArg add:tr];
        
        [delimitedStringParser add:[[PKLiteral literalWithString:@"DelimitedString"] discard]];
        [delimitedStringParser add:self.optionalWhitespaceParser];
        [delimitedStringParser add:[PKSymbol symbolWithString:@"("]]; // preserve as fence
        [delimitedStringParser add:self.optionalWhitespaceParser];
        [delimitedStringParser add:[PKQuotedString quotedString]]; // startMarker
        [delimitedStringParser add:[self zeroOrOne:secondArg]];
        [delimitedStringParser add:self.optionalWhitespaceParser];
        [delimitedStringParser add:[[PKSymbol symbolWithString:@")"] discard]];
        
        [delimitedStringParser setAssembler:assembler selector:@selector(parser:didMatchDelimitedString:)];
    }
    return delimitedStringParser;
}


// literal              = QuotedString;
- (PKParser *)literalParser {
    if (!literalParser) {
        self.literalParser = [PKQuotedString quotedString];
        [literalParser setAssembler:assembler selector:@selector(parser:didMatchLiteral:)];
    }
    return literalParser;
}


// variable             = LowercaseWord;
- (PKParser *)variableParser {
    if (!variableParser) {
        self.variableParser = [PKLowercaseWord word];
        variableParser.name = @"variable";
        [variableParser setAssembler:assembler selector:@selector(parser:didMatchVariable:)];
    }
    return variableParser;
}


// constant             = UppercaseWord;
- (PKParser *)constantParser {
    if (!constantParser) {
        self.constantParser = [PKUppercaseWord word];
        constantParser.name = @"constant";
        [constantParser setAssembler:assembler selector:@selector(parser:didMatchConstant:)];
    }
    return constantParser;
}


// specificConstant      = UppercaseWord '(' QuotedString ')';
- (PKParser *)specificConstantParser {
    if (!specificConstantParser) {
        self.specificConstantParser = [PKSequence sequence];
        specificConstantParser.name = @"specificConstant";
        [specificConstantParser add:[PKUppercaseWord word]];
        [specificConstantParser add:[[PKSymbol symbolWithString:@"("] discard]];
        [specificConstantParser add:[PKQuotedString quotedString]];
        [specificConstantParser add:[[PKSymbol symbolWithString:@")"] discard]];
        [specificConstantParser setAssembler:assembler selector:@selector(parser:didMatchSpecificConstant:)];
    }
    return specificConstantParser;
}


- (PKParser *)whitespaceParser {
    return [[PKWhitespace whitespace] discard];
}


- (PKParser *)optionalWhitespaceParser {
    return [PKRepetition repetitionWithSubparser:self.whitespaceParser];
}

@synthesize parser;
@synthesize statementParser;
@synthesize tokenizerDirectiveParser;
@synthesize declParser;
@synthesize productionParser;
@synthesize varProductionParser;
@synthesize startProductionParser;
@synthesize callbackParser;
@synthesize selectorParser;
@synthesize exprParser;
@synthesize termParser;
@synthesize orTermParser;
@synthesize factorParser;
@synthesize nextFactorParser;
@synthesize phraseParser;
@synthesize phraseStarParser;
@synthesize phrasePlusParser;
@synthesize phraseQuestionParser;
@synthesize phraseCardinalityParser;
@synthesize cardinalityParser;
@synthesize primaryExprParser;
@synthesize negatedPrimaryExprParser;
@synthesize barePrimaryExprParser;
@synthesize predicateParser;
@synthesize intersectionParser;
@synthesize differenceParser;
@synthesize atomicValueParser;
@synthesize parserParser;
@synthesize discardParser;
@synthesize patternParser;
@synthesize delimitedStringParser;
@synthesize literalParser;
@synthesize variableParser;
@synthesize constantParser;
@synthesize specificConstantParser;
@end
