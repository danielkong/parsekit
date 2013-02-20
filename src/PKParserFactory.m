//
//  PKParserFactory.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 12/12/08.
//  Copyright 2009 Todd Ditchendorf All rights reserved.
//

#import "PKParserFactory.h"
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

void PKReleaseSubparserTree(PKParser *p) {
    if ([p isKindOfClass:[PKCollectionParser class]]) {
        PKCollectionParser *c = (PKCollectionParser *)p;
        NSArray *subs = c.subparsers;
        if (subs) {
            [subs retain];
            c.subparsers = nil;
            for (PKParser *s in subs) {
                PKReleaseSubparserTree(s);
            }
            [subs release];
        }
    } else if ([p isMemberOfClass:[PKRepetition class]]) {
        PKRepetition *r = (PKRepetition *)p;
		PKParser *sub = r.subparser;
        if (sub) {
            [sub retain];
            r.subparser = nil;
            PKReleaseSubparserTree(sub);
            [sub release];
        }
    } else if ([p isMemberOfClass:[PKNegation class]]) {
        PKNegation *n = (PKNegation *)p;
		PKParser *sub = n.subparser;
        if (sub) {
            [sub retain];
            n.subparser = nil;
            PKReleaseSubparserTree(sub);
            [sub release];
        }
    } else if ([p isMemberOfClass:[PKDifference class]]) {
        PKDifference *d = (PKDifference *)p;
		PKParser *sub = d.subparser;
        if (sub) {
            [sub retain];
            d.subparser = nil;
            PKReleaseSubparserTree(sub);
            [sub release];
        }
		PKParser *m = d.minus;
        if (m) {
            [m retain];
            d.minus = nil;
            PKReleaseSubparserTree(m);
            [m release];
        }
    }
}

@interface PKParserFactory ()
- (PKTokenizer *)tokenizerForParsingGrammar;
- (BOOL)isAllWhitespace:(NSArray *)toks;
- (id)parserTokensTableFromParsingStatementsInString:(NSString *)s;
- (void)gatherParserClassNamesFromTokens;
- (NSString *)parserClassNameFromTokenArray:(NSArray *)toks;

- (PKTokenizer *)tokenizerFromGrammarSettings;
- (BOOL)boolForTokenForKey:(NSString *)key;
- (void)setTokenizerState:(PKTokenizerState *)state onTokenizer:(PKTokenizer *)t forTokensForKey:(NSString *)key;
- (void)setFallbackStateOn:(PKTokenizerState *)state withTokenizer:(PKTokenizer *)t forTokensForKey:(NSString *)key;

- (id)expandParser:(PKParser *)p fromTokenArray:(NSArray *)toks;
- (PKParser *)expandedParserForName:(NSString *)parserName;
- (void)setAssemblerForParser:(PKParser *)p;
- (NSArray *)tokens:(NSArray *)toks byRemovingTokensOfType:(PKTokenType)tt;
- (NSString *)defaultAssemblerSelectorNameForParserName:(NSString *)parserName;
- (NSString *)defaultPreassemblerSelectorNameForParserName:(NSString *)parserName;

// this is only for unit tests? can it go away?
- (PKSequence *)parserFromExpression:(NSString *)s;

- (PKAlternation *)zeroOrOne:(PKParser *)p;
- (PKSequence *)oneOrMore:(PKParser *)p;

- (void)parser:(PKParser *)p didMatchStatement:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchCallback:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchExpression:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchSeq:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchTrack:(PKAssembly *)a;
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
@property (nonatomic, retain) NSMutableDictionary *parserTokensTable;
@property (nonatomic, retain) NSMutableDictionary *parserClassTable;
@property (nonatomic, retain) NSMutableDictionary *selectorTable;
@property (nonatomic, assign) BOOL wantsCharacters;
@property (nonatomic, retain) PKToken *equals;
@property (nonatomic, retain) PKToken *curly;
@property (nonatomic, retain) PKToken *paren;
@property (nonatomic, retain) PKToken *square;
@end

@implementation PKParserFactory

+ (PKParserFactory *)factory {
    return [[[PKParserFactory alloc] init] autorelease];
}


- (id)init {
    self = [super init];
    if (self) {
        self.grammarParser = [[[PKGrammarParser alloc] initWithAssembler:self] autorelease];
        self.equals  = [PKToken tokenWithTokenType:PKTokenTypeSymbol stringValue:@"=" floatValue:0.0];
        self.curly   = [PKToken tokenWithTokenType:PKTokenTypeSymbol stringValue:@"{" floatValue:0.0];
        self.paren   = [PKToken tokenWithTokenType:PKTokenTypeSymbol stringValue:@"(" floatValue:0.0];
        self.square  = [PKToken tokenWithTokenType:PKTokenTypeSymbol stringValue:@"[" floatValue:0.0];
        self.assemblerSettingBehavior = PKParserFactoryAssemblerSettingBehaviorOnAll;
    }
    return self;
}


- (void)dealloc {
    self.grammarParser = nil;
    self.assembler = nil;
    self.preassembler = nil;
    self.parserTokensTable = nil;
    self.parserClassTable = nil;
    self.selectorTable = nil;
    self.equals = nil;
    self.curly = nil;
    self.paren = nil;
    self.square = nil;
    [super dealloc];
}


- (PKCollectionParser *)exprParser {
    return grammarParser.exprParser;
}


- (PKParser *)parserFromGrammar:(NSString *)g assembler:(id)a error:(NSError **)outError {
    return [self parserFromGrammar:g assembler:a preassembler:nil error:outError];
}


- (PKParser *)parserFromGrammar:(NSString *)g assembler:(id)a preassembler:(id)pa error:(NSError **)outError {
    PKParser *result = nil;

    @try {
        self.assembler = a;
        self.preassembler = pa;
        self.selectorTable = [NSMutableDictionary dictionary];
        self.parserClassTable = [NSMutableDictionary dictionary];
        self.parserTokensTable = [self parserTokensTableFromParsingStatementsInString:g];

        PKTokenizer *t = [self tokenizerFromGrammarSettings];

        [self gatherParserClassNamesFromTokens];
        
        PKParser *start = [self expandedParserForName:@"@start"];
        
        assembler = nil;
        self.selectorTable = nil;
        self.parserClassTable = nil;
        self.parserTokensTable = nil;
        
        if (start && [start isKindOfClass:[PKParser class]]) {
            start.tokenizer = t;
            result = start;
        } else {
            [NSException raise:@"PKGrammarException" format:NSLocalizedString(@"An unknown error occurred while parsing the grammar. The provided language grammar was invalid.", @"")];
        }
        
        return result;

    }
    @catch (NSException *ex) {
        if (outError) {
            NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:[ex userInfo]];

            // get reason
            NSString *reason = [ex reason];
            if ([reason length]) [userInfo setObject:reason forKey:NSLocalizedFailureReasonErrorKey];
            
            // get domain
            NSString *name = [ex name];
            NSString *domain = name ? name : @"PKGrammarException";

            // convert to NSError
            NSError *err = [NSError errorWithDomain:domain code:47 userInfo:[[userInfo copy] autorelease]];
            *outError = err;
        } else {
            [ex raise];
        }
    }
}


- (PKTokenizer *)tokenizerForParsingGrammar {
    PKTokenizer *t = [PKTokenizer tokenizer];
    
    t.whitespaceState.reportsWhitespaceTokens = YES;
    
    // customize tokenizer to find tokenizer customization directives
    [t setTokenizerState:t.wordState from:'@' to:'@'];
    
    // add support for tokenizer directives like @commentState.fallbackState
    [t.wordState setWordChars:YES from:'.' to:'.'];
    [t.wordState setWordChars:NO from:'-' to:'-'];
    
    // setup comments
    [t setTokenizerState:t.commentState from:'/' to:'/'];
    [t.commentState addSingleLineStartMarker:@"//"];
    [t.commentState addMultiLineStartMarker:@"/*" endMarker:@"*/"];
    
    // comment state should fallback to delimit state to match regex delimited strings
    t.commentState.fallbackState = t.delimitState;
    
    // regex delimited strings
    [t.delimitState addStartMarker:@"/" endMarker:@"/" allowedCharacterSet:[[NSCharacterSet whitespaceCharacterSet] invertedSet]];
    
    return t;
}


- (BOOL)isAllWhitespace:(NSArray *)toks {
    for (PKToken *tok in toks) {
        if (PKTokenTypeWhitespace != tok.tokenType) {
            return NO;
        }
    }
    return YES;
}


- (id)parserTokensTableFromParsingStatementsInString:(NSString *)s {
    PKTokenizer *t = [self tokenizerForParsingGrammar];
    t.string = s;
    
    PKTokenArraySource *src = [[PKTokenArraySource alloc] initWithTokenizer:t delimiter:@";"];
    id target = [NSMutableDictionary dictionary]; // setup the variable lookup table
    
    while ([src hasMore]) {
        NSArray *toks = [src nextTokenArray];
        if (![self isAllWhitespace:toks]) {
            PKTokenAssembly *a = [PKTokenAssembly assemblyWithTokenArray:toks];
            //a.preservesWhitespaceTokens = YES;
            a.target = target;
            PKAssembly *res = [grammarParser.statementParser completeMatchFor:a];
            target = res.target;
        }
    }

    [src release];
    
    return target;
}


- (void)gatherParserClassNamesFromTokens {
    isGatheringClasses = YES;
    // discover the actual parser class types
    for (NSString *parserName in parserTokensTable) {
        NSString *className = [self parserClassNameFromTokenArray:[parserTokensTable objectForKey:parserName]];
        NSAssert1([className length], @"Could not build ClassName from token array for parserName: %@", parserName);
        [parserClassTable setObject:className forKey:parserName];
    }
    isGatheringClasses = NO;
}


- (NSString *)parserClassNameFromTokenArray:(NSArray *)toks {
    PKAssembly *a = [PKTokenAssembly assemblyWithTokenArray:toks];
    a.target = parserTokensTable;
    a = [grammarParser.exprParser completeMatchFor:a];
    PKParser *res = [a pop];
    a.target = nil;
    return NSStringFromClass([res class]);
}


- (PKTokenizer *)tokenizerFromGrammarSettings {
    self.wantsCharacters = [self boolForTokenForKey:@"@wantsCharacters"];

    PKTokenizer *t = [PKTokenizer tokenizer];
    [t.commentState removeSingleLineStartMarker:@"//"];
    [t.commentState removeMultiLineStartMarker:@"/*"];

    t.whitespaceState.reportsWhitespaceTokens = [self boolForTokenForKey:@"@reportsWhitespaceTokens"];
    t.commentState.reportsCommentTokens = [self boolForTokenForKey:@"@reportsCommentTokens"];
    t.commentState.balancesEOFTerminatedComments = [self boolForTokenForKey:@"balancesEOFTerminatedComments"];
    t.quoteState.balancesEOFTerminatedQuotes = [self boolForTokenForKey:@"@balancesEOFTerminatedQuotes"];
    t.delimitState.balancesEOFTerminatedStrings = [self boolForTokenForKey:@"@balancesEOFTerminatedStrings"];
    t.numberState.allowsTrailingDecimalSeparator = [self boolForTokenForKey:@"@allowsTrailingDecimalSeparator"];
    t.numberState.allowsScientificNotation = [self boolForTokenForKey:@"@allowsScientificNotation"];
    
    BOOL yn = YES;
    if ([parserTokensTable objectForKey:@"@allowsFloatingPoint"]) {
        yn = [self boolForTokenForKey:@"@allowsFloatingPoint"];
    }
    t.numberState.allowsFloatingPoint = yn;
    
    [self setTokenizerState:t.wordState onTokenizer:t forTokensForKey:@"@wordState"];
    [self setTokenizerState:t.numberState onTokenizer:t forTokensForKey:@"@numberState"];
    [self setTokenizerState:t.quoteState onTokenizer:t forTokensForKey:@"@quoteState"];
    [self setTokenizerState:t.delimitState onTokenizer:t forTokensForKey:@"@delimitState"];
    [self setTokenizerState:t.symbolState onTokenizer:t forTokensForKey:@"@symbolState"];
    [self setTokenizerState:t.commentState onTokenizer:t forTokensForKey:@"@commentState"];
    [self setTokenizerState:t.whitespaceState onTokenizer:t forTokensForKey:@"@whitespaceState"];
    
    [self setFallbackStateOn:t.commentState withTokenizer:t forTokensForKey:@"@commentState.fallbackState"];
    [self setFallbackStateOn:t.delimitState withTokenizer:t forTokensForKey:@"@delimitState.fallbackState"];
    
    NSArray *toks = nil;
    
    // muli-char symbols
    toks = [NSArray arrayWithArray:[parserTokensTable objectForKey:@"@symbol"]];
    toks = [toks arrayByAddingObjectsFromArray:[parserTokensTable objectForKey:@"@symbols"]];
    [parserTokensTable removeObjectForKey:@"@symbol"];
    [parserTokensTable removeObjectForKey:@"@symbols"];
    for (PKToken *tok in toks) {
        if (tok.isQuotedString) {
            [t.symbolState add:[tok.stringValue stringByTrimmingQuotes]];
        }
    }
    
    // wordChars
    toks = [NSArray arrayWithArray:[parserTokensTable objectForKey:@"@wordChar"]];
    toks = [toks arrayByAddingObjectsFromArray:[parserTokensTable objectForKey:@"@wordChars"]];
    [parserTokensTable removeObjectForKey:@"@wordChar"];
    [parserTokensTable removeObjectForKey:@"@wordChars"];
    for (PKToken *tok in toks) {
        if (tok.isQuotedString) {
			NSString *s = [tok.stringValue stringByTrimmingQuotes];
			if ([s length]) {
				PKUniChar c = [s characterAtIndex:0];
				[t.wordState setWordChars:YES from:c to:c];
			}
        }
    }
    
    // whitespaceChars
    toks = [NSArray arrayWithArray:[parserTokensTable objectForKey:@"@whitespaceChar"]];
    toks = [toks arrayByAddingObjectsFromArray:[parserTokensTable objectForKey:@"@whitespaceChars"]];
    [parserTokensTable removeObjectForKey:@"@whitespaceChar"];
    [parserTokensTable removeObjectForKey:@"@whitespaceChars"];
    for (PKToken *tok in toks) {
        if (tok.isQuotedString) {
			NSString *s = [tok.stringValue stringByTrimmingQuotes];
			if ([s length]) {
                PKUniChar c = 0;
                if ([s hasPrefix:@"#x"]) {
                    c = (PKUniChar)[s integerValue];
                } else {
                    c = [s characterAtIndex:0];
                }
                [t.whitespaceState setWhitespaceChars:YES from:c to:c];
			}
        }
    }
    
    // single-line comments
    toks = [NSArray arrayWithArray:[parserTokensTable objectForKey:@"@singleLineComment"]];
    toks = [toks arrayByAddingObjectsFromArray:[parserTokensTable objectForKey:@"@singleLineComments"]];
    [parserTokensTable removeObjectForKey:@"@singleLineComment"];
    [parserTokensTable removeObjectForKey:@"@singleLineComments"];
    for (PKToken *tok in toks) {
        if (tok.isQuotedString) {
            NSString *s = [tok.stringValue stringByTrimmingQuotes];
            [t.commentState addSingleLineStartMarker:s];
        }
    }
    
    // multi-line comments
    toks = [NSArray arrayWithArray:[parserTokensTable objectForKey:@"@multiLineComment"]];
    toks = [toks arrayByAddingObjectsFromArray:[parserTokensTable objectForKey:@"@multiLineComments"]];
    NSAssert(0 == [toks count] % 2, @"@multiLineComments must be specified as quoted strings in multiples of 2");
    [parserTokensTable removeObjectForKey:@"@multiLineComment"];
    [parserTokensTable removeObjectForKey:@"@multiLineComments"];
    if ([toks count] > 1) {
        for (NSInteger i = 0; i < [toks count] - 1; i++) {
            PKToken *startTok = [toks objectAtIndex:i];
            PKToken *endTok = [toks objectAtIndex:++i];
            if (startTok.isQuotedString && endTok.isQuotedString) {
                NSString *start = [startTok.stringValue stringByTrimmingQuotes];
                NSString *end = [endTok.stringValue stringByTrimmingQuotes];
                [t.commentState addMultiLineStartMarker:start endMarker:end];
            }
        }
    }
    
    // number state prefixes
    toks = [NSArray arrayWithArray:[parserTokensTable objectForKey:@"@numberPrefixForRadix"]];
    NSAssert(0 == [toks count] % 2, @"@numberPrefixForRadix must be specified as quoted strings in multiples of 2");
    [parserTokensTable removeObjectForKey:@"@numberPrefixForRadix"];
    if ([toks count] > 1) {
        for (NSInteger i = 0; i < [toks count] - 1; i++) {
            PKToken *prefixTok = [toks objectAtIndex:i];
            PKToken *radixTok = [toks objectAtIndex:++i];
            if (prefixTok.isQuotedString && radixTok.isNumber) {
                NSString *prefix = [prefixTok.stringValue stringByTrimmingQuotes];
                PKFloat radix = radixTok.floatValue;
                [t.numberState addPrefix:prefix forRadix:radix];
            }
        }
    }
    
    // number state suffix
    toks = [NSArray arrayWithArray:[parserTokensTable objectForKey:@"@numberSuffixForRadix"]];
    NSAssert(0 == [toks count] % 2, @"@numberSuffixForRadix must be specified as quoted strings in multiples of 2");
    [parserTokensTable removeObjectForKey:@"@numberSuffixForRadix"];
    if ([toks count] > 1) {
        for (NSInteger i = 0; i < [toks count] - 1; i++) {
            PKToken *suffixTok = [toks objectAtIndex:i];
            PKToken *radixTok = [toks objectAtIndex:++i];
            if (suffixTok.isQuotedString && radixTok.isNumber) {
                NSString *suffix = [suffixTok.stringValue stringByTrimmingQuotes];
                PKFloat radix = radixTok.floatValue;
                if (radix > 0.0) {
                    [t.numberState addSuffix:suffix forRadix:radix];
                }
            }
        }
    }
    
    // number grouping separator
    toks = [NSArray arrayWithArray:[parserTokensTable objectForKey:@"@numberGroupingSeparatorForRadix"]];
    NSAssert(0 == [toks count] % 2, @"@numberGroupingSeparatorForRadix must be specified as quoted strings in multiples of 2");
    [parserTokensTable removeObjectForKey:@"@numberGroupingSeparatorForRadix"];
    if ([toks count] > 1) {
        for (NSInteger i = 0; i < [toks count] - 1; i++) {
            PKToken *sepTok = [toks objectAtIndex:i];
            PKToken *radixTok = [toks objectAtIndex:++i];
            if (sepTok.isQuotedString && radixTok.isNumber) {
                NSString *sepStr = [sepTok.stringValue stringByTrimmingQuotes];
                if (1 == [sepStr length]) {
                    PKFloat radix = radixTok.floatValue;
                    if (radix > 0.0) {
                        PKUniChar c = [sepStr characterAtIndex:0];
                        [t.numberState addGroupingSeparator:c forRadix:radix];
                    }
                }
            }
        }
    }

    // delimited strings
    toks = [NSArray arrayWithArray:[parserTokensTable objectForKey:@"@delimitedString"]];
    toks = [toks arrayByAddingObjectsFromArray:[parserTokensTable objectForKey:@"@delimitedStrings"]];
    NSAssert(0 == [toks count] % 3, @"@delimitedString must be specified as quoted strings in multiples of 3");
    [parserTokensTable removeObjectForKey:@"@delimitedString"];
    [parserTokensTable removeObjectForKey:@"@delimitedStrings"];
    if ([toks count] > 1) {
        for (NSInteger i = 0; i < [toks count] - 2; i++) {
            PKToken *startTok = [toks objectAtIndex:i];
            PKToken *endTok = [toks objectAtIndex:++i];
            PKToken *charSetTok = [toks objectAtIndex:++i];
            if (startTok.isQuotedString && endTok.isQuotedString) {
                NSString *start = [startTok.stringValue stringByTrimmingQuotes];
                NSString *end = [endTok.stringValue stringByTrimmingQuotes];
                NSCharacterSet *charSet = nil;
                if (charSetTok.isQuotedString) {
                    charSet = [NSCharacterSet characterSetWithCharactersInString:[charSetTok.stringValue stringByTrimmingQuotes]];
                }
                [t.delimitState addStartMarker:start endMarker:end allowedCharacterSet:charSet];
            }
        }
    }
    
    return t;
}


- (BOOL)boolForTokenForKey:(NSString *)key {
    BOOL result = NO;
    NSArray *toks = [parserTokensTable objectForKey:key];
    if ([toks count]) {
        PKToken *tok = [toks objectAtIndex:0];
        if (tok.isWord && [tok.stringValue isEqualToString:@"YES"]) {
            result = YES;
        }
    }
    [parserTokensTable removeObjectForKey:key];
    return result;
}


- (void)setTokenizerState:(PKTokenizerState *)state onTokenizer:(PKTokenizer *)t forTokensForKey:(NSString *)key {
    NSArray *toks = [parserTokensTable objectForKey:key];
    for (PKToken *tok in toks) {
        if (tok.isQuotedString) {
            NSString *s = [tok.stringValue stringByTrimmingQuotes];
            if (1 == [s length]) {
                PKUniChar c = [s characterAtIndex:0];
                [t setTokenizerState:state from:c to:c];
            }
        }
    }
    [parserTokensTable removeObjectForKey:key];
}


- (void)setFallbackStateOn:(PKTokenizerState *)state withTokenizer:(PKTokenizer *)t forTokensForKey:(NSString *)key {
    NSArray *toks = [parserTokensTable objectForKey:key];
    if ([toks count]) {
        PKToken *tok = [toks objectAtIndex:0];
        if (tok.isWord) {
            PKTokenizerState *fallbackState = [t valueForKey:tok.stringValue];
            if (state != fallbackState) {
                state.fallbackState = fallbackState;
            }
        }
    }
    [parserTokensTable removeObjectForKey:key];
}


- (PKParser *)expandedParserForName:(NSString *)parserName {
    id obj = [parserTokensTable objectForKey:parserName];
    if ([obj isKindOfClass:[PKParser class]]) {
        return obj;
    } else {
        // prevent infinite loops by creating a parser of the correct type first, and putting it in the table
        NSString *className = [parserClassTable objectForKey:parserName];

        PKParser *p = [[NSClassFromString(className) alloc] init];
        [parserTokensTable setObject:p forKey:parserName];
        [p release];
        
        p = [self expandParser:p fromTokenArray:obj];
        p.name = parserName;

        [self setAssemblerForParser:p];

        [parserTokensTable setObject:p forKey:parserName];
        return p;
    }
}


- (void)setAssemblerForParser:(PKParser *)p {
    NSString *parserName = p.name;
    NSString *selName = [selectorTable objectForKey:parserName];

    BOOL setOnAll = (assemblerSettingBehavior & PKParserFactoryAssemblerSettingBehaviorOnAll);

    if (setOnAll) {
        // continue
    } else {
        BOOL setOnExplicit = (assemblerSettingBehavior & PKParserFactoryAssemblerSettingBehaviorOnExplicit);
        if (setOnExplicit && selName) {
            // continue
        } else {
            BOOL isTerminal = [p isKindOfClass:[PKTerminal class]];
            if (!isTerminal && !setOnExplicit) return;
            
            BOOL setOnTerminals = (assemblerSettingBehavior & PKParserFactoryAssemblerSettingBehaviorOnTerminals);
            if (setOnTerminals && isTerminal) {
                // continue
            } else {
                return;
            }
        }
    }
    
    if (!selName) {
        selName = [self defaultAssemblerSelectorNameForParserName:parserName];
    }
    
    if (selName) {
        SEL sel = NSSelectorFromString(selName);
        if (assembler && [assembler respondsToSelector:sel]) {
            [p setAssembler:assembler selector:sel];
        }
        if (preassembler && [preassembler respondsToSelector:sel]) {
            NSString *selName = [self defaultPreassemblerSelectorNameForParserName:parserName];
            [p setPreassembler:preassembler selector:NSSelectorFromString(selName)];
        }
    }
}


- (id)expandParser:(PKParser *)p fromTokenArray:(NSArray *)toks {	
    PKAssembly *a = [PKTokenAssembly assemblyWithTokenArray:toks];
    a.target = parserTokensTable;
    a = [grammarParser.exprParser completeMatchFor:a];
    PKParser *res = [a pop];
    if ([p isKindOfClass:[PKCollectionParser class]]) {
        PKCollectionParser *cp = (PKCollectionParser *)p;
        [cp add:res];
        return cp;
    } else {
        return res;
    }
}


// this is just a utility for unit-testing
- (PKSequence *)parserFromExpression:(NSString *)s {
    PKTokenizer *t = [self tokenizerForParsingGrammar];
    t.string = s;
    PKAssembly *a = [PKTokenAssembly assemblyWithTokenizer:t];
    a.target = [NSMutableDictionary dictionary]; // setup the variable lookup table
    a = [grammarParser.exprParser completeMatchFor:a];
    return [a pop];
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


- (void)parser:(PKParser *)p didMatchStatement:(PKAssembly *)a {
    NSArray *toks = [[a objectsAbove:equals] reversedArray];
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
        [selectorTable setObject:selName forKey:parserName];
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
    NSArray *objs = [a objectsAbove:paren];
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
        opts = [obj integerValue];
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
    if (self.wantsCharacters) {
        t = [PKSpecificChar specificCharWithChar:[s characterAtIndex:0]];
    } else {
        t = [PKCaseInsensitiveLiteral literalWithString:s];
    }

    [a push:t];
}


- (void)parser:(PKParser *)p didMatchVariable:(PKAssembly *)a {
    PKToken *tok = [a pop];
    NSString *parserName = tok.stringValue;
    
    p = nil;
    if (isGatheringClasses) {
        // lookup the actual possible parser. 
        // if its not there, or still a token array, just spoof it with a sequence
		NSMutableDictionary *d = a.target;
        p = [d objectForKey:parserName];
        if (![p isKindOfClass:[PKParser class]]) {
            p = [PKSequence sequence];
        }
    } else {
        if ([parserTokensTable objectForKey:parserName]) {
            p = [self expandedParserForName:parserName];
        }
    }
    [a push:p];
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
    NSArray *toks = [a objectsAbove:paren];
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
    
    if (self.wantsCharacters) {
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
    
    for (NSInteger i = start ; i < end; i++) {
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


- (void)parser:(PKParser *)p didMatchTrack:(PKAssembly *)a {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, a);

    NSAssert(square, @"");
    NSArray *parsers = [a objectsAbove:square];
    
    [a pop]; // discard '['
    
    if ([parsers count] > 1) {
        PKSequence *seq = [PKTrack track];
        for (PKParser *p in [parsers reverseObjectEnumerator]) {
            [seq add:p];
        }
        
        [a push:seq];
    } else if (1 == [parsers count]) {
        [a push:[parsers objectAtIndex:0]];
    }
}


- (void)parser:(PKParser *)p didMatchSeq:(PKAssembly *)a {
    //NSLog(@"%s %@", __PRETTY_FUNCTION__, a);

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

@synthesize grammarParser;
@synthesize assembler;
@synthesize preassembler;
@synthesize parserTokensTable;
@synthesize parserClassTable;
@synthesize selectorTable;
@synthesize wantsCharacters;
@synthesize equals;
@synthesize curly;
@synthesize paren;
@synthesize square;
@synthesize assemblerSettingBehavior;
@end
