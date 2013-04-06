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

@interface ParseKitParser ()
@property (nonatomic, retain) NSMutableDictionary *statement_memo;
@property (nonatomic, retain) NSMutableDictionary *tokenizerDirective_memo;
@property (nonatomic, retain) NSMutableDictionary *decl_memo;
@property (nonatomic, retain) NSMutableDictionary *production_memo;
@property (nonatomic, retain) NSMutableDictionary *startProduction_memo;
@property (nonatomic, retain) NSMutableDictionary *varProduction_memo;
@property (nonatomic, retain) NSMutableDictionary *expr_memo;
@property (nonatomic, retain) NSMutableDictionary *term_memo;
@property (nonatomic, retain) NSMutableDictionary *orTerm_memo;
@property (nonatomic, retain) NSMutableDictionary *factor_memo;
@property (nonatomic, retain) NSMutableDictionary *nextFactor_memo;
@property (nonatomic, retain) NSMutableDictionary *phrase_memo;
@property (nonatomic, retain) NSMutableDictionary *phraseStar_memo;
@property (nonatomic, retain) NSMutableDictionary *phrasePlus_memo;
@property (nonatomic, retain) NSMutableDictionary *phraseQuestion_memo;
@property (nonatomic, retain) NSMutableDictionary *action_memo;
@property (nonatomic, retain) NSMutableDictionary *semanticPredicate_memo;
@property (nonatomic, retain) NSMutableDictionary *predicate_memo;
@property (nonatomic, retain) NSMutableDictionary *intersection_memo;
@property (nonatomic, retain) NSMutableDictionary *difference_memo;
@property (nonatomic, retain) NSMutableDictionary *primaryExpr_memo;
@property (nonatomic, retain) NSMutableDictionary *negatedPrimaryExpr_memo;
@property (nonatomic, retain) NSMutableDictionary *barePrimaryExpr_memo;
@property (nonatomic, retain) NSMutableDictionary *subSeqExpr_memo;
@property (nonatomic, retain) NSMutableDictionary *subTrackExpr_memo;
@property (nonatomic, retain) NSMutableDictionary *atomicValue_memo;
@property (nonatomic, retain) NSMutableDictionary *parser_memo;
@property (nonatomic, retain) NSMutableDictionary *discard_memo;
@property (nonatomic, retain) NSMutableDictionary *pattern_memo;
@property (nonatomic, retain) NSMutableDictionary *patternNoOpts_memo;
@property (nonatomic, retain) NSMutableDictionary *patternIgnoreCase_memo;
@property (nonatomic, retain) NSMutableDictionary *delimitedString_memo;
@property (nonatomic, retain) NSMutableDictionary *literal_memo;
@property (nonatomic, retain) NSMutableDictionary *constant_memo;
@property (nonatomic, retain) NSMutableDictionary *variable_memo;
@property (nonatomic, retain) NSMutableDictionary *delimOpen_memo;
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

        self.statement_memo = [NSMutableDictionary dictionary];
        self.tokenizerDirective_memo = [NSMutableDictionary dictionary];
        self.decl_memo = [NSMutableDictionary dictionary];
        self.production_memo = [NSMutableDictionary dictionary];
        self.startProduction_memo = [NSMutableDictionary dictionary];
        self.varProduction_memo = [NSMutableDictionary dictionary];
        self.expr_memo = [NSMutableDictionary dictionary];
        self.term_memo = [NSMutableDictionary dictionary];
        self.orTerm_memo = [NSMutableDictionary dictionary];
        self.factor_memo = [NSMutableDictionary dictionary];
        self.nextFactor_memo = [NSMutableDictionary dictionary];
        self.phrase_memo = [NSMutableDictionary dictionary];
        self.phraseStar_memo = [NSMutableDictionary dictionary];
        self.phrasePlus_memo = [NSMutableDictionary dictionary];
        self.phraseQuestion_memo = [NSMutableDictionary dictionary];
        self.action_memo = [NSMutableDictionary dictionary];
        self.semanticPredicate_memo = [NSMutableDictionary dictionary];
        self.predicate_memo = [NSMutableDictionary dictionary];
        self.intersection_memo = [NSMutableDictionary dictionary];
        self.difference_memo = [NSMutableDictionary dictionary];
        self.primaryExpr_memo = [NSMutableDictionary dictionary];
        self.negatedPrimaryExpr_memo = [NSMutableDictionary dictionary];
        self.barePrimaryExpr_memo = [NSMutableDictionary dictionary];
        self.subSeqExpr_memo = [NSMutableDictionary dictionary];
        self.subTrackExpr_memo = [NSMutableDictionary dictionary];
        self.atomicValue_memo = [NSMutableDictionary dictionary];
        self.parser_memo = [NSMutableDictionary dictionary];
        self.discard_memo = [NSMutableDictionary dictionary];
        self.pattern_memo = [NSMutableDictionary dictionary];
        self.patternNoOpts_memo = [NSMutableDictionary dictionary];
        self.patternIgnoreCase_memo = [NSMutableDictionary dictionary];
        self.delimitedString_memo = [NSMutableDictionary dictionary];
        self.literal_memo = [NSMutableDictionary dictionary];
        self.constant_memo = [NSMutableDictionary dictionary];
        self.variable_memo = [NSMutableDictionary dictionary];
        self.delimOpen_memo = [NSMutableDictionary dictionary];
    }
	return self;
}

- (void)dealloc {
    self.statement_memo = nil;
    self.tokenizerDirective_memo = nil;
    self.decl_memo = nil;
    self.production_memo = nil;
    self.startProduction_memo = nil;
    self.varProduction_memo = nil;
    self.expr_memo = nil;
    self.term_memo = nil;
    self.orTerm_memo = nil;
    self.factor_memo = nil;
    self.nextFactor_memo = nil;
    self.phrase_memo = nil;
    self.phraseStar_memo = nil;
    self.phrasePlus_memo = nil;
    self.phraseQuestion_memo = nil;
    self.action_memo = nil;
    self.semanticPredicate_memo = nil;
    self.predicate_memo = nil;
    self.intersection_memo = nil;
    self.difference_memo = nil;
    self.primaryExpr_memo = nil;
    self.negatedPrimaryExpr_memo = nil;
    self.barePrimaryExpr_memo = nil;
    self.subSeqExpr_memo = nil;
    self.subTrackExpr_memo = nil;
    self.atomicValue_memo = nil;
    self.parser_memo = nil;
    self.discard_memo = nil;
    self.pattern_memo = nil;
    self.patternNoOpts_memo = nil;
    self.patternIgnoreCase_memo = nil;
    self.delimitedString_memo = nil;
    self.literal_memo = nil;
    self.constant_memo = nil;
    self.variable_memo = nil;
    self.delimOpen_memo = nil;

    [super dealloc];
}

- (void)_clearMemo {
    [_statement_memo removeAllObjects];
    [_tokenizerDirective_memo removeAllObjects];
    [_decl_memo removeAllObjects];
    [_production_memo removeAllObjects];
    [_startProduction_memo removeAllObjects];
    [_varProduction_memo removeAllObjects];
    [_expr_memo removeAllObjects];
    [_term_memo removeAllObjects];
    [_orTerm_memo removeAllObjects];
    [_factor_memo removeAllObjects];
    [_nextFactor_memo removeAllObjects];
    [_phrase_memo removeAllObjects];
    [_phraseStar_memo removeAllObjects];
    [_phrasePlus_memo removeAllObjects];
    [_phraseQuestion_memo removeAllObjects];
    [_action_memo removeAllObjects];
    [_semanticPredicate_memo removeAllObjects];
    [_predicate_memo removeAllObjects];
    [_intersection_memo removeAllObjects];
    [_difference_memo removeAllObjects];
    [_primaryExpr_memo removeAllObjects];
    [_negatedPrimaryExpr_memo removeAllObjects];
    [_barePrimaryExpr_memo removeAllObjects];
    [_subSeqExpr_memo removeAllObjects];
    [_subTrackExpr_memo removeAllObjects];
    [_atomicValue_memo removeAllObjects];
    [_parser_memo removeAllObjects];
    [_discard_memo removeAllObjects];
    [_pattern_memo removeAllObjects];
    [_patternNoOpts_memo removeAllObjects];
    [_patternIgnoreCase_memo removeAllObjects];
    [_delimitedString_memo removeAllObjects];
    [_literal_memo removeAllObjects];
    [_constant_memo removeAllObjects];
    [_variable_memo removeAllObjects];
    [_delimOpen_memo removeAllObjects];
}

- (void)_start {
    
    do {
        [self statement]; 
    } while ((LA(1) == TOKEN_KIND_AT || LA(1) == TOKEN_KIND_BUILTIN_WORD) && ([self speculate:^{ [self statement]; }]));

    [self fireAssemblerSelector:@selector(parser:didMatch_start:)];
}

- (void)__statement {
    
    if ([self speculate:^{ [self decl]; }]) {
        [self decl]; 
    } else if ([self speculate:^{ [self tokenizerDirective]; }]) {
        [self tokenizerDirective]; 
    } else {
        [self raise:@"no viable alternative found in statement"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchStatement:)];
}

- (void)statement {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:_statement_memo]) return;
    @try {
        [self __statement];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:_statement_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__tokenizerDirective {
    
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

- (void)tokenizerDirective {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:_tokenizerDirective_memo]) return;
    @try {
        [self __tokenizerDirective];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:_tokenizerDirective_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__decl {
    
    [self production]; 
    [self match:TOKEN_KIND_EQUALS]; 
    if (LA(1) == TOKEN_KIND_ACTION) {
        [self action]; 
    }
    [self expr]; 
    [self match:TOKEN_KIND_SEMI_COLON]; [self discard:1];

    [self fireAssemblerSelector:@selector(parser:didMatchDecl:)];
}

- (void)decl {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:_decl_memo]) return;
    @try {
        [self __decl];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:_decl_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__production {
    
    if (LA(1) == TOKEN_KIND_AT) {
        [self startProduction]; 
    } else if (LA(1) == TOKEN_KIND_BUILTIN_WORD) {
        [self varProduction]; 
    } else {
        [self raise:@"no viable alternative found in production"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchProduction:)];
}

- (void)production {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:_production_memo]) return;
    @try {
        [self __production];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:_production_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__startProduction {
    
    [self match:TOKEN_KIND_AT]; [self discard:1];
    [self match:TOKEN_KIND_START]; [self discard:1];

    [self fireAssemblerSelector:@selector(parser:didMatchStartProduction:)];
}

- (void)startProduction {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:_startProduction_memo]) return;
    @try {
        [self __startProduction];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:_startProduction_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__varProduction {
    
    [self Word]; 

    [self fireAssemblerSelector:@selector(parser:didMatchVarProduction:)];
}

- (void)varProduction {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:_varProduction_memo]) return;
    @try {
        [self __varProduction];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:_varProduction_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__expr {
    
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

- (void)expr {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:_expr_memo]) return;
    @try {
        [self __expr];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:_expr_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__term {
    
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

- (void)term {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:_term_memo]) return;
    @try {
        [self __term];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:_term_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__orTerm {
    
    [self match:TOKEN_KIND_PIPE]; 
    [self term]; 

    [self fireAssemblerSelector:@selector(parser:didMatchOrTerm:)];
}

- (void)orTerm {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:_orTerm_memo]) return;
    @try {
        [self __orTerm];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:_orTerm_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__factor {
    
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

- (void)factor {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:_factor_memo]) return;
    @try {
        [self __factor];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:_factor_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__nextFactor {
    
    [self factor]; 

    [self fireAssemblerSelector:@selector(parser:didMatchNextFactor:)];
}

- (void)nextFactor {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:_nextFactor_memo]) return;
    @try {
        [self __nextFactor];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:_nextFactor_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__phrase {
    
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

- (void)phrase {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:_phrase_memo]) return;
    @try {
        [self __phrase];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:_phrase_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__phraseStar {
    
    [self match:TOKEN_KIND_PHRASESTAR]; [self discard:1];

    [self fireAssemblerSelector:@selector(parser:didMatchPhraseStar:)];
}

- (void)phraseStar {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:_phraseStar_memo]) return;
    @try {
        [self __phraseStar];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:_phraseStar_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__phrasePlus {
    
    [self match:TOKEN_KIND_PHRASEPLUS]; [self discard:1];

    [self fireAssemblerSelector:@selector(parser:didMatchPhrasePlus:)];
}

- (void)phrasePlus {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:_phrasePlus_memo]) return;
    @try {
        [self __phrasePlus];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:_phrasePlus_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__phraseQuestion {
    
    [self match:TOKEN_KIND_PHRASEQUESTION]; [self discard:1];

    [self fireAssemblerSelector:@selector(parser:didMatchPhraseQuestion:)];
}

- (void)phraseQuestion {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:_phraseQuestion_memo]) return;
    @try {
        [self __phraseQuestion];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:_phraseQuestion_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__action {
    
    [self match:TOKEN_KIND_ACTION]; 

    [self fireAssemblerSelector:@selector(parser:didMatchAction:)];
}

- (void)action {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:_action_memo]) return;
    @try {
        [self __action];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:_action_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__semanticPredicate {
    
    [self match:TOKEN_KIND_SEMANTICPREDICATE]; 

    [self fireAssemblerSelector:@selector(parser:didMatchSemanticPredicate:)];
}

- (void)semanticPredicate {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:_semanticPredicate_memo]) return;
    @try {
        [self __semanticPredicate];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:_semanticPredicate_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__predicate {
    
    if (LA(1) == TOKEN_KIND_AMPERSAND) {
        [self intersection]; 
    } else if (LA(1) == TOKEN_KIND_MINUS) {
        [self difference]; 
    } else {
        [self raise:@"no viable alternative found in predicate"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchPredicate:)];
}

- (void)predicate {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:_predicate_memo]) return;
    @try {
        [self __predicate];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:_predicate_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__intersection {
    
    [self match:TOKEN_KIND_AMPERSAND]; [self discard:1];
    [self primaryExpr]; 

    [self fireAssemblerSelector:@selector(parser:didMatchIntersection:)];
}

- (void)intersection {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:_intersection_memo]) return;
    @try {
        [self __intersection];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:_intersection_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__difference {
    
    [self match:TOKEN_KIND_MINUS]; [self discard:1];
    [self primaryExpr]; 

    [self fireAssemblerSelector:@selector(parser:didMatchDifference:)];
}

- (void)difference {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:_difference_memo]) return;
    @try {
        [self __difference];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:_difference_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__primaryExpr {
    
    if (LA(1) == TOKEN_KIND_TILDE) {
        [self negatedPrimaryExpr]; 
    } else if (LA(1) == TOKEN_KIND_ANY_TITLE || LA(1) == TOKEN_KIND_BUILTIN_QUOTEDSTRING || LA(1) == TOKEN_KIND_BUILTIN_WORD || LA(1) == TOKEN_KIND_CHAR_TITLE || LA(1) == TOKEN_KIND_COMMENT_TITLE || LA(1) == TOKEN_KIND_DELIMOPEN || LA(1) == TOKEN_KIND_DIGIT_TITLE || LA(1) == TOKEN_KIND_EMPTY_TITLE || LA(1) == TOKEN_KIND_LETTER_TITLE || LA(1) == TOKEN_KIND_NUMBER_TITLE || LA(1) == TOKEN_KIND_OPEN_BRACKET || LA(1) == TOKEN_KIND_OPEN_PAREN || LA(1) == TOKEN_KIND_PATTERNIGNORECASE || LA(1) == TOKEN_KIND_PATTERNNOOPTS || LA(1) == TOKEN_KIND_QUOTEDSTRING_TITLE || LA(1) == TOKEN_KIND_SPECIFICCHAR_TITLE || LA(1) == TOKEN_KIND_SYMBOL_TITLE || LA(1) == TOKEN_KIND_S_TITLE || LA(1) == TOKEN_KIND_WORD_TITLE) {
        [self barePrimaryExpr]; 
    } else {
        [self raise:@"no viable alternative found in primaryExpr"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchPrimaryExpr:)];
}

- (void)primaryExpr {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:_primaryExpr_memo]) return;
    @try {
        [self __primaryExpr];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:_primaryExpr_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__negatedPrimaryExpr {
    
    [self match:TOKEN_KIND_TILDE]; [self discard:1];
    [self barePrimaryExpr]; 

    [self fireAssemblerSelector:@selector(parser:didMatchNegatedPrimaryExpr:)];
}

- (void)negatedPrimaryExpr {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:_negatedPrimaryExpr_memo]) return;
    @try {
        [self __negatedPrimaryExpr];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:_negatedPrimaryExpr_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__barePrimaryExpr {
    
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

- (void)barePrimaryExpr {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:_barePrimaryExpr_memo]) return;
    @try {
        [self __barePrimaryExpr];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:_barePrimaryExpr_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__subSeqExpr {
    
    [self match:TOKEN_KIND_OPEN_PAREN]; 
    [self expr]; 
    [self match:TOKEN_KIND_CLOSE_PAREN]; [self discard:1];

    [self fireAssemblerSelector:@selector(parser:didMatchSubSeqExpr:)];
}

- (void)subSeqExpr {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:_subSeqExpr_memo]) return;
    @try {
        [self __subSeqExpr];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:_subSeqExpr_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__subTrackExpr {
    
    [self match:TOKEN_KIND_OPEN_BRACKET]; 
    [self expr]; 
    [self match:TOKEN_KIND_CLOSE_BRACKET]; [self discard:1];

    [self fireAssemblerSelector:@selector(parser:didMatchSubTrackExpr:)];
}

- (void)subTrackExpr {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:_subTrackExpr_memo]) return;
    @try {
        [self __subTrackExpr];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:_subTrackExpr_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__atomicValue {
    
    [self parser]; 
    if (LA(1) == TOKEN_KIND_DISCARD) {
        [self discard]; 
    }

    [self fireAssemblerSelector:@selector(parser:didMatchAtomicValue:)];
}

- (void)atomicValue {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:_atomicValue_memo]) return;
    @try {
        [self __atomicValue];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:_atomicValue_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__parser {
    
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

- (void)parser {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:_parser_memo]) return;
    @try {
        [self __parser];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:_parser_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__discard {
    
    [self match:TOKEN_KIND_DISCARD]; [self discard:1];

    [self fireAssemblerSelector:@selector(parser:didMatchDiscard:)];
}

- (void)discard {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:_discard_memo]) return;
    @try {
        [self __discard];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:_discard_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__pattern {
    
    if (LA(1) == TOKEN_KIND_PATTERNNOOPTS) {
        [self patternNoOpts]; 
    } else if (LA(1) == TOKEN_KIND_PATTERNIGNORECASE) {
        [self patternIgnoreCase]; 
    } else {
        [self raise:@"no viable alternative found in pattern"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchPattern:)];
}

- (void)pattern {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:_pattern_memo]) return;
    @try {
        [self __pattern];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:_pattern_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__patternNoOpts {
    
    [self match:TOKEN_KIND_PATTERNNOOPTS]; 

    [self fireAssemblerSelector:@selector(parser:didMatchPatternNoOpts:)];
}

- (void)patternNoOpts {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:_patternNoOpts_memo]) return;
    @try {
        [self __patternNoOpts];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:_patternNoOpts_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__patternIgnoreCase {
    
    [self match:TOKEN_KIND_PATTERNIGNORECASE]; 

    [self fireAssemblerSelector:@selector(parser:didMatchPatternIgnoreCase:)];
}

- (void)patternIgnoreCase {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:_patternIgnoreCase_memo]) return;
    @try {
        [self __patternIgnoreCase];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:_patternIgnoreCase_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__delimitedString {
    
    [self delimOpen]; 
    [self QuotedString]; 
    if ((LA(1) == TOKEN_KIND_COMMA) && ([self speculate:^{ [self match:TOKEN_KIND_COMMA]; [self discard:1];[self QuotedString]; }])) {
        [self match:TOKEN_KIND_COMMA]; [self discard:1];
        [self QuotedString]; 
    }
    [self match:TOKEN_KIND_CLOSE_CURLY]; [self discard:1];

    [self fireAssemblerSelector:@selector(parser:didMatchDelimitedString:)];
}

- (void)delimitedString {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:_delimitedString_memo]) return;
    @try {
        [self __delimitedString];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:_delimitedString_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__literal {
    
    [self QuotedString]; 

    [self fireAssemblerSelector:@selector(parser:didMatchLiteral:)];
}

- (void)literal {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:_literal_memo]) return;
    @try {
        [self __literal];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:_literal_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__constant {
    
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

- (void)constant {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:_constant_memo]) return;
    @try {
        [self __constant];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:_constant_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__variable {
    
    [self Word]; 

    [self fireAssemblerSelector:@selector(parser:didMatchVariable:)];
}

- (void)variable {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:_variable_memo]) return;
    @try {
        [self __variable];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:_variable_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__delimOpen {
    
    [self match:TOKEN_KIND_DELIMOPEN]; 

    [self fireAssemblerSelector:@selector(parser:didMatchDelimOpen:)];
}

- (void)delimOpen {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:_delimOpen_memo]) return;
    @try {
        [self __delimOpen];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:_delimOpen_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

@end