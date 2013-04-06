#import "TDNSPredicateParser.h"
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

@interface TDNSPredicateParser ()
@property (nonatomic, retain) NSMutableDictionary *expr_memo;
@property (nonatomic, retain) NSMutableDictionary *orOrTerm_memo;
@property (nonatomic, retain) NSMutableDictionary *orTerm_memo;
@property (nonatomic, retain) NSMutableDictionary *andAndTerm_memo;
@property (nonatomic, retain) NSMutableDictionary *andTerm_memo;
@property (nonatomic, retain) NSMutableDictionary *compoundExpr_memo;
@property (nonatomic, retain) NSMutableDictionary *primaryExpr_memo;
@property (nonatomic, retain) NSMutableDictionary *negatedPredicate_memo;
@property (nonatomic, retain) NSMutableDictionary *predicate_memo;
@property (nonatomic, retain) NSMutableDictionary *value_memo;
@property (nonatomic, retain) NSMutableDictionary *string_memo;
@property (nonatomic, retain) NSMutableDictionary *num_memo;
@property (nonatomic, retain) NSMutableDictionary *bool_memo;
@property (nonatomic, retain) NSMutableDictionary *trueLiteral_memo;
@property (nonatomic, retain) NSMutableDictionary *falseLiteral_memo;
@property (nonatomic, retain) NSMutableDictionary *array_memo;
@property (nonatomic, retain) NSMutableDictionary *arrayContentsOpt_memo;
@property (nonatomic, retain) NSMutableDictionary *arrayContents_memo;
@property (nonatomic, retain) NSMutableDictionary *commaValue_memo;
@property (nonatomic, retain) NSMutableDictionary *keyPath_memo;
@property (nonatomic, retain) NSMutableDictionary *comparisonPredicate_memo;
@property (nonatomic, retain) NSMutableDictionary *numComparisonPredicate_memo;
@property (nonatomic, retain) NSMutableDictionary *numComparisonValue_memo;
@property (nonatomic, retain) NSMutableDictionary *comparisonOp_memo;
@property (nonatomic, retain) NSMutableDictionary *eq_memo;
@property (nonatomic, retain) NSMutableDictionary *gt_memo;
@property (nonatomic, retain) NSMutableDictionary *lt_memo;
@property (nonatomic, retain) NSMutableDictionary *gtEq_memo;
@property (nonatomic, retain) NSMutableDictionary *ltEq_memo;
@property (nonatomic, retain) NSMutableDictionary *notEq_memo;
@property (nonatomic, retain) NSMutableDictionary *between_memo;
@property (nonatomic, retain) NSMutableDictionary *collectionComparisonPredicate_memo;
@property (nonatomic, retain) NSMutableDictionary *collectionLtPredicate_memo;
@property (nonatomic, retain) NSMutableDictionary *collectionGtPredicate_memo;
@property (nonatomic, retain) NSMutableDictionary *collectionLtEqPredicate_memo;
@property (nonatomic, retain) NSMutableDictionary *collectionGtEqPredicate_memo;
@property (nonatomic, retain) NSMutableDictionary *collectionEqPredicate_memo;
@property (nonatomic, retain) NSMutableDictionary *collectionNotEqPredicate_memo;
@property (nonatomic, retain) NSMutableDictionary *boolPredicate_memo;
@property (nonatomic, retain) NSMutableDictionary *truePredicate_memo;
@property (nonatomic, retain) NSMutableDictionary *falsePredicate_memo;
@property (nonatomic, retain) NSMutableDictionary *and_memo;
@property (nonatomic, retain) NSMutableDictionary *or_memo;
@property (nonatomic, retain) NSMutableDictionary *not_memo;
@property (nonatomic, retain) NSMutableDictionary *stringTestPredicate_memo;
@property (nonatomic, retain) NSMutableDictionary *stringTestOp_memo;
@property (nonatomic, retain) NSMutableDictionary *beginswith_memo;
@property (nonatomic, retain) NSMutableDictionary *contains_memo;
@property (nonatomic, retain) NSMutableDictionary *endswith_memo;
@property (nonatomic, retain) NSMutableDictionary *like_memo;
@property (nonatomic, retain) NSMutableDictionary *matches_memo;
@property (nonatomic, retain) NSMutableDictionary *collectionTestPredicate_memo;
@property (nonatomic, retain) NSMutableDictionary *collection_memo;
@property (nonatomic, retain) NSMutableDictionary *in_memo;
@property (nonatomic, retain) NSMutableDictionary *aggregateOp_memo;
@property (nonatomic, retain) NSMutableDictionary *any_memo;
@property (nonatomic, retain) NSMutableDictionary *some_memo;
@property (nonatomic, retain) NSMutableDictionary *all_memo;
@property (nonatomic, retain) NSMutableDictionary *none_memo;
@end

@implementation TDNSPredicateParser

- (id)init {
	self = [super init];
	if (self) {
        self._tokenKindTab[@"ALL"] = @(TOKEN_KIND_ALL);
        self._tokenKindTab[@"FALSEPREDICATE"] = @(TOKEN_KIND_FALSEPREDICATE);
        self._tokenKindTab[@"NOT"] = @(TOKEN_KIND_NOT_UPPER);
        self._tokenKindTab[@"{"] = @(TOKEN_KIND_OPEN_CURLY);
        self._tokenKindTab[@"=>"] = @(TOKEN_KIND_HASH_ROCKET);
        self._tokenKindTab[@">="] = @(TOKEN_KIND_GE);
        self._tokenKindTab[@"&&"] = @(TOKEN_KIND_DOUBLE_AMPERSAND);
        self._tokenKindTab[@"TRUEPREDICATE"] = @(TOKEN_KIND_TRUEPREDICATE);
        self._tokenKindTab[@"AND"] = @(TOKEN_KIND_AND_UPPER);
        self._tokenKindTab[@"}"] = @(TOKEN_KIND_CLOSE_CURLY);
        self._tokenKindTab[@"true"] = @(TOKEN_KIND_TRUELITERAL);
        self._tokenKindTab[@"!="] = @(TOKEN_KIND_NE);
        self._tokenKindTab[@"OR"] = @(TOKEN_KIND_OR_UPPER);
        self._tokenKindTab[@"!"] = @(TOKEN_KIND_BANG);
        self._tokenKindTab[@"SOME"] = @(TOKEN_KIND_SOME);
        self._tokenKindTab[@"IN"] = @(TOKEN_KIND_IN);
        self._tokenKindTab[@"BEGINSWITH"] = @(TOKEN_KIND_BEGINSWITH);
        self._tokenKindTab[@"<"] = @(TOKEN_KIND_LT);
        self._tokenKindTab[@"="] = @(TOKEN_KIND_EQUALS);
        self._tokenKindTab[@"CONTAINS"] = @(TOKEN_KIND_CONTAINS);
        self._tokenKindTab[@">"] = @(TOKEN_KIND_GT);
        self._tokenKindTab[@"("] = @(TOKEN_KIND_OPEN_PAREN);
        self._tokenKindTab[@")"] = @(TOKEN_KIND_CLOSE_PAREN);
        self._tokenKindTab[@"||"] = @(TOKEN_KIND_DOUBLE_PIPE);
        self._tokenKindTab[@"MATCHES"] = @(TOKEN_KIND_MATCHES);
        self._tokenKindTab[@","] = @(TOKEN_KIND_COMMA);
        self._tokenKindTab[@"LIKE"] = @(TOKEN_KIND_LIKE);
        self._tokenKindTab[@"ANY"] = @(TOKEN_KIND_ANY);
        self._tokenKindTab[@"ENDSWITH"] = @(TOKEN_KIND_ENDSWITH);
        self._tokenKindTab[@"false"] = @(TOKEN_KIND_FALSELITERAL);
        self._tokenKindTab[@"<="] = @(TOKEN_KIND_LE);
        self._tokenKindTab[@"BETWEEN"] = @(TOKEN_KIND_BETWEEN);
        self._tokenKindTab[@"=<"] = @(TOKEN_KIND_EL);
        self._tokenKindTab[@"<>"] = @(TOKEN_KIND_NOT_EQUAL);
        self._tokenKindTab[@"NONE"] = @(TOKEN_KIND_NONE);
        self._tokenKindTab[@"=="] = @(TOKEN_KIND_DOUBLE_EQUALS);
    }
	return self;
}

- (void)dealloc {
    self.expr_memo = nil;
    self.orOrTerm_memo = nil;
    self.orTerm_memo = nil;
    self.andAndTerm_memo = nil;
    self.andTerm_memo = nil;
    self.compoundExpr_memo = nil;
    self.primaryExpr_memo = nil;
    self.negatedPredicate_memo = nil;
    self.predicate_memo = nil;
    self.value_memo = nil;
    self.string_memo = nil;
    self.num_memo = nil;
    self.bool_memo = nil;
    self.trueLiteral_memo = nil;
    self.falseLiteral_memo = nil;
    self.array_memo = nil;
    self.arrayContentsOpt_memo = nil;
    self.arrayContents_memo = nil;
    self.commaValue_memo = nil;
    self.keyPath_memo = nil;
    self.comparisonPredicate_memo = nil;
    self.numComparisonPredicate_memo = nil;
    self.numComparisonValue_memo = nil;
    self.comparisonOp_memo = nil;
    self.eq_memo = nil;
    self.gt_memo = nil;
    self.lt_memo = nil;
    self.gtEq_memo = nil;
    self.ltEq_memo = nil;
    self.notEq_memo = nil;
    self.between_memo = nil;
    self.collectionComparisonPredicate_memo = nil;
    self.collectionLtPredicate_memo = nil;
    self.collectionGtPredicate_memo = nil;
    self.collectionLtEqPredicate_memo = nil;
    self.collectionGtEqPredicate_memo = nil;
    self.collectionEqPredicate_memo = nil;
    self.collectionNotEqPredicate_memo = nil;
    self.boolPredicate_memo = nil;
    self.truePredicate_memo = nil;
    self.falsePredicate_memo = nil;
    self.and_memo = nil;
    self.or_memo = nil;
    self.not_memo = nil;
    self.stringTestPredicate_memo = nil;
    self.stringTestOp_memo = nil;
    self.beginswith_memo = nil;
    self.contains_memo = nil;
    self.endswith_memo = nil;
    self.like_memo = nil;
    self.matches_memo = nil;
    self.collectionTestPredicate_memo = nil;
    self.collection_memo = nil;
    self.in_memo = nil;
    self.aggregateOp_memo = nil;
    self.any_memo = nil;
    self.some_memo = nil;
    self.all_memo = nil;
    self.none_memo = nil;

    [super dealloc];
}

- (void)_clearMemo {
    [self.expr_memo removeAllObjects];
    [self.orOrTerm_memo removeAllObjects];
    [self.orTerm_memo removeAllObjects];
    [self.andAndTerm_memo removeAllObjects];
    [self.andTerm_memo removeAllObjects];
    [self.compoundExpr_memo removeAllObjects];
    [self.primaryExpr_memo removeAllObjects];
    [self.negatedPredicate_memo removeAllObjects];
    [self.predicate_memo removeAllObjects];
    [self.value_memo removeAllObjects];
    [self.string_memo removeAllObjects];
    [self.num_memo removeAllObjects];
    [self.bool_memo removeAllObjects];
    [self.trueLiteral_memo removeAllObjects];
    [self.falseLiteral_memo removeAllObjects];
    [self.array_memo removeAllObjects];
    [self.arrayContentsOpt_memo removeAllObjects];
    [self.arrayContents_memo removeAllObjects];
    [self.commaValue_memo removeAllObjects];
    [self.keyPath_memo removeAllObjects];
    [self.comparisonPredicate_memo removeAllObjects];
    [self.numComparisonPredicate_memo removeAllObjects];
    [self.numComparisonValue_memo removeAllObjects];
    [self.comparisonOp_memo removeAllObjects];
    [self.eq_memo removeAllObjects];
    [self.gt_memo removeAllObjects];
    [self.lt_memo removeAllObjects];
    [self.gtEq_memo removeAllObjects];
    [self.ltEq_memo removeAllObjects];
    [self.notEq_memo removeAllObjects];
    [self.between_memo removeAllObjects];
    [self.collectionComparisonPredicate_memo removeAllObjects];
    [self.collectionLtPredicate_memo removeAllObjects];
    [self.collectionGtPredicate_memo removeAllObjects];
    [self.collectionLtEqPredicate_memo removeAllObjects];
    [self.collectionGtEqPredicate_memo removeAllObjects];
    [self.collectionEqPredicate_memo removeAllObjects];
    [self.collectionNotEqPredicate_memo removeAllObjects];
    [self.boolPredicate_memo removeAllObjects];
    [self.truePredicate_memo removeAllObjects];
    [self.falsePredicate_memo removeAllObjects];
    [self.and_memo removeAllObjects];
    [self.or_memo removeAllObjects];
    [self.not_memo removeAllObjects];
    [self.stringTestPredicate_memo removeAllObjects];
    [self.stringTestOp_memo removeAllObjects];
    [self.beginswith_memo removeAllObjects];
    [self.contains_memo removeAllObjects];
    [self.endswith_memo removeAllObjects];
    [self.like_memo removeAllObjects];
    [self.matches_memo removeAllObjects];
    [self.collectionTestPredicate_memo removeAllObjects];
    [self.collection_memo removeAllObjects];
    [self.in_memo removeAllObjects];
    [self.aggregateOp_memo removeAllObjects];
    [self.any_memo removeAllObjects];
    [self.some_memo removeAllObjects];
    [self.all_memo removeAllObjects];
    [self.none_memo removeAllObjects];
}

- (void)_start {
    
    [self expr]; 

    [self fireAssemblerSelector:@selector(parser:didMatch_start:)];
}

- (void)__expr {
    
    [self orTerm]; 
    while (LA(1) == TOKEN_KIND_DOUBLE_PIPE || LA(1) == TOKEN_KIND_OR_UPPER) {
        if ([self speculate:^{ [self orOrTerm]; }]) {
            [self orOrTerm]; 
        } else {
            break;
        }
    }

    [self fireAssemblerSelector:@selector(parser:didMatchExpr:)];
}

- (void)expr {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.expr_memo]) return;
    @try {
        [self __expr];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.expr_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__orOrTerm {
    
    [self or]; 
    [self orTerm]; 

    [self fireAssemblerSelector:@selector(parser:didMatchOrOrTerm:)];
}

- (void)orOrTerm {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.orOrTerm_memo]) return;
    @try {
        [self __orOrTerm];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.orOrTerm_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__orTerm {
    
    [self andTerm]; 
    while (LA(1) == TOKEN_KIND_AND_UPPER || LA(1) == TOKEN_KIND_DOUBLE_AMPERSAND) {
        if ([self speculate:^{ [self andAndTerm]; }]) {
            [self andAndTerm]; 
        } else {
            break;
        }
    }

    [self fireAssemblerSelector:@selector(parser:didMatchOrTerm:)];
}

- (void)orTerm {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.orTerm_memo]) return;
    @try {
        [self __orTerm];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.orTerm_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__andAndTerm {
    
    [self and]; 
    [self andTerm]; 

    [self fireAssemblerSelector:@selector(parser:didMatchAndAndTerm:)];
}

- (void)andAndTerm {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.andAndTerm_memo]) return;
    @try {
        [self __andAndTerm];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.andAndTerm_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__andTerm {
    
    if (LA(1) == TOKEN_KIND_ALL || LA(1) == TOKEN_KIND_ANY || LA(1) == TOKEN_KIND_BANG || LA(1) == TOKEN_KIND_BUILTIN_NUMBER || LA(1) == TOKEN_KIND_BUILTIN_QUOTEDSTRING || LA(1) == TOKEN_KIND_BUILTIN_WORD || LA(1) == TOKEN_KIND_FALSELITERAL || LA(1) == TOKEN_KIND_FALSEPREDICATE || LA(1) == TOKEN_KIND_NONE || LA(1) == TOKEN_KIND_NOT_UPPER || LA(1) == TOKEN_KIND_OPEN_CURLY || LA(1) == TOKEN_KIND_SOME || LA(1) == TOKEN_KIND_TRUELITERAL || LA(1) == TOKEN_KIND_TRUEPREDICATE) {
        [self primaryExpr]; 
    } else if (LA(1) == TOKEN_KIND_OPEN_PAREN) {
        [self compoundExpr]; 
    } else {
        [self raise:@"no viable alternative found in andTerm"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchAndTerm:)];
}

- (void)andTerm {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.andTerm_memo]) return;
    @try {
        [self __andTerm];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.andTerm_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__compoundExpr {
    
    [self match:TOKEN_KIND_OPEN_PAREN]; [self discard:1];
    [self expr]; 
    [self match:TOKEN_KIND_CLOSE_PAREN]; [self discard:1];

    [self fireAssemblerSelector:@selector(parser:didMatchCompoundExpr:)];
}

- (void)compoundExpr {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.compoundExpr_memo]) return;
    @try {
        [self __compoundExpr];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.compoundExpr_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__primaryExpr {
    
    if (LA(1) == TOKEN_KIND_ALL || LA(1) == TOKEN_KIND_ANY || LA(1) == TOKEN_KIND_BUILTIN_NUMBER || LA(1) == TOKEN_KIND_BUILTIN_QUOTEDSTRING || LA(1) == TOKEN_KIND_BUILTIN_WORD || LA(1) == TOKEN_KIND_FALSELITERAL || LA(1) == TOKEN_KIND_FALSEPREDICATE || LA(1) == TOKEN_KIND_NONE || LA(1) == TOKEN_KIND_OPEN_CURLY || LA(1) == TOKEN_KIND_SOME || LA(1) == TOKEN_KIND_TRUELITERAL || LA(1) == TOKEN_KIND_TRUEPREDICATE) {
        [self predicate]; 
    } else if (LA(1) == TOKEN_KIND_BANG || LA(1) == TOKEN_KIND_NOT_UPPER) {
        [self negatedPredicate]; 
    } else {
        [self raise:@"no viable alternative found in primaryExpr"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchPrimaryExpr:)];
}

- (void)primaryExpr {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.primaryExpr_memo]) return;
    @try {
        [self __primaryExpr];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.primaryExpr_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__negatedPredicate {
    
    [self not]; 
    [self predicate]; 

    [self fireAssemblerSelector:@selector(parser:didMatchNegatedPredicate:)];
}

- (void)negatedPredicate {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.negatedPredicate_memo]) return;
    @try {
        [self __negatedPredicate];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.negatedPredicate_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__predicate {
    
    if ([self speculate:^{ [self boolPredicate]; }]) {
        [self boolPredicate]; 
    } else if ([self speculate:^{ [self comparisonPredicate]; }]) {
        [self comparisonPredicate]; 
    } else if ([self speculate:^{ [self stringTestPredicate]; }]) {
        [self stringTestPredicate]; 
    } else if ([self speculate:^{ [self collectionTestPredicate]; }]) {
        [self collectionTestPredicate]; 
    } else {
        [self raise:@"no viable alternative found in predicate"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchPredicate:)];
}

- (void)predicate {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.predicate_memo]) return;
    @try {
        [self __predicate];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.predicate_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__value {
    
    if (LA(1) == TOKEN_KIND_BUILTIN_WORD) {
        [self keyPath]; 
    } else if (LA(1) == TOKEN_KIND_BUILTIN_QUOTEDSTRING) {
        [self string]; 
    } else if (LA(1) == TOKEN_KIND_BUILTIN_NUMBER) {
        [self num]; 
    } else if (LA(1) == TOKEN_KIND_FALSELITERAL || LA(1) == TOKEN_KIND_TRUELITERAL) {
        [self bool]; 
    } else if (LA(1) == TOKEN_KIND_OPEN_CURLY) {
        [self array]; 
    } else {
        [self raise:@"no viable alternative found in value"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchValue:)];
}

- (void)value {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.value_memo]) return;
    @try {
        [self __value];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.value_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__string {
    
    [self QuotedString]; 

    [self fireAssemblerSelector:@selector(parser:didMatchString:)];
}

- (void)string {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.string_memo]) return;
    @try {
        [self __string];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.string_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__num {
    
    [self Number]; 

    [self fireAssemblerSelector:@selector(parser:didMatchNum:)];
}

- (void)num {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.num_memo]) return;
    @try {
        [self __num];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.num_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__bool {
    
    if (LA(1) == TOKEN_KIND_TRUELITERAL) {
        [self trueLiteral]; 
    } else if (LA(1) == TOKEN_KIND_FALSELITERAL) {
        [self falseLiteral]; 
    } else {
        [self raise:@"no viable alternative found in bool"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchBool:)];
}

- (void)bool {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.bool_memo]) return;
    @try {
        [self __bool];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.bool_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__trueLiteral {
    
    [self match:TOKEN_KIND_TRUELITERAL]; [self discard:1];

    [self fireAssemblerSelector:@selector(parser:didMatchTrueLiteral:)];
}

- (void)trueLiteral {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.trueLiteral_memo]) return;
    @try {
        [self __trueLiteral];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.trueLiteral_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__falseLiteral {
    
    [self match:TOKEN_KIND_FALSELITERAL]; [self discard:1];

    [self fireAssemblerSelector:@selector(parser:didMatchFalseLiteral:)];
}

- (void)falseLiteral {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.falseLiteral_memo]) return;
    @try {
        [self __falseLiteral];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.falseLiteral_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__array {
    
    [self match:TOKEN_KIND_OPEN_CURLY]; 
    [self arrayContentsOpt]; 
    [self match:TOKEN_KIND_CLOSE_CURLY]; [self discard:1];

    [self fireAssemblerSelector:@selector(parser:didMatchArray:)];
}

- (void)array {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.array_memo]) return;
    @try {
        [self __array];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.array_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__arrayContentsOpt {
    
    if (LA(1) == TOKEN_KIND_BUILTIN_NUMBER || LA(1) == TOKEN_KIND_BUILTIN_QUOTEDSTRING || LA(1) == TOKEN_KIND_BUILTIN_WORD || LA(1) == TOKEN_KIND_FALSELITERAL || LA(1) == TOKEN_KIND_OPEN_CURLY || LA(1) == TOKEN_KIND_TRUELITERAL) {
        [self arrayContents]; 
    }

    [self fireAssemblerSelector:@selector(parser:didMatchArrayContentsOpt:)];
}

- (void)arrayContentsOpt {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.arrayContentsOpt_memo]) return;
    @try {
        [self __arrayContentsOpt];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.arrayContentsOpt_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__arrayContents {
    
    [self value]; 
    while (LA(1) == TOKEN_KIND_COMMA) {
        if ([self speculate:^{ [self commaValue]; }]) {
            [self commaValue]; 
        } else {
            break;
        }
    }

    [self fireAssemblerSelector:@selector(parser:didMatchArrayContents:)];
}

- (void)arrayContents {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.arrayContents_memo]) return;
    @try {
        [self __arrayContents];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.arrayContents_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__commaValue {
    
    [self match:TOKEN_KIND_COMMA]; [self discard:1];
    [self value]; 

    [self fireAssemblerSelector:@selector(parser:didMatchCommaValue:)];
}

- (void)commaValue {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.commaValue_memo]) return;
    @try {
        [self __commaValue];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.commaValue_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__keyPath {
    
    [self Word]; 

    [self fireAssemblerSelector:@selector(parser:didMatchKeyPath:)];
}

- (void)keyPath {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.keyPath_memo]) return;
    @try {
        [self __keyPath];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.keyPath_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__comparisonPredicate {
    
    if (LA(1) == TOKEN_KIND_BUILTIN_NUMBER || LA(1) == TOKEN_KIND_BUILTIN_WORD) {
        [self numComparisonPredicate]; 
    } else if (LA(1) == TOKEN_KIND_ALL || LA(1) == TOKEN_KIND_ANY || LA(1) == TOKEN_KIND_NONE || LA(1) == TOKEN_KIND_SOME) {
        [self collectionComparisonPredicate]; 
    } else {
        [self raise:@"no viable alternative found in comparisonPredicate"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchComparisonPredicate:)];
}

- (void)comparisonPredicate {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.comparisonPredicate_memo]) return;
    @try {
        [self __comparisonPredicate];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.comparisonPredicate_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__numComparisonPredicate {
    
    [self numComparisonValue]; 
    [self comparisonOp]; 
    [self numComparisonValue]; 

    [self fireAssemblerSelector:@selector(parser:didMatchNumComparisonPredicate:)];
}

- (void)numComparisonPredicate {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.numComparisonPredicate_memo]) return;
    @try {
        [self __numComparisonPredicate];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.numComparisonPredicate_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__numComparisonValue {
    
    if (LA(1) == TOKEN_KIND_BUILTIN_WORD) {
        [self keyPath]; 
    } else if (LA(1) == TOKEN_KIND_BUILTIN_NUMBER) {
        [self num]; 
    } else {
        [self raise:@"no viable alternative found in numComparisonValue"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchNumComparisonValue:)];
}

- (void)numComparisonValue {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.numComparisonValue_memo]) return;
    @try {
        [self __numComparisonValue];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.numComparisonValue_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__comparisonOp {
    
    if (LA(1) == TOKEN_KIND_DOUBLE_EQUALS || LA(1) == TOKEN_KIND_EQUALS) {
        [self eq]; 
    } else if (LA(1) == TOKEN_KIND_GT) {
        [self gt]; 
    } else if (LA(1) == TOKEN_KIND_LT) {
        [self lt]; 
    } else if (LA(1) == TOKEN_KIND_GE || LA(1) == TOKEN_KIND_HASH_ROCKET) {
        [self gtEq]; 
    } else if (LA(1) == TOKEN_KIND_EL || LA(1) == TOKEN_KIND_LE) {
        [self ltEq]; 
    } else if (LA(1) == TOKEN_KIND_NE || LA(1) == TOKEN_KIND_NOT_EQUAL) {
        [self notEq]; 
    } else if (LA(1) == TOKEN_KIND_BETWEEN) {
        [self between]; 
    } else {
        [self raise:@"no viable alternative found in comparisonOp"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchComparisonOp:)];
}

- (void)comparisonOp {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.comparisonOp_memo]) return;
    @try {
        [self __comparisonOp];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.comparisonOp_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__eq {
    
    if (LA(1) == TOKEN_KIND_EQUALS) {
        [self match:TOKEN_KIND_EQUALS]; 
    } else if (LA(1) == TOKEN_KIND_DOUBLE_EQUALS) {
        [self match:TOKEN_KIND_DOUBLE_EQUALS]; 
    } else {
        [self raise:@"no viable alternative found in eq"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchEq:)];
}

- (void)eq {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.eq_memo]) return;
    @try {
        [self __eq];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.eq_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__gt {
    
    [self match:TOKEN_KIND_GT]; 

    [self fireAssemblerSelector:@selector(parser:didMatchGt:)];
}

- (void)gt {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.gt_memo]) return;
    @try {
        [self __gt];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.gt_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__lt {
    
    [self match:TOKEN_KIND_LT]; 

    [self fireAssemblerSelector:@selector(parser:didMatchLt:)];
}

- (void)lt {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.lt_memo]) return;
    @try {
        [self __lt];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.lt_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__gtEq {
    
    if (LA(1) == TOKEN_KIND_GE) {
        [self match:TOKEN_KIND_GE]; 
    } else if (LA(1) == TOKEN_KIND_HASH_ROCKET) {
        [self match:TOKEN_KIND_HASH_ROCKET]; 
    } else {
        [self raise:@"no viable alternative found in gtEq"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchGtEq:)];
}

- (void)gtEq {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.gtEq_memo]) return;
    @try {
        [self __gtEq];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.gtEq_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__ltEq {
    
    if (LA(1) == TOKEN_KIND_LE) {
        [self match:TOKEN_KIND_LE]; 
    } else if (LA(1) == TOKEN_KIND_EL) {
        [self match:TOKEN_KIND_EL]; 
    } else {
        [self raise:@"no viable alternative found in ltEq"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchLtEq:)];
}

- (void)ltEq {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.ltEq_memo]) return;
    @try {
        [self __ltEq];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.ltEq_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__notEq {
    
    if (LA(1) == TOKEN_KIND_NE) {
        [self match:TOKEN_KIND_NE]; 
    } else if (LA(1) == TOKEN_KIND_NOT_EQUAL) {
        [self match:TOKEN_KIND_NOT_EQUAL]; 
    } else {
        [self raise:@"no viable alternative found in notEq"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchNotEq:)];
}

- (void)notEq {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.notEq_memo]) return;
    @try {
        [self __notEq];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.notEq_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__between {
    
    [self match:TOKEN_KIND_BETWEEN]; 

    [self fireAssemblerSelector:@selector(parser:didMatchBetween:)];
}

- (void)between {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.between_memo]) return;
    @try {
        [self __between];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.between_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__collectionComparisonPredicate {
    
    if ([self speculate:^{ [self collectionLtPredicate]; }]) {
        [self collectionLtPredicate]; 
    } else if ([self speculate:^{ [self collectionGtPredicate]; }]) {
        [self collectionGtPredicate]; 
    } else if ([self speculate:^{ [self collectionLtEqPredicate]; }]) {
        [self collectionLtEqPredicate]; 
    } else if ([self speculate:^{ [self collectionGtEqPredicate]; }]) {
        [self collectionGtEqPredicate]; 
    } else if ([self speculate:^{ [self collectionEqPredicate]; }]) {
        [self collectionEqPredicate]; 
    } else if ([self speculate:^{ [self collectionNotEqPredicate]; }]) {
        [self collectionNotEqPredicate]; 
    } else {
        [self raise:@"no viable alternative found in collectionComparisonPredicate"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchCollectionComparisonPredicate:)];
}

- (void)collectionComparisonPredicate {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.collectionComparisonPredicate_memo]) return;
    @try {
        [self __collectionComparisonPredicate];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.collectionComparisonPredicate_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__collectionLtPredicate {
    
    [self aggregateOp]; 
    [self collection]; 
    [self lt]; 
    [self value]; 

    [self fireAssemblerSelector:@selector(parser:didMatchCollectionLtPredicate:)];
}

- (void)collectionLtPredicate {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.collectionLtPredicate_memo]) return;
    @try {
        [self __collectionLtPredicate];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.collectionLtPredicate_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__collectionGtPredicate {
    
    [self aggregateOp]; 
    [self collection]; 
    [self gt]; 
    [self value]; 

    [self fireAssemblerSelector:@selector(parser:didMatchCollectionGtPredicate:)];
}

- (void)collectionGtPredicate {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.collectionGtPredicate_memo]) return;
    @try {
        [self __collectionGtPredicate];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.collectionGtPredicate_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__collectionLtEqPredicate {
    
    [self aggregateOp]; 
    [self collection]; 
    [self ltEq]; 
    [self value]; 

    [self fireAssemblerSelector:@selector(parser:didMatchCollectionLtEqPredicate:)];
}

- (void)collectionLtEqPredicate {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.collectionLtEqPredicate_memo]) return;
    @try {
        [self __collectionLtEqPredicate];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.collectionLtEqPredicate_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__collectionGtEqPredicate {
    
    [self aggregateOp]; 
    [self collection]; 
    [self gtEq]; 
    [self value]; 

    [self fireAssemblerSelector:@selector(parser:didMatchCollectionGtEqPredicate:)];
}

- (void)collectionGtEqPredicate {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.collectionGtEqPredicate_memo]) return;
    @try {
        [self __collectionGtEqPredicate];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.collectionGtEqPredicate_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__collectionEqPredicate {
    
    [self aggregateOp]; 
    [self collection]; 
    [self eq]; 
    [self value]; 

    [self fireAssemblerSelector:@selector(parser:didMatchCollectionEqPredicate:)];
}

- (void)collectionEqPredicate {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.collectionEqPredicate_memo]) return;
    @try {
        [self __collectionEqPredicate];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.collectionEqPredicate_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__collectionNotEqPredicate {
    
    [self aggregateOp]; 
    [self collection]; 
    [self notEq]; 
    [self value]; 

    [self fireAssemblerSelector:@selector(parser:didMatchCollectionNotEqPredicate:)];
}

- (void)collectionNotEqPredicate {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.collectionNotEqPredicate_memo]) return;
    @try {
        [self __collectionNotEqPredicate];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.collectionNotEqPredicate_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__boolPredicate {
    
    if (LA(1) == TOKEN_KIND_TRUEPREDICATE) {
        [self truePredicate]; 
    } else if (LA(1) == TOKEN_KIND_FALSEPREDICATE) {
        [self falsePredicate]; 
    } else {
        [self raise:@"no viable alternative found in boolPredicate"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchBoolPredicate:)];
}

- (void)boolPredicate {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.boolPredicate_memo]) return;
    @try {
        [self __boolPredicate];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.boolPredicate_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__truePredicate {
    
    [self match:TOKEN_KIND_TRUEPREDICATE]; [self discard:1];

    [self fireAssemblerSelector:@selector(parser:didMatchTruePredicate:)];
}

- (void)truePredicate {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.truePredicate_memo]) return;
    @try {
        [self __truePredicate];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.truePredicate_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__falsePredicate {
    
    [self match:TOKEN_KIND_FALSEPREDICATE]; [self discard:1];

    [self fireAssemblerSelector:@selector(parser:didMatchFalsePredicate:)];
}

- (void)falsePredicate {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.falsePredicate_memo]) return;
    @try {
        [self __falsePredicate];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.falsePredicate_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__and {
    
    if (LA(1) == TOKEN_KIND_AND_UPPER) {
        [self match:TOKEN_KIND_AND_UPPER]; [self discard:1];
    } else if (LA(1) == TOKEN_KIND_DOUBLE_AMPERSAND) {
        [self match:TOKEN_KIND_DOUBLE_AMPERSAND]; [self discard:1];
    } else {
        [self raise:@"no viable alternative found in and"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchAnd:)];
}

- (void)and {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.and_memo]) return;
    @try {
        [self __and];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.and_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__or {
    
    if (LA(1) == TOKEN_KIND_OR_UPPER) {
        [self match:TOKEN_KIND_OR_UPPER]; [self discard:1];
    } else if (LA(1) == TOKEN_KIND_DOUBLE_PIPE) {
        [self match:TOKEN_KIND_DOUBLE_PIPE]; [self discard:1];
    } else {
        [self raise:@"no viable alternative found in or"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchOr:)];
}

- (void)or {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.or_memo]) return;
    @try {
        [self __or];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.or_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__not {
    
    if (LA(1) == TOKEN_KIND_NOT_UPPER) {
        [self match:TOKEN_KIND_NOT_UPPER]; [self discard:1];
    } else if (LA(1) == TOKEN_KIND_BANG) {
        [self match:TOKEN_KIND_BANG]; [self discard:1];
    } else {
        [self raise:@"no viable alternative found in not"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchNot:)];
}

- (void)not {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.not_memo]) return;
    @try {
        [self __not];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.not_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__stringTestPredicate {
    
    [self string]; 
    [self stringTestOp]; 
    [self value]; 

    [self fireAssemblerSelector:@selector(parser:didMatchStringTestPredicate:)];
}

- (void)stringTestPredicate {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.stringTestPredicate_memo]) return;
    @try {
        [self __stringTestPredicate];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.stringTestPredicate_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__stringTestOp {
    
    if (LA(1) == TOKEN_KIND_BEGINSWITH) {
        [self beginswith]; 
    } else if (LA(1) == TOKEN_KIND_CONTAINS) {
        [self contains]; 
    } else if (LA(1) == TOKEN_KIND_ENDSWITH) {
        [self endswith]; 
    } else if (LA(1) == TOKEN_KIND_LIKE) {
        [self like]; 
    } else if (LA(1) == TOKEN_KIND_MATCHES) {
        [self matches]; 
    } else {
        [self raise:@"no viable alternative found in stringTestOp"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchStringTestOp:)];
}

- (void)stringTestOp {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.stringTestOp_memo]) return;
    @try {
        [self __stringTestOp];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.stringTestOp_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__beginswith {
    
    [self match:TOKEN_KIND_BEGINSWITH]; 

    [self fireAssemblerSelector:@selector(parser:didMatchBeginswith:)];
}

- (void)beginswith {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.beginswith_memo]) return;
    @try {
        [self __beginswith];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.beginswith_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__contains {
    
    [self match:TOKEN_KIND_CONTAINS]; 

    [self fireAssemblerSelector:@selector(parser:didMatchContains:)];
}

- (void)contains {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.contains_memo]) return;
    @try {
        [self __contains];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.contains_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__endswith {
    
    [self match:TOKEN_KIND_ENDSWITH]; 

    [self fireAssemblerSelector:@selector(parser:didMatchEndswith:)];
}

- (void)endswith {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.endswith_memo]) return;
    @try {
        [self __endswith];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.endswith_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__like {
    
    [self match:TOKEN_KIND_LIKE]; 

    [self fireAssemblerSelector:@selector(parser:didMatchLike:)];
}

- (void)like {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.like_memo]) return;
    @try {
        [self __like];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.like_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__matches {
    
    [self match:TOKEN_KIND_MATCHES]; 

    [self fireAssemblerSelector:@selector(parser:didMatchMatches:)];
}

- (void)matches {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.matches_memo]) return;
    @try {
        [self __matches];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.matches_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__collectionTestPredicate {
    
    [self value]; 
    [self in]; 
    [self collection]; 

    [self fireAssemblerSelector:@selector(parser:didMatchCollectionTestPredicate:)];
}

- (void)collectionTestPredicate {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.collectionTestPredicate_memo]) return;
    @try {
        [self __collectionTestPredicate];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.collectionTestPredicate_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__collection {
    
    if (LA(1) == TOKEN_KIND_BUILTIN_WORD) {
        [self keyPath]; 
    } else if (LA(1) == TOKEN_KIND_OPEN_CURLY) {
        [self array]; 
    } else {
        [self raise:@"no viable alternative found in collection"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchCollection:)];
}

- (void)collection {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.collection_memo]) return;
    @try {
        [self __collection];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.collection_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__in {
    
    [self match:TOKEN_KIND_IN]; [self discard:1];

    [self fireAssemblerSelector:@selector(parser:didMatchIn:)];
}

- (void)in {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.in_memo]) return;
    @try {
        [self __in];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.in_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__aggregateOp {
    
    if (LA(1) == TOKEN_KIND_ANY) {
        [self any]; 
    } else if (LA(1) == TOKEN_KIND_SOME) {
        [self some]; 
    } else if (LA(1) == TOKEN_KIND_ALL) {
        [self all]; 
    } else if (LA(1) == TOKEN_KIND_NONE) {
        [self none]; 
    } else {
        [self raise:@"no viable alternative found in aggregateOp"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchAggregateOp:)];
}

- (void)aggregateOp {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.aggregateOp_memo]) return;
    @try {
        [self __aggregateOp];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.aggregateOp_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__any {
    
    [self match:TOKEN_KIND_ANY]; 

    [self fireAssemblerSelector:@selector(parser:didMatchAny:)];
}

- (void)any {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.any_memo]) return;
    @try {
        [self __any];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.any_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__some {
    
    [self match:TOKEN_KIND_SOME]; 

    [self fireAssemblerSelector:@selector(parser:didMatchSome:)];
}

- (void)some {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.some_memo]) return;
    @try {
        [self __some];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.some_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__all {
    
    [self match:TOKEN_KIND_ALL]; 

    [self fireAssemblerSelector:@selector(parser:didMatchAll:)];
}

- (void)all {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.all_memo]) return;
    @try {
        [self __all];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.all_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__none {
    
    [self match:TOKEN_KIND_NONE]; 

    [self fireAssemblerSelector:@selector(parser:didMatchNone:)];
}

- (void)none {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.none_memo]) return;
    @try {
        [self __none];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.none_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

@end