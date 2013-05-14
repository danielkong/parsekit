#import "ParseKitParser.h"
#import <ParseKit/ParseKit.h>

#define LT(i) [self LT:(i)]
#define LA(i) [self LA:(i)]
#define LS(i) [self LS:(i)]
#define LF(i) [self LF:(i)]

#define POP()       [self.assembly pop]
#define POP_STR()   [self _popString]
#define POP_TOK()   [self _popToken]
#define POP_BOOL()  [self _popBool]
#define POP_INT()   [self _popInteger]
#define POP_FLOAT() [self _popDouble]

#define PUSH(obj)     [self.assembly push:(id)(obj)]
#define PUSH_BOOL(yn) [self _pushBool:(BOOL)(yn)]
#define PUSH_INT(i)   [self _pushInteger:(NSInteger)(i)]
#define PUSH_FLOAT(f) [self _pushDouble:(double)(f)]

#define EQ(a, b) [(a) isEqual:(b)]
#define NE(a, b) (![(a) isEqual:(b)])
#define EQ_IGNORE_CASE(a, b) (NSOrderedSame == [(a) compare:(b)])

#define ABOVE(fence) [self.assembly objectsAbove:(fence)]

#define LOG(obj) do { NSLog(@"%@", (obj)); } while (0);
#define PRINT(str) do { printf("%s\n", (str)); } while (0);

@interface PKSParser ()
@property (nonatomic, retain) NSMutableDictionary *_tokenKindTab;
@property (nonatomic, retain) NSMutableArray *_tokenKindNameTab;

- (BOOL)_popBool;
- (NSInteger)_popInteger;
- (double)_popDouble;
- (PKToken *)_popToken;
- (NSString *)_popString;

- (void)_pushBool:(BOOL)yn;
- (void)_pushInteger:(NSInteger)i;
- (void)_pushDouble:(double)d;
@end

@interface ParseKitParser ()
@end

@implementation ParseKitParser

- (id)init {
    self = [super init];
    if (self) {
        self._tokenKindTab[@"Symbol"] = @(PARSEKIT_TOKEN_KIND_SYMBOL_TITLE);
        self._tokenKindTab[@"{,}?"] = @(PARSEKIT_TOKEN_KIND_SEMANTICPREDICATE);
        self._tokenKindTab[@"|"] = @(PARSEKIT_TOKEN_KIND_PIPE);
        self._tokenKindTab[@"after"] = @(PARSEKIT_TOKEN_KIND_AFTERKEY);
        self._tokenKindTab[@"}"] = @(PARSEKIT_TOKEN_KIND_CLOSE_CURLY);
        self._tokenKindTab[@"~"] = @(PARSEKIT_TOKEN_KIND_TILDE);
        self._tokenKindTab[@"Comment"] = @(PARSEKIT_TOKEN_KIND_COMMENT_TITLE);
        self._tokenKindTab[@"!"] = @(PARSEKIT_TOKEN_KIND_DISCARD);
        self._tokenKindTab[@"Number"] = @(PARSEKIT_TOKEN_KIND_NUMBER_TITLE);
        self._tokenKindTab[@"Any"] = @(PARSEKIT_TOKEN_KIND_ANY_TITLE);
        self._tokenKindTab[@";"] = @(PARSEKIT_TOKEN_KIND_SEMI_COLON);
        self._tokenKindTab[@"S"] = @(PARSEKIT_TOKEN_KIND_S_TITLE);
        self._tokenKindTab[@"{,}"] = @(PARSEKIT_TOKEN_KIND_ACTION);
        self._tokenKindTab[@"="] = @(PARSEKIT_TOKEN_KIND_EQUALS);
        self._tokenKindTab[@"&"] = @(PARSEKIT_TOKEN_KIND_AMPERSAND);
        self._tokenKindTab[@"/,/"] = @(PARSEKIT_TOKEN_KIND_PATTERNNOOPTS);
        self._tokenKindTab[@"?"] = @(PARSEKIT_TOKEN_KIND_PHRASEQUESTION);
        self._tokenKindTab[@"QuotedString"] = @(PARSEKIT_TOKEN_KIND_QUOTEDSTRING_TITLE);
        self._tokenKindTab[@"("] = @(PARSEKIT_TOKEN_KIND_OPEN_PAREN);
        self._tokenKindTab[@"@"] = @(PARSEKIT_TOKEN_KIND_AT);
        self._tokenKindTab[@"/,/i"] = @(PARSEKIT_TOKEN_KIND_PATTERNIGNORECASE);
        self._tokenKindTab[@"before"] = @(PARSEKIT_TOKEN_KIND_BEFOREKEY);
        self._tokenKindTab[@"EOF"] = @(PARSEKIT_TOKEN_KIND_EOF_TITLE);
        self._tokenKindTab[@")"] = @(PARSEKIT_TOKEN_KIND_CLOSE_PAREN);
        self._tokenKindTab[@"*"] = @(PARSEKIT_TOKEN_KIND_PHRASESTAR);
        self._tokenKindTab[@"Letter"] = @(PARSEKIT_TOKEN_KIND_LETTER_TITLE);
        self._tokenKindTab[@"Empty"] = @(PARSEKIT_TOKEN_KIND_EMPTY_TITLE);
        self._tokenKindTab[@"+"] = @(PARSEKIT_TOKEN_KIND_PHRASEPLUS);
        self._tokenKindTab[@"["] = @(PARSEKIT_TOKEN_KIND_OPEN_BRACKET);
        self._tokenKindTab[@","] = @(PARSEKIT_TOKEN_KIND_COMMA);
        self._tokenKindTab[@"SpecificChar"] = @(PARSEKIT_TOKEN_KIND_SPECIFICCHAR_TITLE);
        self._tokenKindTab[@"-"] = @(PARSEKIT_TOKEN_KIND_MINUS);
        self._tokenKindTab[@"Word"] = @(PARSEKIT_TOKEN_KIND_WORD_TITLE);
        self._tokenKindTab[@"]"] = @(PARSEKIT_TOKEN_KIND_CLOSE_BRACKET);
        self._tokenKindTab[@"Char"] = @(PARSEKIT_TOKEN_KIND_CHAR_TITLE);
        self._tokenKindTab[@"Digit"] = @(PARSEKIT_TOKEN_KIND_DIGIT_TITLE);
        self._tokenKindTab[@"%{"] = @(PARSEKIT_TOKEN_KIND_DELIMOPEN);

        self._tokenKindNameTab[PARSEKIT_TOKEN_KIND_SYMBOL_TITLE] = @"Symbol";
        self._tokenKindNameTab[PARSEKIT_TOKEN_KIND_SEMANTICPREDICATE] = @"{,}?";
        self._tokenKindNameTab[PARSEKIT_TOKEN_KIND_PIPE] = @"|";
        self._tokenKindNameTab[PARSEKIT_TOKEN_KIND_AFTERKEY] = @"after";
        self._tokenKindNameTab[PARSEKIT_TOKEN_KIND_CLOSE_CURLY] = @"}";
        self._tokenKindNameTab[PARSEKIT_TOKEN_KIND_TILDE] = @"~";
        self._tokenKindNameTab[PARSEKIT_TOKEN_KIND_COMMENT_TITLE] = @"Comment";
        self._tokenKindNameTab[PARSEKIT_TOKEN_KIND_DISCARD] = @"!";
        self._tokenKindNameTab[PARSEKIT_TOKEN_KIND_NUMBER_TITLE] = @"Number";
        self._tokenKindNameTab[PARSEKIT_TOKEN_KIND_ANY_TITLE] = @"Any";
        self._tokenKindNameTab[PARSEKIT_TOKEN_KIND_SEMI_COLON] = @";";
        self._tokenKindNameTab[PARSEKIT_TOKEN_KIND_S_TITLE] = @"S";
        self._tokenKindNameTab[PARSEKIT_TOKEN_KIND_ACTION] = @"{,}";
        self._tokenKindNameTab[PARSEKIT_TOKEN_KIND_EQUALS] = @"=";
        self._tokenKindNameTab[PARSEKIT_TOKEN_KIND_AMPERSAND] = @"&";
        self._tokenKindNameTab[PARSEKIT_TOKEN_KIND_PATTERNNOOPTS] = @"/,/";
        self._tokenKindNameTab[PARSEKIT_TOKEN_KIND_PHRASEQUESTION] = @"?";
        self._tokenKindNameTab[PARSEKIT_TOKEN_KIND_QUOTEDSTRING_TITLE] = @"QuotedString";
        self._tokenKindNameTab[PARSEKIT_TOKEN_KIND_OPEN_PAREN] = @"(";
        self._tokenKindNameTab[PARSEKIT_TOKEN_KIND_AT] = @"@";
        self._tokenKindNameTab[PARSEKIT_TOKEN_KIND_PATTERNIGNORECASE] = @"/,/i";
        self._tokenKindNameTab[PARSEKIT_TOKEN_KIND_BEFOREKEY] = @"before";
        self._tokenKindNameTab[PARSEKIT_TOKEN_KIND_EOF_TITLE] = @"EOF";
        self._tokenKindNameTab[PARSEKIT_TOKEN_KIND_CLOSE_PAREN] = @")";
        self._tokenKindNameTab[PARSEKIT_TOKEN_KIND_PHRASESTAR] = @"*";
        self._tokenKindNameTab[PARSEKIT_TOKEN_KIND_LETTER_TITLE] = @"Letter";
        self._tokenKindNameTab[PARSEKIT_TOKEN_KIND_EMPTY_TITLE] = @"Empty";
        self._tokenKindNameTab[PARSEKIT_TOKEN_KIND_PHRASEPLUS] = @"+";
        self._tokenKindNameTab[PARSEKIT_TOKEN_KIND_OPEN_BRACKET] = @"[";
        self._tokenKindNameTab[PARSEKIT_TOKEN_KIND_COMMA] = @",";
        self._tokenKindNameTab[PARSEKIT_TOKEN_KIND_SPECIFICCHAR_TITLE] = @"SpecificChar";
        self._tokenKindNameTab[PARSEKIT_TOKEN_KIND_MINUS] = @"-";
        self._tokenKindNameTab[PARSEKIT_TOKEN_KIND_WORD_TITLE] = @"Word";
        self._tokenKindNameTab[PARSEKIT_TOKEN_KIND_CLOSE_BRACKET] = @"]";
        self._tokenKindNameTab[PARSEKIT_TOKEN_KIND_CHAR_TITLE] = @"Char";
        self._tokenKindNameTab[PARSEKIT_TOKEN_KIND_DIGIT_TITLE] = @"Digit";
        self._tokenKindNameTab[PARSEKIT_TOKEN_KIND_DELIMOPEN] = @"%{";

    }
    return self;
}

- (void)_start {
    [self start];
}

- (void)start {
    
    do {
        [self statement]; 
    } while ([self speculate:^{ [self statement]; }]);
    [self matchEOF:YES]; 

    [self fireAssemblerSelector:@selector(parser:didMatchStart:)];
}

- (void)statement {
    
    if ([self predicts:TOKEN_KIND_BUILTIN_WORD, 0]) {
        [self decl]; 
    } else if ([self predicts:PARSEKIT_TOKEN_KIND_AT, 0]) {
        [self tokenizerDirective]; 
    } else {
        [self raise:@"No viable alternative found in rule 'statement'."];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchStatement:)];
}

- (void)tokenizerDirective {
    
    [self match:PARSEKIT_TOKEN_KIND_AT discard:YES]; 
    [self matchWord:NO]; 
    [self match:PARSEKIT_TOKEN_KIND_EQUALS discard:NO]; 
    do {
        if ([self predicts:TOKEN_KIND_BUILTIN_WORD, 0]) {
            [self matchWord:NO]; 
        } else if ([self predicts:TOKEN_KIND_BUILTIN_QUOTEDSTRING, 0]) {
            [self matchQuotedString:NO]; 
        } else {
            [self raise:@"No viable alternative found in rule 'tokenizerDirective'."];
        }
    } while ([self predicts:TOKEN_KIND_BUILTIN_QUOTEDSTRING, TOKEN_KIND_BUILTIN_WORD, 0]);
    [self match:PARSEKIT_TOKEN_KIND_SEMI_COLON discard:YES]; 

    [self fireAssemblerSelector:@selector(parser:didMatchTokenizerDirective:)];
}

- (void)decl {
    
    [self production]; 
    while ([self predicts:PARSEKIT_TOKEN_KIND_AT, 0]) {
        if ([self speculate:^{ [self namedAction]; }]) {
            [self namedAction]; 
        } else {
            break;
        }
    }
    [self match:PARSEKIT_TOKEN_KIND_EQUALS discard:NO]; 
    if ([self predicts:PARSEKIT_TOKEN_KIND_ACTION, 0]) {
        [self action]; 
    }
    [self expr]; 
    [self match:PARSEKIT_TOKEN_KIND_SEMI_COLON discard:YES]; 

    [self fireAssemblerSelector:@selector(parser:didMatchDecl:)];
}

- (void)production {
    
    [self varProduction]; 

    [self fireAssemblerSelector:@selector(parser:didMatchProduction:)];
}

- (void)namedAction {
    
    [self match:PARSEKIT_TOKEN_KIND_AT discard:YES]; 
    if ([self predicts:PARSEKIT_TOKEN_KIND_BEFOREKEY, 0]) {
        [self beforeKey]; 
    } else if ([self predicts:PARSEKIT_TOKEN_KIND_AFTERKEY, 0]) {
        [self afterKey]; 
    } else {
        [self raise:@"No viable alternative found in rule 'namedAction'."];
    }
    [self action]; 

    [self fireAssemblerSelector:@selector(parser:didMatchNamedAction:)];
}

- (void)beforeKey {
    
    [self match:PARSEKIT_TOKEN_KIND_BEFOREKEY discard:NO]; 

    [self fireAssemblerSelector:@selector(parser:didMatchBeforeKey:)];
}

- (void)afterKey {
    
    [self match:PARSEKIT_TOKEN_KIND_AFTERKEY discard:NO]; 

    [self fireAssemblerSelector:@selector(parser:didMatchAfterKey:)];
}

- (void)varProduction {
    
    [self matchWord:NO]; 

    [self fireAssemblerSelector:@selector(parser:didMatchVarProduction:)];
}

- (void)expr {
    
    [self term]; 
    while ([self predicts:PARSEKIT_TOKEN_KIND_PIPE, 0]) {
        if ([self speculate:^{ [self orTerm]; }]) {
            [self orTerm]; 
        } else {
            break;
        }
    }

    [self fireAssemblerSelector:@selector(parser:didMatchExpr:)];
}

- (void)term {
    
    if ([self predicts:PARSEKIT_TOKEN_KIND_SEMANTICPREDICATE, 0]) {
        [self semanticPredicate]; 
    }
    [self factor]; 
    while ([self predicts:PARSEKIT_TOKEN_KIND_ANY_TITLE, PARSEKIT_TOKEN_KIND_CHAR_TITLE, PARSEKIT_TOKEN_KIND_COMMENT_TITLE, PARSEKIT_TOKEN_KIND_DELIMOPEN, PARSEKIT_TOKEN_KIND_DIGIT_TITLE, PARSEKIT_TOKEN_KIND_EMPTY_TITLE, PARSEKIT_TOKEN_KIND_EOF_TITLE, PARSEKIT_TOKEN_KIND_LETTER_TITLE, PARSEKIT_TOKEN_KIND_NUMBER_TITLE, PARSEKIT_TOKEN_KIND_OPEN_BRACKET, PARSEKIT_TOKEN_KIND_OPEN_PAREN, PARSEKIT_TOKEN_KIND_PATTERNIGNORECASE, PARSEKIT_TOKEN_KIND_PATTERNNOOPTS, PARSEKIT_TOKEN_KIND_QUOTEDSTRING_TITLE, PARSEKIT_TOKEN_KIND_SPECIFICCHAR_TITLE, PARSEKIT_TOKEN_KIND_SYMBOL_TITLE, PARSEKIT_TOKEN_KIND_S_TITLE, PARSEKIT_TOKEN_KIND_TILDE, PARSEKIT_TOKEN_KIND_WORD_TITLE, TOKEN_KIND_BUILTIN_QUOTEDSTRING, TOKEN_KIND_BUILTIN_WORD, 0]) {
        if ([self speculate:^{ [self nextFactor]; }]) {
            [self nextFactor]; 
        } else {
            break;
        }
    }

    [self fireAssemblerSelector:@selector(parser:didMatchTerm:)];
}

- (void)orTerm {
    
    [self match:PARSEKIT_TOKEN_KIND_PIPE discard:NO]; 
    [self term]; 

    [self fireAssemblerSelector:@selector(parser:didMatchOrTerm:)];
}

- (void)factor {
    
    [self phrase]; 
    if ([self predicts:PARSEKIT_TOKEN_KIND_PHRASEPLUS, PARSEKIT_TOKEN_KIND_PHRASEQUESTION, PARSEKIT_TOKEN_KIND_PHRASESTAR, 0]) {
        if ([self predicts:PARSEKIT_TOKEN_KIND_PHRASESTAR, 0]) {
            [self phraseStar]; 
        } else if ([self predicts:PARSEKIT_TOKEN_KIND_PHRASEPLUS, 0]) {
            [self phrasePlus]; 
        } else if ([self predicts:PARSEKIT_TOKEN_KIND_PHRASEQUESTION, 0]) {
            [self phraseQuestion]; 
        } else {
            [self raise:@"No viable alternative found in rule 'factor'."];
        }
    }
    if ([self predicts:PARSEKIT_TOKEN_KIND_ACTION, 0]) {
        [self action]; 
    }

    [self fireAssemblerSelector:@selector(parser:didMatchFactor:)];
}

- (void)nextFactor {
    
    [self factor]; 

    [self fireAssemblerSelector:@selector(parser:didMatchNextFactor:)];
}

- (void)phrase {
    
    [self primaryExpr]; 
    while ([self predicts:PARSEKIT_TOKEN_KIND_AMPERSAND, PARSEKIT_TOKEN_KIND_MINUS, 0]) {
        if ([self speculate:^{ [self predicate]; }]) {
            [self predicate]; 
        } else {
            break;
        }
    }

    [self fireAssemblerSelector:@selector(parser:didMatchPhrase:)];
}

- (void)phraseStar {
    
    [self match:PARSEKIT_TOKEN_KIND_PHRASESTAR discard:YES]; 

    [self fireAssemblerSelector:@selector(parser:didMatchPhraseStar:)];
}

- (void)phrasePlus {
    
    [self match:PARSEKIT_TOKEN_KIND_PHRASEPLUS discard:YES]; 

    [self fireAssemblerSelector:@selector(parser:didMatchPhrasePlus:)];
}

- (void)phraseQuestion {
    
    [self match:PARSEKIT_TOKEN_KIND_PHRASEQUESTION discard:YES]; 

    [self fireAssemblerSelector:@selector(parser:didMatchPhraseQuestion:)];
}

- (void)action {
    
    [self match:PARSEKIT_TOKEN_KIND_ACTION discard:NO]; 

    [self fireAssemblerSelector:@selector(parser:didMatchAction:)];
}

- (void)semanticPredicate {
    
    [self match:PARSEKIT_TOKEN_KIND_SEMANTICPREDICATE discard:NO]; 

    [self fireAssemblerSelector:@selector(parser:didMatchSemanticPredicate:)];
}

- (void)predicate {
    
    if ([self predicts:PARSEKIT_TOKEN_KIND_AMPERSAND, 0]) {
        [self intersection]; 
    } else if ([self predicts:PARSEKIT_TOKEN_KIND_MINUS, 0]) {
        [self difference]; 
    } else {
        [self raise:@"No viable alternative found in rule 'predicate'."];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchPredicate:)];
}

- (void)intersection {
    
    [self match:PARSEKIT_TOKEN_KIND_AMPERSAND discard:YES]; 
    [self primaryExpr]; 

    [self fireAssemblerSelector:@selector(parser:didMatchIntersection:)];
}

- (void)difference {
    
    [self match:PARSEKIT_TOKEN_KIND_MINUS discard:YES]; 
    [self primaryExpr]; 

    [self fireAssemblerSelector:@selector(parser:didMatchDifference:)];
}

- (void)primaryExpr {
    
    if ([self predicts:PARSEKIT_TOKEN_KIND_TILDE, 0]) {
        [self negatedPrimaryExpr]; 
    } else if ([self predicts:PARSEKIT_TOKEN_KIND_ANY_TITLE, PARSEKIT_TOKEN_KIND_CHAR_TITLE, PARSEKIT_TOKEN_KIND_COMMENT_TITLE, PARSEKIT_TOKEN_KIND_DELIMOPEN, PARSEKIT_TOKEN_KIND_DIGIT_TITLE, PARSEKIT_TOKEN_KIND_EMPTY_TITLE, PARSEKIT_TOKEN_KIND_EOF_TITLE, PARSEKIT_TOKEN_KIND_LETTER_TITLE, PARSEKIT_TOKEN_KIND_NUMBER_TITLE, PARSEKIT_TOKEN_KIND_OPEN_BRACKET, PARSEKIT_TOKEN_KIND_OPEN_PAREN, PARSEKIT_TOKEN_KIND_PATTERNIGNORECASE, PARSEKIT_TOKEN_KIND_PATTERNNOOPTS, PARSEKIT_TOKEN_KIND_QUOTEDSTRING_TITLE, PARSEKIT_TOKEN_KIND_SPECIFICCHAR_TITLE, PARSEKIT_TOKEN_KIND_SYMBOL_TITLE, PARSEKIT_TOKEN_KIND_S_TITLE, PARSEKIT_TOKEN_KIND_WORD_TITLE, TOKEN_KIND_BUILTIN_QUOTEDSTRING, TOKEN_KIND_BUILTIN_WORD, 0]) {
        [self barePrimaryExpr]; 
    } else {
        [self raise:@"No viable alternative found in rule 'primaryExpr'."];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchPrimaryExpr:)];
}

- (void)negatedPrimaryExpr {
    
    [self match:PARSEKIT_TOKEN_KIND_TILDE discard:YES]; 
    [self barePrimaryExpr]; 

    [self fireAssemblerSelector:@selector(parser:didMatchNegatedPrimaryExpr:)];
}

- (void)barePrimaryExpr {
    
    if ([self predicts:PARSEKIT_TOKEN_KIND_ANY_TITLE, PARSEKIT_TOKEN_KIND_CHAR_TITLE, PARSEKIT_TOKEN_KIND_COMMENT_TITLE, PARSEKIT_TOKEN_KIND_DELIMOPEN, PARSEKIT_TOKEN_KIND_DIGIT_TITLE, PARSEKIT_TOKEN_KIND_EMPTY_TITLE, PARSEKIT_TOKEN_KIND_EOF_TITLE, PARSEKIT_TOKEN_KIND_LETTER_TITLE, PARSEKIT_TOKEN_KIND_NUMBER_TITLE, PARSEKIT_TOKEN_KIND_PATTERNIGNORECASE, PARSEKIT_TOKEN_KIND_PATTERNNOOPTS, PARSEKIT_TOKEN_KIND_QUOTEDSTRING_TITLE, PARSEKIT_TOKEN_KIND_SPECIFICCHAR_TITLE, PARSEKIT_TOKEN_KIND_SYMBOL_TITLE, PARSEKIT_TOKEN_KIND_S_TITLE, PARSEKIT_TOKEN_KIND_WORD_TITLE, TOKEN_KIND_BUILTIN_QUOTEDSTRING, TOKEN_KIND_BUILTIN_WORD, 0]) {
        [self atomicValue]; 
    } else if ([self predicts:PARSEKIT_TOKEN_KIND_OPEN_PAREN, 0]) {
        [self subSeqExpr]; 
    } else if ([self predicts:PARSEKIT_TOKEN_KIND_OPEN_BRACKET, 0]) {
        [self subTrackExpr]; 
    } else {
        [self raise:@"No viable alternative found in rule 'barePrimaryExpr'."];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchBarePrimaryExpr:)];
}

- (void)subSeqExpr {
    
    [self match:PARSEKIT_TOKEN_KIND_OPEN_PAREN discard:NO]; 
    [self expr]; 
    [self match:PARSEKIT_TOKEN_KIND_CLOSE_PAREN discard:YES]; 

    [self fireAssemblerSelector:@selector(parser:didMatchSubSeqExpr:)];
}

- (void)subTrackExpr {
    
    [self match:PARSEKIT_TOKEN_KIND_OPEN_BRACKET discard:NO]; 
    [self expr]; 
    [self match:PARSEKIT_TOKEN_KIND_CLOSE_BRACKET discard:YES]; 

    [self fireAssemblerSelector:@selector(parser:didMatchSubTrackExpr:)];
}

- (void)atomicValue {
    
    [self parser]; 
    if ([self predicts:PARSEKIT_TOKEN_KIND_DISCARD, 0]) {
        [self discard]; 
    }

    [self fireAssemblerSelector:@selector(parser:didMatchAtomicValue:)];
}

- (void)parser {
    
    if ([self predicts:TOKEN_KIND_BUILTIN_WORD, 0]) {
        [self variable]; 
    } else if ([self predicts:TOKEN_KIND_BUILTIN_QUOTEDSTRING, 0]) {
        [self literal]; 
    } else if ([self predicts:PARSEKIT_TOKEN_KIND_PATTERNIGNORECASE, PARSEKIT_TOKEN_KIND_PATTERNNOOPTS, 0]) {
        [self pattern]; 
    } else if ([self predicts:PARSEKIT_TOKEN_KIND_DELIMOPEN, 0]) {
        [self delimitedString]; 
    } else if ([self predicts:PARSEKIT_TOKEN_KIND_ANY_TITLE, PARSEKIT_TOKEN_KIND_CHAR_TITLE, PARSEKIT_TOKEN_KIND_COMMENT_TITLE, PARSEKIT_TOKEN_KIND_DIGIT_TITLE, PARSEKIT_TOKEN_KIND_EMPTY_TITLE, PARSEKIT_TOKEN_KIND_EOF_TITLE, PARSEKIT_TOKEN_KIND_LETTER_TITLE, PARSEKIT_TOKEN_KIND_NUMBER_TITLE, PARSEKIT_TOKEN_KIND_QUOTEDSTRING_TITLE, PARSEKIT_TOKEN_KIND_SPECIFICCHAR_TITLE, PARSEKIT_TOKEN_KIND_SYMBOL_TITLE, PARSEKIT_TOKEN_KIND_S_TITLE, PARSEKIT_TOKEN_KIND_WORD_TITLE, 0]) {
        [self constant]; 
    } else {
        [self raise:@"No viable alternative found in rule 'parser'."];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchParser:)];
}

- (void)discard {
    
    [self match:PARSEKIT_TOKEN_KIND_DISCARD discard:YES]; 

    [self fireAssemblerSelector:@selector(parser:didMatchDiscard:)];
}

- (void)pattern {
    
    if ([self predicts:PARSEKIT_TOKEN_KIND_PATTERNNOOPTS, 0]) {
        [self patternNoOpts]; 
    } else if ([self predicts:PARSEKIT_TOKEN_KIND_PATTERNIGNORECASE, 0]) {
        [self patternIgnoreCase]; 
    } else {
        [self raise:@"No viable alternative found in rule 'pattern'."];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchPattern:)];
}

- (void)patternNoOpts {
    
    [self match:PARSEKIT_TOKEN_KIND_PATTERNNOOPTS discard:NO]; 

    [self fireAssemblerSelector:@selector(parser:didMatchPatternNoOpts:)];
}

- (void)patternIgnoreCase {
    
    [self match:PARSEKIT_TOKEN_KIND_PATTERNIGNORECASE discard:NO]; 

    [self fireAssemblerSelector:@selector(parser:didMatchPatternIgnoreCase:)];
}

- (void)delimitedString {
    
    [self delimOpen]; 
    [self matchQuotedString:NO]; 
    if ([self speculate:^{ [self match:PARSEKIT_TOKEN_KIND_COMMA discard:YES]; [self matchQuotedString:NO]; }]) {
        [self match:PARSEKIT_TOKEN_KIND_COMMA discard:YES]; 
        [self matchQuotedString:NO]; 
    }
    [self match:PARSEKIT_TOKEN_KIND_CLOSE_CURLY discard:YES]; 

    [self fireAssemblerSelector:@selector(parser:didMatchDelimitedString:)];
}

- (void)literal {
    
    [self matchQuotedString:NO]; 

    [self fireAssemblerSelector:@selector(parser:didMatchLiteral:)];
}

- (void)constant {
    
    if ([self predicts:PARSEKIT_TOKEN_KIND_EOF_TITLE, 0]) {
        [self match:PARSEKIT_TOKEN_KIND_EOF_TITLE discard:NO]; 
    } else if ([self predicts:PARSEKIT_TOKEN_KIND_WORD_TITLE, 0]) {
        [self match:PARSEKIT_TOKEN_KIND_WORD_TITLE discard:NO]; 
    } else if ([self predicts:PARSEKIT_TOKEN_KIND_NUMBER_TITLE, 0]) {
        [self match:PARSEKIT_TOKEN_KIND_NUMBER_TITLE discard:NO]; 
    } else if ([self predicts:PARSEKIT_TOKEN_KIND_QUOTEDSTRING_TITLE, 0]) {
        [self match:PARSEKIT_TOKEN_KIND_QUOTEDSTRING_TITLE discard:NO]; 
    } else if ([self predicts:PARSEKIT_TOKEN_KIND_SYMBOL_TITLE, 0]) {
        [self match:PARSEKIT_TOKEN_KIND_SYMBOL_TITLE discard:NO]; 
    } else if ([self predicts:PARSEKIT_TOKEN_KIND_COMMENT_TITLE, 0]) {
        [self match:PARSEKIT_TOKEN_KIND_COMMENT_TITLE discard:NO]; 
    } else if ([self predicts:PARSEKIT_TOKEN_KIND_EMPTY_TITLE, 0]) {
        [self match:PARSEKIT_TOKEN_KIND_EMPTY_TITLE discard:NO]; 
    } else if ([self predicts:PARSEKIT_TOKEN_KIND_ANY_TITLE, 0]) {
        [self match:PARSEKIT_TOKEN_KIND_ANY_TITLE discard:NO]; 
    } else if ([self predicts:PARSEKIT_TOKEN_KIND_S_TITLE, 0]) {
        [self match:PARSEKIT_TOKEN_KIND_S_TITLE discard:NO]; 
    } else if ([self predicts:PARSEKIT_TOKEN_KIND_DIGIT_TITLE, 0]) {
        [self match:PARSEKIT_TOKEN_KIND_DIGIT_TITLE discard:NO]; 
    } else if ([self predicts:PARSEKIT_TOKEN_KIND_LETTER_TITLE, 0]) {
        [self match:PARSEKIT_TOKEN_KIND_LETTER_TITLE discard:NO]; 
    } else if ([self predicts:PARSEKIT_TOKEN_KIND_CHAR_TITLE, 0]) {
        [self match:PARSEKIT_TOKEN_KIND_CHAR_TITLE discard:NO]; 
    } else if ([self predicts:PARSEKIT_TOKEN_KIND_SPECIFICCHAR_TITLE, 0]) {
        [self match:PARSEKIT_TOKEN_KIND_SPECIFICCHAR_TITLE discard:NO]; 
    } else {
        [self raise:@"No viable alternative found in rule 'constant'."];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchConstant:)];
}

- (void)variable {
    
    [self matchWord:NO]; 

    [self fireAssemblerSelector:@selector(parser:didMatchVariable:)];
}

- (void)delimOpen {
    
    [self match:PARSEKIT_TOKEN_KIND_DELIMOPEN discard:NO]; 

    [self fireAssemblerSelector:@selector(parser:didMatchDelimOpen:)];
}

@end