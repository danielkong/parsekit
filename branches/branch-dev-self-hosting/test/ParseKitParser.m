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
@end

@implementation ParseKitParser

- (id)init {
	self = [super init];
	if (self) {
        self._tokenKindTab[@"*"] = @(TOKEN_KIND_STAR);
        self._tokenKindTab[@"start"] = @(TOKEN_KIND_START);
        self._tokenKindTab[@"}"] = @(TOKEN_KIND_CLOSE_CURLY);
        self._tokenKindTab[@"+"] = @(TOKEN_KIND_PLUS);
        self._tokenKindTab[@"%{"] = @(TOKEN_KIND_DELIMOPEN);
        self._tokenKindTab[@";"] = @(TOKEN_KIND_SEMI_COLON);
        self._tokenKindTab[@","] = @(TOKEN_KIND_COMMA);
        self._tokenKindTab[@"-"] = @(TOKEN_KIND_MINUS);
        self._tokenKindTab[@"["] = @(TOKEN_KIND_OPEN_BRACKET);
        self._tokenKindTab[@"="] = @(TOKEN_KIND_EQUALS);
        self._tokenKindTab[@"&"] = @(TOKEN_KIND_AMPERSAND);
        self._tokenKindTab[@"]"] = @(TOKEN_KIND_CLOSE_BRACKET);
        self._tokenKindTab[@"|"] = @(TOKEN_KIND_PIPE);
        self._tokenKindTab[@"("] = @(TOKEN_KIND_OPEN_PAREN);
        self._tokenKindTab[@"?"] = @(TOKEN_KIND_QUESTION);
        self._tokenKindTab[@"!"] = @(TOKEN_KIND_DISCARD);
        self._tokenKindTab[@"@"] = @(TOKEN_KIND_AT);
        self._tokenKindTab[@")"] = @(TOKEN_KIND_CLOSE_PAREN);
        self._tokenKindTab[@"~"] = @(TOKEN_KIND_TILDE);
        self._tokenKindTab[@"{,}?"] = @(TOKEN_KIND_SEMANTICPREDICATE);
        self._tokenKindTab[@"{,}"] = @(TOKEN_KIND_ACTION);
        self._tokenKindTab[@"/,/"] = @(TOKEN_KIND_PATTERN);
        self._tokenKindTab[@"/,/i"] = @(TOKEN_KIND_PATTERN);
	}
	return self;
}

- (void)dealloc {
	[super dealloc];
}


- (void)_start {
    
        do {
            [self statement];
        } while (LA(1) == TOKEN_KIND_AT || (LA(1) == TOKEN_KIND_BUILTIN_WORD && islower([LS(1) characterAtIndex:0])));

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
    if (![self speculate:^{ [self match:TOKEN_KIND_START]; }]) {
        [self match:TOKEN_KIND_BUILTIN_ANY];
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
        if ((LA(1) == TOKEN_KIND_ACTION) && ([self speculate:^{ [self action]; }])) {
            [self action]; 
        }
        [self expr]; 
        [self match:TOKEN_KIND_SEMI_COLON]; [self discard:1];

    [self fireAssemblerSelector:@selector(parser:didMatchDecl:)];
}

- (void)production {
    
        if (LA(1) == TOKEN_KIND_AT) {
            [self startProduction]; 
        } else if ((LA(1) == TOKEN_KIND_BUILTIN_WORD && islower([LS(1) characterAtIndex:0]))) {
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
    
        [self LowercaseWord]; 

    [self fireAssemblerSelector:@selector(parser:didMatchVarProduction:)];
}

- (void)expr {
    
        [self term]; 
        while (LA(1) == TOKEN_KIND_PIPE) {
            if ([self speculate:^{ [self orTerm]; }]) {
                [self orTerm]; 
            } else {
                return;
            }
        }

    [self fireAssemblerSelector:@selector(parser:didMatchExpr:)];
}

- (void)term {
    
        if ((LA(1) == TOKEN_KIND_SEMANTICPREDICATE && [LS(1) hasPrefix:@"{"]) && ([self speculate:^{ [self semanticPredicate]; }])) {
            [self semanticPredicate]; 
        }
        [self factor]; 
        while (LA(1) == TOKEN_KIND_BUILTIN_WORD || LA(1) == TOKEN_KIND_DELIMOPEN || LA(1) == TOKEN_KIND_OPEN_BRACKET || LA(1) == TOKEN_KIND_BUILTIN_QUOTEDSTRING || LA(1) == TOKEN_KIND_TILDE || LA(1) == TOKEN_KIND_OPEN_PAREN) {
            if ([self speculate:^{ [self nextFactor]; }]) {
                [self nextFactor]; 
            } else {
                return;
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
    
        if ([self speculate:^{ [self phraseStar]; }]) {
            [self phraseStar]; 
        } else if ([self speculate:^{ [self phrasePlus]; }]) {
            [self phrasePlus]; 
        } else if ([self speculate:^{ [self phraseQuestion]; }]) {
            [self phraseQuestion];
        } else if ([self speculate:^{ [self phrase]; }]) {
            [self phrase];
        } else {
            [self raise:@"no viable alternative found in factor"];
        }
        if ((LA(1) == TOKEN_KIND_ACTION) && ([self speculate:^{ [self action]; }])) {
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
        while (LA(1) == TOKEN_KIND_MINUS || LA(1) == TOKEN_KIND_AMPERSAND) {
            if ([self speculate:^{ [self predicate]; }]) {
                [self predicate]; 
            } else {
                return;
            }
        }

    [self fireAssemblerSelector:@selector(parser:didMatchPhrase:)];
}

- (void)phraseStar {
    
        [self phrase]; 
        [self match:TOKEN_KIND_STAR]; [self discard:1];

    [self fireAssemblerSelector:@selector(parser:didMatchPhraseStar:)];
}

- (void)phrasePlus {
    
        [self phrase]; 
        [self match:TOKEN_KIND_PLUS]; [self discard:1];

    [self fireAssemblerSelector:@selector(parser:didMatchPhrasePlus:)];
}

- (void)phraseQuestion {
    
        [self phrase]; 
        [self match:TOKEN_KIND_QUESTION]; [self discard:1];

    [self fireAssemblerSelector:@selector(parser:didMatchPhraseQuestion:)];
}

- (void)action {
    
        if (LA(1) == TOKEN_KIND_ACTION && [LS(1) hasPrefix:@"{"] && [LS(1) hasSuffix:@"}"]) {
            [self match:TOKEN_KIND_ACTION];
        }

    [self fireAssemblerSelector:@selector(parser:didMatchAction:)];
}

- (void)semanticPredicate {
    
        if (LA(1) == TOKEN_KIND_SEMANTICPREDICATE && [LS(1) hasPrefix:@"{"] && [LS(1) hasSuffix:@"}?"]) {
            [self match:TOKEN_KIND_SEMANTICPREDICATE];
        }

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
        } else if (LA(1) == TOKEN_KIND_PATTERN || LA(1) == TOKEN_KIND_OPEN_PAREN || LA(1) == TOKEN_KIND_BUILTIN_WORD || LA(1) == TOKEN_KIND_OPEN_BRACKET || LA(1) == TOKEN_KIND_DELIMOPEN || LA(1) == TOKEN_KIND_BUILTIN_QUOTEDSTRING) {
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
    
        if (LA(1) == TOKEN_KIND_PATTERN ||LA(1) == TOKEN_KIND_BUILTIN_QUOTEDSTRING || LA(1) == TOKEN_KIND_DELIMOPEN || LA(1) == TOKEN_KIND_BUILTIN_WORD) {
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
        if ((LA(1) == TOKEN_KIND_DISCARD) && ([self speculate:^{ [self discard]; }])) {
            [self discard]; 
        }

    [self fireAssemblerSelector:@selector(parser:didMatchAtomicValue:)];
}

- (void)parser {
    
        if (LA(1) == TOKEN_KIND_PATTERN) {
            [self pattern]; 
        } else if (LA(1) == TOKEN_KIND_BUILTIN_QUOTEDSTRING) {
            [self literal]; 
        } else if ((LA(1) == TOKEN_KIND_BUILTIN_WORD && islower([LS(1) characterAtIndex:0]))) {
            [self variable]; 
        } else if ((LA(1) == TOKEN_KIND_BUILTIN_WORD && isupper([LS(1) characterAtIndex:0]))) {
            [self constant]; 
        } else if (LA(1) == TOKEN_KIND_DELIMOPEN) {
            [self delimitedString];
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
    
        if (LA(1) == TOKEN_KIND_PATTERN && [LS(1) hasPrefix:@"/"] && [LS(1) hasSuffix:@"/"]) {
            [self match:TOKEN_KIND_PATTERN];
        } else if (LA(1) == TOKEN_KIND_PATTERN && [LS(1) hasPrefix:@"/"] && [LS(1) hasSuffix:@"/i"]) {
            [self match:TOKEN_KIND_PATTERN];
        }


    [self fireAssemblerSelector:@selector(parser:didMatchPattern:)];
}

- (void)delimitedString {
    
        [self delimOpen]; 
        [self QuotedString]; 
        if ((LA(1) == TOKEN_KIND_COMMA) && ([self speculate:^{ [self match:TOKEN_KIND_COMMA]; [self QuotedString]; }])) {
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

- (void)variable {
    
        [self LowercaseWord]; 

    [self fireAssemblerSelector:@selector(parser:didMatchVariable:)];
}

- (void)constant {
    
        [self UppercaseWord]; 

    [self fireAssemblerSelector:@selector(parser:didMatchConstant:)];
}

- (void)delimOpen {
    
        [self match:TOKEN_KIND_DELIMOPEN]; 

    [self fireAssemblerSelector:@selector(parser:didMatchDelimOpen:)];
}

@synthesize _tokenKindTab = _tokenKindTab;
@end
