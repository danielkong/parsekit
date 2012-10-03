//
//  TDParserFactory.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/3/12.
//
//

#import "TDParserFactory.h"
#import <ParseKit/ParseKit.h>
#import "TDGrammarParser.h"
#import "NSString+ParseKitAdditions.h"
#import "NSArray+ParseKitAdditions.h"

#import "PKParseTree.h"
#import "PKRuleNode.h"
#import "PKTokenNode.h"

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
- (PKParseTree *)syntaxTreeFromParsingStatementsInString:(NSString *)s;
- (BOOL)isAllWhitespace:(NSArray *)toks;
- (PKTokenizer *)tokenizerForParsingGrammar;

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

@property (nonatomic, retain) TDGrammarParser *grammarParser;
@property (nonatomic, assign) id assembler;
@property (nonatomic, assign) id preassembler;
@property (nonatomic, assign) BOOL wantsCharacters;
@property (nonatomic, retain) PKToken *equals;
@property (nonatomic, retain) PKToken *curly;
@property (nonatomic, retain) PKToken *paren;

@property (nonatomic, retain) PKToken *altToken;
@property (nonatomic, retain) PKToken *wordToken;
@property (nonatomic, retain) PKToken *numberToken;

@property (nonatomic, retain) NSMutableDictionary *productionTab;
@property (nonatomic, retain) NSMutableDictionary *callbackTab;
@end

@implementation TDParserFactory {

}

+ (TDParserFactory *)factory {
    return [[[TDParserFactory alloc] init] autorelease];
}


- (id)init {
    self = [super init];
    if (self) {
        self.grammarParser = [[[TDGrammarParser alloc] initWithAssembler:self] autorelease];
        self.equals = [PKToken tokenWithTokenType:PKTokenTypeSymbol stringValue:@"=" floatValue:0.0];
        self.curly = [PKToken tokenWithTokenType:PKTokenTypeSymbol stringValue:@"{" floatValue:0.0];
        self.paren = [PKToken tokenWithTokenType:PKTokenTypeSymbol stringValue:@"(" floatValue:0.0];

        self.altToken = [PKToken tokenWithTokenType:PKTokenTypeAny stringValue:@"|" floatValue:0.0];
        self.wordToken = [PKToken tokenWithTokenType:PKTokenTypeAny stringValue:@"Word" floatValue:0.0];
        self.numberToken = [PKToken tokenWithTokenType:PKTokenTypeAny stringValue:@"Num" floatValue:0.0];
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
    
    self.altToken = nil;
    self.wordToken = nil;
    self.numberToken = nil;
    
    self.productionTab = nil;
    self.callbackTab = nil;
    [super dealloc];
}


#pragma mark -
#pragma mark Public

- (PKParser *)parserFromGrammar:(NSString *)g assembler:(id)a error:(NSError **)outError {
    return [self parserFromGrammar:g assembler:a preassembler:nil error:outError];
}


- (PKParser *)parserFromGrammar:(NSString *)g assembler:(id)a preassembler:(id)pa error:(NSError **)outError {
    PKParser *result = nil;
    
    @try {
        self.assembler = a;
        self.preassembler = pa;
        
        self.callbackTab = [NSMutableDictionary dictionary];
        self.productionTab = nil;
        
        PKParseTree *rootNode = [self syntaxTreeFromParsingStatementsInString:g];
        
        NSLog(@"%@", rootNode);

//        self.parserClassTable = [NSMutableDictionary dictionary];
//        self.parserTokensTable = [self parserTokensTableFromParsingStatementsInString:g];
//        
//        PKTokenizer *t = [self tokenizerFromGrammarSettings];
//        
//        [self gatherParserClassNamesFromTokens];
//        
//        PKParser *start = [self expandedParserForName:@"@start"];
//        
//        assembler = nil;
//        self.selectorTable = nil;
//        self.parserClassTable = nil;
//        self.parserTokensTable = nil;
//        
//        if (start && [start isKindOfClass:[PKParser class]]) {
//            start.tokenizer = t;
//            result = start;
//        } else {
//            [NSException raise:@"PKGrammarException" format:NSLocalizedString(@"An unknown error occurred while parsing the grammar. The provided language grammar was invalid.", @"")];
//        }
        
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


#pragma mark -
#pragma mark Private

- (PKParseTree *)syntaxTreeFromParsingStatementsInString:(NSString *)s {
    PKTokenizer *t = [self tokenizerForParsingGrammar];
    t.string = s;
    
    PKTokenArraySource *src = [[[PKTokenArraySource alloc] initWithTokenizer:t delimiter:@";"] autorelease];
//    id target = [NSMutableDictionary dictionary]; // setup the variable lookup table
    
    while ([src hasMore]) {
        NSArray *toks = [src nextTokenArray];
        NSLog(@"%@", toks);
        if (![self isAllWhitespace:toks]) {
            PKTokenAssembly *a = [PKTokenAssembly assemblyWithTokenArray:toks];
            NSLog(@"%@", a);
            //a.preservesWhitespaceTokens = YES;
            a.target = [NSMutableDictionary dictionary];
            PKAssembly *res = [_grammarParser.statementParser completeMatchFor:a];
            NSLog(@"res: %@", res);
            id target = res.target;
            NSLog(@"target: %@", target);
            
        }
    }
    

    PKParseTree *rootNode = nil;
    return rootNode;
    //    return target;
}


- (BOOL)isAllWhitespace:(NSArray *)toks {
    for (PKToken *tok in toks) {
        if (PKTokenTypeWhitespace != tok.tokenType) {
            return NO;
        }
    }
    return YES;
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


#pragma mark -
#pragma mark Assembler Helpers

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

- (void)parser:(PKParser *)p didMatchDeclaration:(PKAssembly *)a {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, a);
    
    PKToken *tok = [a pop];
    NSString *prodName = tok.stringValue;
    
    //    PKParseTree *parent = a.target;
    PKParseTree *prodNode = [PKRuleNode ruleNodeWithName:prodName];
    
    NSAssert([a isStackEmpty], @"");
    [a push:prodNode];
    NSLog(@"%@", a);
}


- (void)parser:(PKParser *)p didMatchVariable:(PKAssembly *)a {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, a);

    PKToken *tok = [a pop];
    NSString *prodName = tok.stringValue;
    
    PKParseTree *parent = [a pop];
    NSAssert([parent isKindOfClass:[PKParseTree class]], @"");

    [parent addChildRule:prodName];
    [a push:parent];
    NSLog(@"%@", a);
}


- (void)parser:(PKParser *)p didMatchConstant:(PKAssembly *)a {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, a);

    PKToken *tok = [a pop];

    PKParseTree *parent = [a pop];
    NSAssert([parent isKindOfClass:[PKParseTree class]], @"");
    
    [parent addChildToken:tok];
    [a push:parent];
    NSLog(@"%@", a);

}


- (void)parser:(PKParser *)p didMatchOr:(PKAssembly *)a {
    PKParseTree *first = [a pop];
    PKToken *tok = [a pop]; // pop '|'
    PKParseTree *second = [a pop];
    
    NSAssert([tok isKindOfClass:[PKToken class]], @"");
    NSAssert([first isKindOfClass:[PKParseTree class]], @"");
    NSAssert([second isKindOfClass:[PKParseTree class]], @"");
        
    PKParseTree *parent = [a pop];
    NSAssert([parent isKindOfClass:[PKParseTree class]], @"");

    PKParseTree *altNode = [parent addChildToken:tok];
    [altNode addChild:first];
    [altNode addChild:second];
    
    [a push:parent];
    [a push:altNode];
    NSLog(@"%@", a);

}


- (void)parser:(PKParser *)p didMatchStatement:(PKAssembly *)a {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, a);
    
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


//- (NSString *)defaultAssemblerSelectorNameForParserName:(NSString *)parserName {
//    NSString *prefix = nil;
//    if ([parserName hasPrefix:@"@"]) {
//        //        parserName = [parserName substringFromIndex:1];
//        //        prefix = @"parser:didMatch_";
//        return nil;
//    } else {
//        prefix = @"parser:didMatch";
//    }
//    NSString *s = [NSString stringWithFormat:@"%@%@", [[parserName substringToIndex:1] uppercaseString], [parserName substringFromIndex:1]];
//    return [NSString stringWithFormat:@"%@%@:", prefix, s];
//}
//
//
//- (NSString *)defaultPreassemblerSelectorNameForParserName:(NSString *)parserName {
//    NSString *prefix = nil;
//    if ([parserName hasPrefix:@"@"]) {
//        return nil;
//    } else {
//        prefix = @"parser:willMatch";
//    }
//    NSString *s = [NSString stringWithFormat:@"%@%@", [[parserName substringToIndex:1] uppercaseString], [parserName substringFromIndex:1]];
//    return [NSString stringWithFormat:@"%@%@:", prefix, s];
//}


- (void)parser:(PKParser *)p didMatchCallback:(PKAssembly *)a {
    PKToken *selNameTok2 = [a pop];
    PKToken *selNameTok1 = [a pop];
    NSString *selName = [NSString stringWithFormat:@"%@:%@:", selNameTok1.stringValue, selNameTok2.stringValue];
    [a push:selName];
}


- (void)parser:(PKParser *)p didMatchExpression:(PKAssembly *)a {
//    NSArray *objs = [a objectsAbove:_paren];
//    NSAssert([objs count], @"");
//    [a pop]; // pop '('
//    
//    if ([objs count] > 1) {
//        PKSequence *seq = nil;
//#if USE_TRACK
//        seq = [PKTrack track];
//#else
//        seq = [PKSequence sequence];
//#endif
//        for (id obj in [objs reverseObjectEnumerator]) {
//            [seq add:obj];
//        }
//        [a push:seq];
//    } else if ([objs count]) {
//        [a push:[objs objectAtIndex:0]];
//    }
}


- (void)parser:(PKParser *)p didMatchDifference:(PKAssembly *)a {
//    PKParser *minus = [a pop];
//    PKParser *sub = [a pop];
//    NSAssert([minus isKindOfClass:[PKParser class]], @"");
//    NSAssert([sub isKindOfClass:[PKParser class]], @"");
//    
//    [a push:[PKDifference differenceWithSubparser:sub minus:minus]];
}


- (void)parser:(PKParser *)p didMatchIntersection:(PKAssembly *)a {
//    PKParser *predicate = [a pop];
//    PKParser *sub = [a pop];
//    NSAssert([predicate isKindOfClass:[PKParser class]], @"");
//    NSAssert([sub isKindOfClass:[PKParser class]], @"");
//    
//    PKIntersection *inter = [PKIntersection intersection];
//    [inter add:sub];
//    [inter add:predicate];
//    
//    [a push:inter];
}


- (void)parser:(PKParser *)p didMatchPatternOptions:(PKAssembly *)a {
//    PKToken *tok = [a pop];
//    NSAssert(tok.isWord, @"");
//    
//    NSString *s = tok.stringValue;
//    NSAssert([s length] > 0, @"");
//    
//    PKPatternOptions opts = PKPatternOptionsNone;
//    if (NSNotFound != [s rangeOfString:@"i"].location) {
//        opts |= PKPatternOptionsIgnoreCase;
//    }
//    if (NSNotFound != [s rangeOfString:@"m"].location) {
//        opts |= PKPatternOptionsMultiline;
//    }
//    if (NSNotFound != [s rangeOfString:@"x"].location) {
//        opts |= PKPatternOptionsComments;
//    }
//    if (NSNotFound != [s rangeOfString:@"s"].location) {
//        opts |= PKPatternOptionsDotAll;
//    }
//    if (NSNotFound != [s rangeOfString:@"w"].location) {
//        opts |= PKPatternOptionsUnicodeWordBoundaries;
//    }
//    
//    [a push:[NSNumber numberWithInteger:opts]];
}


- (void)parser:(PKParser *)p didMatchPattern:(PKAssembly *)a {
//    id obj = [a pop]; // opts (as Number*) or DelimitedString('/', '/')
//    
//    PKPatternOptions opts = PKPatternOptionsNone;
//    if ([obj isKindOfClass:[NSNumber class]]) {
//        opts = [obj unsignedIntValue];
//        obj = [a pop];
//    }
//    
//    NSAssert([obj isMemberOfClass:[PKToken class]], @"");
//    PKToken *tok = (PKToken *)obj;
//    NSAssert(tok.isDelimitedString, @"");
//    
//    NSString *s = tok.stringValue;
//    NSAssert([s length] > 2, @"");
//    
//    NSAssert([s hasPrefix:@"/"], @"");
//    NSAssert([s hasSuffix:@"/"], @"");
//    
//    NSString *re = [s stringByTrimmingQuotes];
//    
//    PKTerminal *t = [PKPattern patternWithString:re options:opts];
//    
//    [a push:t];
}


- (void)parser:(PKParser *)p didMatchDiscard:(PKAssembly *)a {
//    id obj = [a pop];
//    if ([obj isKindOfClass:[PKTerminal class]]) {
//        PKTerminal *t = (PKTerminal *)obj;
//        [t discard];
//    }
//    [a push:obj];
}


- (void)parser:(PKParser *)p didMatchLiteral:(PKAssembly *)a {
//    PKToken *tok = [a pop];
//    
//    NSString *s = [tok.stringValue stringByTrimmingQuotes];
//    PKTerminal *t = nil;
//    
//    NSAssert([s length], @"");
//    if (_wantsCharacters) {
//        t = [PKSpecificChar specificCharWithChar:[s characterAtIndex:0]];
//    } else {
//        t = [PKCaseInsensitiveLiteral literalWithString:s];
//    }
//    
//    [a push:t];
}


//- (void)parser:(PKParser *)p didMatchConstant:(PKAssembly *)a {
//    PKToken *tok = [a pop];
//    NSString *s = tok.stringValue;
//    
//    PKTokenNode *node = nil;
//    if ([s isEqualToString:@"Word"]) {
//        node = [PKTokenNode tokenNodeWithToken:_wordToken]; //[PKWord word];
////    } else if ([s isEqualToString:@"LowercaseWord"]) {
////        obj = [PKLowercaseWord word];
////    } else if ([s isEqualToString:@"UppercaseWord"]) {
////        obj = [PKUppercaseWord word];
//    } else if ([s isEqualToString:@"Number"] || [s isEqualToString:@"Num"]) {
//        node = [PKTokenNode tokenNodeWithToken:_numberToken]; //[PKNumber number];
////    } else if ([s isEqualToString:@"S"]) {
////        obj = [PKWhitespace whitespace];
////    } else if ([s isEqualToString:@"QuotedString"]) {
////        obj = [PKQuotedString quotedString];
////    } else if ([s isEqualToString:@"Symbol"]) {
////        obj = [PKSymbol symbol];
////    } else if ([s isEqualToString:@"Comment"]) {
////        obj = [PKComment comment];
////    } else if ([s isEqualToString:@"Any"]) {
////        obj = [PKAny any];
////    } else if ([s isEqualToString:@"Empty"]) {
////        obj = [PKEmpty empty];
////    } else if ([s isEqualToString:@"Char"]) {
////        obj = [PKChar char];
////    } else if ([s isEqualToString:@"Letter"]) {
////        obj = [PKLetter letter];
////    } else if ([s isEqualToString:@"Digit"]) {
////        obj = [PKDigit digit];
////    } else if ([s isEqualToString:@"Pattern"]) {
////        obj = tok;
////    } else if ([s isEqualToString:@"DelimitedString"]) {
////        obj = tok;
////    } else if ([s isEqualToString:@"YES"] || [s isEqualToString:@"NO"]) {
////        obj = tok;
//    } else {
//        [NSException raise:@"Grammar Exception" format:
//         @"User Grammar referenced a constant parser name (uppercase word) which is not supported: %@. Must be one of: Word, LowercaseWord, UppercaseWord, QuotedString, Number, Symbol, Empty.", s];
//    }
//    
//    [a push:node];
//}


- (void)parser:(PKParser *)p didMatchDelimitedString:(PKAssembly *)a {
//    NSArray *toks = [a objectsAbove:_paren];
//    [a pop]; // discard '(' fence
//    
//    NSAssert([toks count] > 0 && [toks count] < 3, @"");
//    NSString *start = [[[toks lastObject] stringValue] stringByTrimmingQuotes];
//    NSString *end = nil;
//    if ([toks count] > 1) {
//        end = [[[toks objectAtIndex:0] stringValue] stringByTrimmingQuotes];
//    }
//    
//    PKTerminal *t = [PKDelimitedString delimitedStringWithStartMarker:start endMarker:end];
//    
//    [a push:t];
}


- (void)parser:(PKParser *)p didMatchNum:(PKAssembly *)a {
//    PKToken *tok = [a pop];
//    
//    if (_wantsCharacters) {
//        PKUniChar c = [tok.stringValue characterAtIndex:0];
//        [a push:[PKSpecificChar specificCharWithChar:c]];
//    } else {
//        [a push:[NSNumber numberWithFloat:tok.floatValue]];
//    }
}


- (void)parser:(PKParser *)p didMatchStar:(PKAssembly *)a {
//    id top = [a pop];
//    PKRepetition *rep = [PKRepetition repetitionWithSubparser:top];
//    [a push:rep];
}


- (void)parser:(PKParser *)p didMatchPlus:(PKAssembly *)a {
//    id top = [a pop];
//    [a push:[self oneOrMore:top]];
}


- (void)parser:(PKParser *)p didMatchQuestion:(PKAssembly *)a {
//    id top = [a pop];
//    [a push:[self zeroOrOne:top]];
}


- (void)parser:(PKParser *)p didMatchPhraseCardinality:(PKAssembly *)a {
//    NSRange r = [[a pop] rangeValue];
//    
//    p = [a pop];
//    PKSequence *s = [PKSequence sequence];
//    
//    NSInteger start = r.location;
//    NSInteger end = r.length;
//    
//    for (NSInteger i = 0; i < start; i++) {
//        [s add:p];
//    }
//    
//    for (NSInteger i = 0; i < end; i++) {
//        [s add:[self zeroOrOne:p]];
//    }
//    
//    [a push:s];
}


- (void)parser:(PKParser *)p didMatchCardinality:(PKAssembly *)a {
//    NSArray *toks = [a objectsAbove:self.curly];
//    [a pop]; // discard '{' tok
//    
//    NSAssert([toks count] > 0, @"");
//    
//    PKToken *tok = [toks lastObject];
//    PKFloat start = tok.floatValue;
//    PKFloat end = start;
//    if ([toks count] > 1) {
//        tok = [toks objectAtIndex:0];
//        end = tok.floatValue;
//    }
//    
//    NSAssert(start <= end, @"");
//    
//    NSRange r = NSMakeRange(start, end);
//    [a push:[NSValue valueWithRange:r]];
}


- (void)parser:(PKParser *)p didMatchAnd:(PKAssembly *)a {
//    NSMutableArray *parsers = [NSMutableArray array];
//    while (![a isStackEmpty]) {
//        id obj = [a pop];
//        if ([obj isKindOfClass:[PKParser class]]) {
//            [parsers addObject:obj];
//        } else {
//            [a push:obj];
//            break;
//        }
//    }
//    
//    if ([parsers count] > 1) {
//        PKSequence *seq = nil;
//#if USE_TRACK
//        seq = [PKTrack track];
//#else
//        seq = [PKSequence sequence];
//#endif
//        for (PKParser *p in [parsers reverseObjectEnumerator]) {
//            [seq add:p];
//        }
//        
//        [a push:seq];
//    } else if (1 == [parsers count]) {
//        [a push:[parsers objectAtIndex:0]];
//    }
}


- (void)parser:(PKParser *)p didMatchNegation:(PKAssembly *)a {
//    p = [a pop];
//    [a push:[PKNegation negationWithSubparser:p]];
}

@end
