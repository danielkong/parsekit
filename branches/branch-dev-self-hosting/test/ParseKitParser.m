#import "ParseKitParser.h"
#import <ParseKit/ParseKit.h>
#import "PKSRecognitionException.h"

#define LT(i) [self LT:(i)]
#define LA(i) [self LA:(i)]
#define LS(i) [self LS:(i)]
#define LF(i) [self LF:(i)]

#define POP()       [self._assembly pop]
#define POP_STR()   [self _popString]
#define POP_TOK()   [self _popToken]
#define POP_BOOL()  [self _popBool]
#define POP_INT()   [self _popInteger]
#define POP_FLOAT() [self _popDouble]

#define PUSH(obj)     [self._assembly push:(id)(obj)]
#define PUSH_BOOL(yn) [self _pushBool:(BOOL)(yn)]
#define PUSH_INT(i)   [self _pushInteger:(NSInteger)(i)]
#define PUSH_FLOAT(f) [self _pushDouble:(double)(f)]

#define EQ(a, b) [(a) isEqual:(b)]
#define NE(a, b) (![(a) isEqual:(b)])
#define EQ_IGNORE_CASE(a, b) (NSOrderedSame == [(a) compare:(b)])

#define ABOVE(fence) [self._assembly objectsAbove:(fence)]

#define LOG(obj) do { NSLog(@"%@", (obj)); } while (0);
#define PRINT(str) do { printf("%s\n", (str)); } while (0);

@interface PKSParser ()
@property (nonatomic, retain) PKAssembly *_assembly;
@property (nonatomic, retain) NSMutableDictionary *_tokenKindTab;

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
        self._tokenKindTab[@"Symbol"] = @(TOKEN_KIND_SYMBOL_TITLE);
        self._tokenKindTab[@"{,}?"] = @(TOKEN_KIND_SEMANTICPREDICATE);
        self._tokenKindTab[@"|"] = @(TOKEN_KIND_PIPE);
        self._tokenKindTab[@"}"] = @(TOKEN_KIND_CLOSE_CURLY);
        self._tokenKindTab[@"~"] = @(TOKEN_KIND_TILDE);
        self._tokenKindTab[@"start"] = @(TOKEN_KIND_START);
        self._tokenKindTab[@"Comment"] = @(TOKEN_KIND_COMMENT_TITLE);
        self._tokenKindTab[@"!"] = @(TOKEN_KIND_DISCARD);
        self._tokenKindTab[@"Number"] = @(TOKEN_KIND_NUMBER_TITLE);
        self._tokenKindTab[@"Any"] = @(TOKEN_KIND_ANY_TITLE);
        self._tokenKindTab[@";"] = @(TOKEN_KIND_SEMI_COLON);
        self._tokenKindTab[@"S"] = @(TOKEN_KIND_S_TITLE);
        self._tokenKindTab[@"{,}"] = @(TOKEN_KIND_ACTION);
        self._tokenKindTab[@"="] = @(TOKEN_KIND_EQUALS);
        self._tokenKindTab[@"&"] = @(TOKEN_KIND_AMPERSAND);
        self._tokenKindTab[@"/,/"] = @(TOKEN_KIND_PATTERNNOOPTS);
        self._tokenKindTab[@"?"] = @(TOKEN_KIND_PHRASEQUESTION);
        self._tokenKindTab[@"QuotedString"] = @(TOKEN_KIND_QUOTEDSTRING_TITLE);
        self._tokenKindTab[@"Letter"] = @(TOKEN_KIND_LETTER_TITLE);
        self._tokenKindTab[@"@"] = @(TOKEN_KIND_AT);
        self._tokenKindTab[@"("] = @(TOKEN_KIND_OPEN_PAREN);
        self._tokenKindTab[@")"] = @(TOKEN_KIND_CLOSE_PAREN);
        self._tokenKindTab[@"/,/i"] = @(TOKEN_KIND_PATTERNIGNORECASE);
        self._tokenKindTab[@"*"] = @(TOKEN_KIND_PHRASESTAR);
        self._tokenKindTab[@"Empty"] = @(TOKEN_KIND_EMPTY_TITLE);
        self._tokenKindTab[@"+"] = @(TOKEN_KIND_PHRASEPLUS);
        self._tokenKindTab[@"["] = @(TOKEN_KIND_OPEN_BRACKET);
        self._tokenKindTab[@","] = @(TOKEN_KIND_COMMA);
        self._tokenKindTab[@"SpecificChar"] = @(TOKEN_KIND_SPECIFICCHAR_TITLE);
        self._tokenKindTab[@"-"] = @(TOKEN_KIND_MINUS);
        self._tokenKindTab[@"Word"] = @(TOKEN_KIND_WORD_TITLE);
        self._tokenKindTab[@"Char"] = @(TOKEN_KIND_CHAR_TITLE);
        self._tokenKindTab[@"]"] = @(TOKEN_KIND_CLOSE_BRACKET);
        self._tokenKindTab[@"Digit"] = @(TOKEN_KIND_DIGIT_TITLE);
        self._tokenKindTab[@"%{"] = @(TOKEN_KIND_DELIMOPEN);

    }
	return self;
}


- (void)_start {
    
    do {
        [self statement]; 
    } while ((LA(1) == TOKEN_KIND_AT || LA(1) == TOKEN_KIND_BUILTIN_WORD) && ([self speculate:^{ [self statement]; }]));

    [self fireAssemblerSelector:@selector(parser:didMatch_start:)];
}

- (void)statement {
    
    if ([self speculate:^{ [self decl]; }]) {
        [self decl]; 
    } else if ([self speculate:^{ [self tokenizerDirective]; }]) {
        [self tokenizerDirective]; 
    } else {
        [self raise:@"no viable alternative found in statement"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchStatement:)];
}

- (void)tokenizerDirective {
    
    [self match:TOKEN_KIND_AT]; [self discard:1];
    if (LA(1) != TOKEN_KIND_START) {
        [self match:TOKEN_KIND_BUILTIN_ANY];
    } else {
        [self raise:@"negation test failed in tokenizerDirective"];
    }
    [self match:TOKEN_KIND_EQUALS]; 
    do {
        if (LA(1) == TOKEN_KIND_BUILTIN_WORD) {
            [self Word]; 
        } else if (LA(1) == TOKEN_KIND_BUILTIN_QUOTEDSTRING) {
            [self QuotedString]; 
        } else {
            [self raise:@"no viable alternative found in tokenizerDirective"];
        }
    } while (LA(1) == TOKEN_KIND_BUILTIN_QUOTEDSTRING || LA(1) == TOKEN_KIND_BUILTIN_WORD);
    [self match:TOKEN_KIND_SEMI_COLON]; [self discard:1];

    [self fireAssemblerSelector:@selector(parser:didMatchTokenizerDirective:)];
}

- (void)decl {
    
    [self production]; 
    [self match:TOKEN_KIND_EQUALS]; 
    if (LA(1) == TOKEN_KIND_ACTION) {
        [self action]; 
    }
    [self expr]; 
    [self match:TOKEN_KIND_SEMI_COLON]; [self discard:1];

    [self fireAssemblerSelector:@selector(parser:didMatchDecl:)];
}

- (void)production {
    
    if (LA(1) == TOKEN_KIND_AT) {
        [self startProduction]; 
    } else if (LA(1) == TOKEN_KIND_BUILTIN_WORD) {
        [self varProduction]; 
    } else {
        [self raise:@"no viable alternative found in production"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchProduction:)];
}

- (void)startProduction {
    
    [self match:TOKEN_KIND_AT]; [self discard:1];
    [self match:TOKEN_KIND_START]; [self discard:1];

    [self fireAssemblerSelector:@selector(parser:didMatchStartProduction:)];
}

- (void)varProduction {
    
    [self Word]; 

    [self fireAssemblerSelector:@selector(parser:didMatchVarProduction:)];
}

- (void)expr {
    
    [self term]; 
    while (LA(1) == TOKEN_KIND_PIPE) {
        if ([self speculate:^{ [self orTerm]; }]) {
            [self orTerm]; 
        } else {
            break;
        }
    }

    [self fireAssemblerSelector:@selector(parser:didMatchExpr:)];
}

- (void)term {
    
    if (LA(1) == TOKEN_KIND_SEMANTICPREDICATE) {
        [self semanticPredicate]; 
    }
    [self factor]; 
    while (LA(1) == TOKEN_KIND_ANY_TITLE || LA(1) == TOKEN_KIND_BUILTIN_QUOTEDSTRING || LA(1) == TOKEN_KIND_BUILTIN_WORD || LA(1) == TOKEN_KIND_CHAR_TITLE || LA(1) == TOKEN_KIND_COMMENT_TITLE || LA(1) == TOKEN_KIND_DELIMOPEN || LA(1) == TOKEN_KIND_DIGIT_TITLE || LA(1) == TOKEN_KIND_EMPTY_TITLE || LA(1) == TOKEN_KIND_LETTER_TITLE || LA(1) == TOKEN_KIND_NUMBER_TITLE || LA(1) == TOKEN_KIND_OPEN_BRACKET || LA(1) == TOKEN_KIND_OPEN_PAREN || LA(1) == TOKEN_KIND_PATTERNIGNORECASE || LA(1) == TOKEN_KIND_PATTERNNOOPTS || LA(1) == TOKEN_KIND_QUOTEDSTRING_TITLE || LA(1) == TOKEN_KIND_SPECIFICCHAR_TITLE || LA(1) == TOKEN_KIND_SYMBOL_TITLE || LA(1) == TOKEN_KIND_S_TITLE || LA(1) == TOKEN_KIND_TILDE || LA(1) == TOKEN_KIND_WORD_TITLE) {
        if ([self speculate:^{ [self nextFactor]; }]) {
            [self nextFactor]; 
        } else {
            break;
        }
    }

    [self fireAssemblerSelector:@selector(parser:didMatchTerm:)];
}

- (void)orTerm {
    
    [self match:TOKEN_KIND_PIPE]; 
    [self term]; 

    [self fireAssemblerSelector:@selector(parser:didMatchOrTerm:)];
}

- (void)factor {
    
    [self phrase]; 
    if (LA(1) == TOKEN_KIND_PHRASEPLUS || LA(1) == TOKEN_KIND_PHRASEQUESTION || LA(1) == TOKEN_KIND_PHRASESTAR) {
        if (LA(1) == TOKEN_KIND_PHRASESTAR) {
            [self phraseStar]; 
        } else if (LA(1) == TOKEN_KIND_PHRASEPLUS) {
            [self phrasePlus]; 
        } else if (LA(1) == TOKEN_KIND_PHRASEQUESTION) {
            [self phraseQuestion]; 
        } else {
            [self raise:@"no viable alternative found in factor"];
        }
    }
    if (LA(1) == TOKEN_KIND_ACTION) {
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
    while (LA(1) == TOKEN_KIND_AMPERSAND || LA(1) == TOKEN_KIND_MINUS) {
        if ([self speculate:^{ [self predicate]; }]) {
            [self predicate]; 
        } else {
            break;
        }
    }

    [self fireAssemblerSelector:@selector(parser:didMatchPhrase:)];
}

- (void)phraseStar {
    
    [self match:TOKEN_KIND_PHRASESTAR]; [self discard:1];

    [self fireAssemblerSelector:@selector(parser:didMatchPhraseStar:)];
}

- (void)phrasePlus {
    
    [self match:TOKEN_KIND_PHRASEPLUS]; [self discard:1];

    [self fireAssemblerSelector:@selector(parser:didMatchPhrasePlus:)];
}

- (void)phraseQuestion {
    
    [self match:TOKEN_KIND_PHRASEQUESTION]; [self discard:1];

    [self fireAssemblerSelector:@selector(parser:didMatchPhraseQuestion:)];
}

- (void)action {
    
    [self match:TOKEN_KIND_ACTION]; 

    [self fireAssemblerSelector:@selector(parser:didMatchAction:)];
}

- (void)semanticPredicate {
    
    [self match:TOKEN_KIND_SEMANTICPREDICATE]; 

    [self fireAssemblerSelector:@selector(parser:didMatchSemanticPredicate:)];
}

- (void)predicate {
    
    if (LA(1) == TOKEN_KIND_AMPERSAND) {
        [self intersection]; 
    } else if (LA(1) == TOKEN_KIND_MINUS) {
        [self difference]; 
    } else {
        [self raise:@"no viable alternative found in predicate"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchPredicate:)];
}

- (void)intersection {
    
    [self match:TOKEN_KIND_AMPERSAND]; [self discard:1];
    [self primaryExpr]; 

    [self fireAssemblerSelector:@selector(parser:didMatchIntersection:)];
}

- (void)difference {
    
    [self match:TOKEN_KIND_MINUS]; [self discard:1];
    [self primaryExpr]; 

    [self fireAssemblerSelector:@selector(parser:didMatchDifference:)];
}

- (void)primaryExpr {
    
    if (LA(1) == TOKEN_KIND_TILDE) {
        [self negatedPrimaryExpr]; 
    } else if (LA(1) == TOKEN_KIND_ANY_TITLE || LA(1) == TOKEN_KIND_BUILTIN_QUOTEDSTRING || LA(1) == TOKEN_KIND_BUILTIN_WORD || LA(1) == TOKEN_KIND_CHAR_TITLE || LA(1) == TOKEN_KIND_COMMENT_TITLE || LA(1) == TOKEN_KIND_DELIMOPEN || LA(1) == TOKEN_KIND_DIGIT_TITLE || LA(1) == TOKEN_KIND_EMPTY_TITLE || LA(1) == TOKEN_KIND_LETTER_TITLE || LA(1) == TOKEN_KIND_NUMBER_TITLE || LA(1) == TOKEN_KIND_OPEN_BRACKET || LA(1) == TOKEN_KIND_OPEN_PAREN || LA(1) == TOKEN_KIND_PATTERNIGNORECASE || LA(1) == TOKEN_KIND_PATTERNNOOPTS || LA(1) == TOKEN_KIND_QUOTEDSTRING_TITLE || LA(1) == TOKEN_KIND_SPECIFICCHAR_TITLE || LA(1) == TOKEN_KIND_SYMBOL_TITLE || LA(1) == TOKEN_KIND_S_TITLE || LA(1) == TOKEN_KIND_WORD_TITLE) {
        [self barePrimaryExpr]; 
    } else {
        [self raise:@"no viable alternative found in primaryExpr"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchPrimaryExpr:)];
}

- (void)negatedPrimaryExpr {
    
    [self match:TOKEN_KIND_TILDE]; [self discard:1];
    [self barePrimaryExpr]; 

    [self fireAssemblerSelector:@selector(parser:didMatchNegatedPrimaryExpr:)];
}

- (void)barePrimaryExpr {
    
    if (LA(1) == TOKEN_KIND_ANY_TITLE || LA(1) == TOKEN_KIND_BUILTIN_QUOTEDSTRING || LA(1) == TOKEN_KIND_BUILTIN_WORD || LA(1) == TOKEN_KIND_CHAR_TITLE || LA(1) == TOKEN_KIND_COMMENT_TITLE || LA(1) == TOKEN_KIND_DELIMOPEN || LA(1) == TOKEN_KIND_DIGIT_TITLE || LA(1) == TOKEN_KIND_EMPTY_TITLE || LA(1) == TOKEN_KIND_LETTER_TITLE || LA(1) == TOKEN_KIND_NUMBER_TITLE || LA(1) == TOKEN_KIND_PATTERNIGNORECASE || LA(1) == TOKEN_KIND_PATTERNNOOPTS || LA(1) == TOKEN_KIND_QUOTEDSTRING_TITLE || LA(1) == TOKEN_KIND_SPECIFICCHAR_TITLE || LA(1) == TOKEN_KIND_SYMBOL_TITLE || LA(1) == TOKEN_KIND_S_TITLE || LA(1) == TOKEN_KIND_WORD_TITLE) {
        [self atomicValue]; 
    } else if (LA(1) == TOKEN_KIND_OPEN_PAREN) {
        [self subSeqExpr]; 
    } else if (LA(1) == TOKEN_KIND_OPEN_BRACKET) {
        [self subTrackExpr]; 
    } else {
        [self raise:@"no viable alternative found in barePrimaryExpr"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchBarePrimaryExpr:)];
}

- (void)subSeqExpr {
    
    [self match:TOKEN_KIND_OPEN_PAREN]; 
    [self expr]; 
    [self match:TOKEN_KIND_CLOSE_PAREN]; [self discard:1];

    [self fireAssemblerSelector:@selector(parser:didMatchSubSeqExpr:)];
}

- (void)subTrackExpr {
    
    [self match:TOKEN_KIND_OPEN_BRACKET]; 
    [self expr]; 
    [self match:TOKEN_KIND_CLOSE_BRACKET]; [self discard:1];

    [self fireAssemblerSelector:@selector(parser:didMatchSubTrackExpr:)];
}

- (void)atomicValue {
    
    [self parser]; 
    if (LA(1) == TOKEN_KIND_DISCARD) {
        [self discard]; 
    }

    [self fireAssemblerSelector:@selector(parser:didMatchAtomicValue:)];
}

- (void)parser {
    
    if (LA(1) == TOKEN_KIND_BUILTIN_WORD) {
        [self variable]; 
    } else if (LA(1) == TOKEN_KIND_BUILTIN_QUOTEDSTRING) {
        [self literal]; 
    } else if (LA(1) == TOKEN_KIND_PATTERNIGNORECASE || LA(1) == TOKEN_KIND_PATTERNNOOPTS) {
        [self pattern]; 
    } else if (LA(1) == TOKEN_KIND_DELIMOPEN) {
        [self delimitedString]; 
    } else if (LA(1) == TOKEN_KIND_ANY_TITLE || LA(1) == TOKEN_KIND_CHAR_TITLE || LA(1) == TOKEN_KIND_COMMENT_TITLE || LA(1) == TOKEN_KIND_DIGIT_TITLE || LA(1) == TOKEN_KIND_EMPTY_TITLE || LA(1) == TOKEN_KIND_LETTER_TITLE || LA(1) == TOKEN_KIND_NUMBER_TITLE || LA(1) == TOKEN_KIND_QUOTEDSTRING_TITLE || LA(1) == TOKEN_KIND_SPECIFICCHAR_TITLE || LA(1) == TOKEN_KIND_SYMBOL_TITLE || LA(1) == TOKEN_KIND_S_TITLE || LA(1) == TOKEN_KIND_WORD_TITLE) {
        [self constant]; 
    } else {
        [self raise:@"no viable alternative found in parser"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchParser:)];
}

- (void)discard {
    
    [self match:TOKEN_KIND_DISCARD]; [self discard:1];

    [self fireAssemblerSelector:@selector(parser:didMatchDiscard:)];
}

- (void)pattern {
    
    if (LA(1) == TOKEN_KIND_PATTERNNOOPTS) {
        [self patternNoOpts]; 
    } else if (LA(1) == TOKEN_KIND_PATTERNIGNORECASE) {
        [self patternIgnoreCase]; 
    } else {
        [self raise:@"no viable alternative found in pattern"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchPattern:)];
}

- (void)patternNoOpts {
    
    [self match:TOKEN_KIND_PATTERNNOOPTS]; 

    [self fireAssemblerSelector:@selector(parser:didMatchPatternNoOpts:)];
}

- (void)patternIgnoreCase {
    
    [self match:TOKEN_KIND_PATTERNIGNORECASE]; 

    [self fireAssemblerSelector:@selector(parser:didMatchPatternIgnoreCase:)];
}

- (void)delimitedString {
    
    [self delimOpen]; 
    [self QuotedString]; 
    if ((LA(1) == TOKEN_KIND_COMMA) && ([self speculate:^{ [self match:TOKEN_KIND_COMMA]; [self discard:1];[self QuotedString]; }])) {
        [self match:TOKEN_KIND_COMMA]; [self discard:1];
        [self QuotedString]; 
    }
    [self match:TOKEN_KIND_CLOSE_CURLY]; [self discard:1];

    [self fireAssemblerSelector:@selector(parser:didMatchDelimitedString:)];
}

- (void)literal {
    
    [self QuotedString]; 

    [self fireAssemblerSelector:@selector(parser:didMatchLiteral:)];
}

- (void)constant {
    
    if (LA(1) == TOKEN_KIND_WORD_TITLE) {
        [self match:TOKEN_KIND_WORD_TITLE]; 
    } else if (LA(1) == TOKEN_KIND_NUMBER_TITLE) {
        [self match:TOKEN_KIND_NUMBER_TITLE]; 
    } else if (LA(1) == TOKEN_KIND_QUOTEDSTRING_TITLE) {
        [self match:TOKEN_KIND_QUOTEDSTRING_TITLE]; 
    } else if (LA(1) == TOKEN_KIND_SYMBOL_TITLE) {
        [self match:TOKEN_KIND_SYMBOL_TITLE]; 
    } else if (LA(1) == TOKEN_KIND_COMMENT_TITLE) {
        [self match:TOKEN_KIND_COMMENT_TITLE]; 
    } else if (LA(1) == TOKEN_KIND_EMPTY_TITLE) {
        [self match:TOKEN_KIND_EMPTY_TITLE]; 
    } else if (LA(1) == TOKEN_KIND_ANY_TITLE) {
        [self match:TOKEN_KIND_ANY_TITLE]; 
    } else if (LA(1) == TOKEN_KIND_S_TITLE) {
        [self match:TOKEN_KIND_S_TITLE]; 
    } else if (LA(1) == TOKEN_KIND_DIGIT_TITLE) {
        [self match:TOKEN_KIND_DIGIT_TITLE]; 
    } else if (LA(1) == TOKEN_KIND_LETTER_TITLE) {
        [self match:TOKEN_KIND_LETTER_TITLE]; 
    } else if (LA(1) == TOKEN_KIND_CHAR_TITLE) {
        [self match:TOKEN_KIND_CHAR_TITLE]; 
    } else if (LA(1) == TOKEN_KIND_SPECIFICCHAR_TITLE) {
        [self match:TOKEN_KIND_SPECIFICCHAR_TITLE]; 
    } else {
        [self raise:@"no viable alternative found in constant"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchConstant:)];
}

- (void)variable {
    
    [self Word]; 

    [self fireAssemblerSelector:@selector(parser:didMatchVariable:)];
}

- (void)delimOpen {
    
    [self match:TOKEN_KIND_DELIMOPEN]; 

    [self fireAssemblerSelector:@selector(parser:didMatchDelimOpen:)];
}

@end