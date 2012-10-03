//
//  TDParserFactory.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/3/12.
//
//

#import "TDParserFactory.h"
#import <ParseKit/ParseKit.h>
#import "PKGrammarParser.h"
#import "NSString+ParseKitAdditions.h"
#import "NSArray+ParseKitAdditions.h"

#define USE_TRACK 0

@interface PKParser (PKParserFactoryAdditionsFriend)
- (void)setTokenizer:(PKTokenizer *)t;
@end

@interface PKCollectionParser ()
@property (nonatomic, readwrite, retain) NSMutableArray *subparsers;
@end

@interface PKRepetition ()
@property (nonatomic, readwrite, retain) PKParser *subparser;
@end

@interface PKNegation ()
@property (nonatomic, readwrite, retain) PKParser *subparser;
@end

@interface PKDifference ()
@property (nonatomic, readwrite, retain) PKParser *subparser;
@property (nonatomic, readwrite, retain) PKParser *minus;
@end

@interface PKPattern ()
@property (nonatomic, assign) PKTokenType tokenType;
@end

@interface TDParserFactory ()
- (void)parser:(PKParser *)p didMatchStatement:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchCallback:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchExpression:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchAnd:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchIntersection:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchDifference:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchPatternOptions:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchPattern:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchDiscard:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchLiteral:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchVariable:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchConstant:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchDelimitedString:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchNum:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchStar:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchPlus:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchQuestion:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchPhraseCardinality:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchCardinality:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchOr:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchNegation:(PKAssembly *)a;

@property (nonatomic, retain) PKGrammarParser *grammarParser;
@property (nonatomic, assign) id assembler;
@property (nonatomic, assign) id preassembler;
@property (nonatomic, assign) BOOL wantsCharacters;
@property (nonatomic, retain) PKToken *equals;
@property (nonatomic, retain) PKToken *curly;
@property (nonatomic, retain) PKToken *paren;
@end

@implementation TDParserFactory {

}

+ (PKParserFactory *)factory {
    return [[[PKParserFactory alloc] init] autorelease];
}


- (id)init {
    self = [super init];
    if (self) {
        self.grammarParser = [[[PKGrammarParser alloc] initWithAssembler:self] autorelease];
        self.equals = [PKToken tokenWithTokenType:PKTokenTypeSymbol stringValue:@"=" floatValue:0.0];
        self.curly  = [PKToken tokenWithTokenType:PKTokenTypeSymbol stringValue:@"{" floatValue:0.0];
        self.paren  = [PKToken tokenWithTokenType:PKTokenTypeSymbol stringValue:@"(" floatValue:0.0];        
    }
    return self;
}


- (void)dealloc {
    self.grammarParser = nil;
    self.assembler = nil;
    self.preassembler = nil;
    self.equals = nil;
    self.curly = nil;
    self.paren = nil;
    [super dealloc];
}


#pragma mark -
#pragma mark Public

- (PKParser *)parserFromGrammar:(NSString *)g assembler:(id)a error:(NSError **)outError {
    return [self parserFromGrammar:g assembler:a preassembler:nil error:outError];
}


- (PKParser *)parserFromGrammar:(NSString *)g assembler:(id)a preassembler:(id)pa error:(NSError **)outError {
    
    
    return nil;
}


#pragma mark -
#pragma mark Utility

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


#pragma mark -
#pragma mark Assembler Callbacks

- (void)parser:(PKParser *)p didMatchStatement:(PKAssembly *)a {
    NSArray *toks = [[a objectsAbove:_equals] reversedArray];
    [a pop]; // discard '=' tok
    
    NSString *parserName = nil;
    NSString *selName = nil;
    id obj = [a pop];
    if ([obj isKindOfClass:[NSString class]]) { // a callback was provided
        selName = obj;
        parserName = [[a pop] stringValue];
    } else {
        parserName = [obj stringValue];
    }
    
    if (selName) {
        NSAssert([selName length], @"");
        //        [selectorTable setObject:selName forKey:parserName];
    }
	NSMutableDictionary *d = a.target;
    //NSLog(@"parserName: %@", parserName);
    NSAssert([toks count], @"");
    
    // support for multiple @delimitedString = ... tokenizer directives
    if ([parserName hasPrefix:@"@"]) {
        // remove whitespace toks from tokenizer directives
        if (![parserName isEqualToString:@"@start"]) {
            toks = [self tokens:toks byRemovingTokensOfType:PKTokenTypeWhitespace];
        }
        
        NSArray *existingToks = [d objectForKey:parserName];
        if ([existingToks count]) {
            toks = [toks arrayByAddingObjectsFromArray:existingToks];
        }
    }
    
    [d setObject:toks forKey:parserName];
}


- (NSArray *)tokens:(NSArray *)toks byRemovingTokensOfType:(PKTokenType)tt {
    NSMutableArray *res = [NSMutableArray array];
    for (PKToken *tok in toks) {
        if (PKTokenTypeWhitespace != tok.tokenType) {
            [res addObject:tok];
        }
    }
    return res;
}


- (NSString *)defaultAssemblerSelectorNameForParserName:(NSString *)parserName {
    NSString *prefix = nil;
    if ([parserName hasPrefix:@"@"]) {
        //        parserName = [parserName substringFromIndex:1];
        //        prefix = @"parser:didMatch_";
        return nil;
    } else {
        prefix = @"parser:didMatch";
    }
    NSString *s = [NSString stringWithFormat:@"%@%@", [[parserName substringToIndex:1] uppercaseString], [parserName substringFromIndex:1]];
    return [NSString stringWithFormat:@"%@%@:", prefix, s];
}


- (NSString *)defaultPreassemblerSelectorNameForParserName:(NSString *)parserName {
    NSString *prefix = nil;
    if ([parserName hasPrefix:@"@"]) {
        return nil;
    } else {
        prefix = @"parser:willMatch";
    }
    NSString *s = [NSString stringWithFormat:@"%@%@", [[parserName substringToIndex:1] uppercaseString], [parserName substringFromIndex:1]];
    return [NSString stringWithFormat:@"%@%@:", prefix, s];
}


- (void)parser:(PKParser *)p didMatchCallback:(PKAssembly *)a {
    PKToken *selNameTok2 = [a pop];
    PKToken *selNameTok1 = [a pop];
    NSString *selName = [NSString stringWithFormat:@"%@:%@:", selNameTok1.stringValue, selNameTok2.stringValue];
    [a push:selName];
}


- (void)parser:(PKParser *)p didMatchExpression:(PKAssembly *)a {
    NSArray *objs = [a objectsAbove:_paren];
    NSAssert([objs count], @"");
    [a pop]; // pop '('
    
    if ([objs count] > 1) {
        PKSequence *seq = nil;
#if USE_TRACK
        seq = [PKTrack track];
#else
        seq = [PKSequence sequence];
#endif
        for (id obj in [objs reverseObjectEnumerator]) {
            [seq add:obj];
        }
        [a push:seq];
    } else if ([objs count]) {
        [a push:[objs objectAtIndex:0]];
    }
}


- (void)parser:(PKParser *)p didMatchDifference:(PKAssembly *)a {
    PKParser *minus = [a pop];
    PKParser *sub = [a pop];
    NSAssert([minus isKindOfClass:[PKParser class]], @"");
    NSAssert([sub isKindOfClass:[PKParser class]], @"");
    
    [a push:[PKDifference differenceWithSubparser:sub minus:minus]];
}


- (void)parser:(PKParser *)p didMatchIntersection:(PKAssembly *)a {
    PKParser *predicate = [a pop];
    PKParser *sub = [a pop];
    NSAssert([predicate isKindOfClass:[PKParser class]], @"");
    NSAssert([sub isKindOfClass:[PKParser class]], @"");
    
    PKIntersection *inter = [PKIntersection intersection];
    [inter add:sub];
    [inter add:predicate];
    
    [a push:inter];
}


- (void)parser:(PKParser *)p didMatchPatternOptions:(PKAssembly *)a {
    PKToken *tok = [a pop];
    NSAssert(tok.isWord, @"");
    
    NSString *s = tok.stringValue;
    NSAssert([s length] > 0, @"");
    
    PKPatternOptions opts = PKPatternOptionsNone;
    if (NSNotFound != [s rangeOfString:@"i"].location) {
        opts |= PKPatternOptionsIgnoreCase;
    }
    if (NSNotFound != [s rangeOfString:@"m"].location) {
        opts |= PKPatternOptionsMultiline;
    }
    if (NSNotFound != [s rangeOfString:@"x"].location) {
        opts |= PKPatternOptionsComments;
    }
    if (NSNotFound != [s rangeOfString:@"s"].location) {
        opts |= PKPatternOptionsDotAll;
    }
    if (NSNotFound != [s rangeOfString:@"w"].location) {
        opts |= PKPatternOptionsUnicodeWordBoundaries;
    }
    
    [a push:[NSNumber numberWithInteger:opts]];
}


- (void)parser:(PKParser *)p didMatchPattern:(PKAssembly *)a {
    id obj = [a pop]; // opts (as Number*) or DelimitedString('/', '/')
    
    PKPatternOptions opts = PKPatternOptionsNone;
    if ([obj isKindOfClass:[NSNumber class]]) {
        opts = [obj unsignedIntValue];
        obj = [a pop];
    }
    
    NSAssert([obj isMemberOfClass:[PKToken class]], @"");
    PKToken *tok = (PKToken *)obj;
    NSAssert(tok.isDelimitedString, @"");
    
    NSString *s = tok.stringValue;
    NSAssert([s length] > 2, @"");
    
    NSAssert([s hasPrefix:@"/"], @"");
    NSAssert([s hasSuffix:@"/"], @"");
    
    NSString *re = [s stringByTrimmingQuotes];
    
    PKTerminal *t = [PKPattern patternWithString:re options:opts];
    
    [a push:t];
}


- (void)parser:(PKParser *)p didMatchDiscard:(PKAssembly *)a {
    id obj = [a pop];
    if ([obj isKindOfClass:[PKTerminal class]]) {
        PKTerminal *t = (PKTerminal *)obj;
        [t discard];
    }
    [a push:obj];
}


- (void)parser:(PKParser *)p didMatchLiteral:(PKAssembly *)a {
    PKToken *tok = [a pop];
    
    NSString *s = [tok.stringValue stringByTrimmingQuotes];
    PKTerminal *t = nil;
    
    NSAssert([s length], @"");
    if (_wantsCharacters) {
        t = [PKSpecificChar specificCharWithChar:[s characterAtIndex:0]];
    } else {
        t = [PKCaseInsensitiveLiteral literalWithString:s];
    }
    
    [a push:t];
}


- (void)parser:(PKParser *)p didMatchVariable:(PKAssembly *)a {
//    PKToken *tok = [a pop];
//    NSString *parserName = tok.stringValue;
//    
//    p = nil;
//    if (isGatheringClasses) {
//        // lookup the actual possible parser.
//        // if its not there, or still a token array, just spoof it with a sequence
//		NSMutableDictionary *d = a.target;
//        p = [d objectForKey:parserName];
//        if (![p isKindOfClass:[PKParser class]]) {
//            p = [PKSequence sequence];
//        }
//    } else {
//        if ([parserTokensTable objectForKey:parserName]) {
//            p = [self expandedParserForName:parserName];
//        }
//    }
//    [a push:p];
}


- (void)parser:(PKParser *)p didMatchConstant:(PKAssembly *)a {
    PKToken *tok = [a pop];
    NSString *s = tok.stringValue;
    
    id obj = nil;
    if ([s isEqualToString:@"Word"]) {
        obj = [PKWord word];
    } else if ([s isEqualToString:@"LowercaseWord"]) {
        obj = [PKLowercaseWord word];
    } else if ([s isEqualToString:@"UppercaseWord"]) {
        obj = [PKUppercaseWord word];
    } else if ([s isEqualToString:@"Number"]) {
        obj = [PKNumber number];
    } else if ([s isEqualToString:@"S"]) {
        obj = [PKWhitespace whitespace];
    } else if ([s isEqualToString:@"QuotedString"]) {
        obj = [PKQuotedString quotedString];
    } else if ([s isEqualToString:@"Symbol"]) {
        obj = [PKSymbol symbol];
    } else if ([s isEqualToString:@"Comment"]) {
        obj = [PKComment comment];
    } else if ([s isEqualToString:@"Any"]) {
        obj = [PKAny any];
    } else if ([s isEqualToString:@"Empty"]) {
        obj = [PKEmpty empty];
    } else if ([s isEqualToString:@"Char"]) {
        obj = [PKChar char];
    } else if ([s isEqualToString:@"Letter"]) {
        obj = [PKLetter letter];
    } else if ([s isEqualToString:@"Digit"]) {
        obj = [PKDigit digit];
    } else if ([s isEqualToString:@"Pattern"]) {
        obj = tok;
    } else if ([s isEqualToString:@"DelimitedString"]) {
        obj = tok;
    } else if ([s isEqualToString:@"YES"] || [s isEqualToString:@"NO"]) {
        obj = tok;
    } else {
        [NSException raise:@"Grammar Exception" format:
         @"User Grammar referenced a constant parser name (uppercase word) which is not supported: %@. Must be one of: Word, LowercaseWord, UppercaseWord, QuotedString, Number, Symbol, Empty.", s];
    }
    
    [a push:obj];
}


- (void)parser:(PKParser *)p didMatchDelimitedString:(PKAssembly *)a {
    NSArray *toks = [a objectsAbove:_paren];
    [a pop]; // discard '(' fence
    
    NSAssert([toks count] > 0 && [toks count] < 3, @"");
    NSString *start = [[[toks lastObject] stringValue] stringByTrimmingQuotes];
    NSString *end = nil;
    if ([toks count] > 1) {
        end = [[[toks objectAtIndex:0] stringValue] stringByTrimmingQuotes];
    }
    
    PKTerminal *t = [PKDelimitedString delimitedStringWithStartMarker:start endMarker:end];
    
    [a push:t];
}


- (void)parser:(PKParser *)p didMatchNum:(PKAssembly *)a {
    PKToken *tok = [a pop];
    
    if (_wantsCharacters) {
        PKUniChar c = [tok.stringValue characterAtIndex:0];
        [a push:[PKSpecificChar specificCharWithChar:c]];
    } else {
        [a push:[NSNumber numberWithFloat:tok.floatValue]];
    }
}


- (void)parser:(PKParser *)p didMatchStar:(PKAssembly *)a {
    id top = [a pop];
    PKRepetition *rep = [PKRepetition repetitionWithSubparser:top];
    [a push:rep];
}


- (void)parser:(PKParser *)p didMatchPlus:(PKAssembly *)a {
    id top = [a pop];
    [a push:[self oneOrMore:top]];
}


- (void)parser:(PKParser *)p didMatchQuestion:(PKAssembly *)a {
    id top = [a pop];
    [a push:[self zeroOrOne:top]];
}


- (void)parser:(PKParser *)p didMatchPhraseCardinality:(PKAssembly *)a {
    NSRange r = [[a pop] rangeValue];
    
    p = [a pop];
    PKSequence *s = [PKSequence sequence];
    
    NSInteger start = r.location;
    NSInteger end = r.length;
    
    for (NSInteger i = 0; i < start; i++) {
        [s add:p];
    }
    
    for (NSInteger i = 0; i < end; i++) {
        [s add:[self zeroOrOne:p]];
    }
    
    [a push:s];
}


- (void)parser:(PKParser *)p didMatchCardinality:(PKAssembly *)a {
    NSArray *toks = [a objectsAbove:self.curly];
    [a pop]; // discard '{' tok
    
    NSAssert([toks count] > 0, @"");
    
    PKToken *tok = [toks lastObject];
    PKFloat start = tok.floatValue;
    PKFloat end = start;
    if ([toks count] > 1) {
        tok = [toks objectAtIndex:0];
        end = tok.floatValue;
    }
    
    NSAssert(start <= end, @"");
    
    NSRange r = NSMakeRange(start, end);
    [a push:[NSValue valueWithRange:r]];
}


- (void)parser:(PKParser *)p didMatchOr:(PKAssembly *)a {
    id second = [a pop];
    [a pop]; // pop '|'
    id first = [a pop];
    
    PKAlternation *alt = [PKAlternation alternation];
    [alt add:first];
    [alt add:second];
    [a push:alt];
}


- (void)parser:(PKParser *)p didMatchAnd:(PKAssembly *)a {
    NSMutableArray *parsers = [NSMutableArray array];
    while (![a isStackEmpty]) {
        id obj = [a pop];
        if ([obj isKindOfClass:[PKParser class]]) {
            [parsers addObject:obj];
        } else {
            [a push:obj];
            break;
        }
    }
    
    if ([parsers count] > 1) {
        PKSequence *seq = nil;
#if USE_TRACK
        seq = [PKTrack track];
#else
        seq = [PKSequence sequence];
#endif
        for (PKParser *p in [parsers reverseObjectEnumerator]) {
            [seq add:p];
        }
        
        [a push:seq];
    } else if (1 == [parsers count]) {
        [a push:[parsers objectAtIndex:0]];
    }
}


- (void)parser:(PKParser *)p didMatchNegation:(PKAssembly *)a {
    p = [a pop];
    [a push:[PKNegation negationWithSubparser:p]];
}

@end
