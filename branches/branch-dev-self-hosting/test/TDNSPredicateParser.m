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

- (BOOL)_popBool;
- (NSInteger)_popInteger;
- (double)_popDouble;
- (PKToken *)_popToken;
- (NSString *)_popString;

- (void)_pushBool:(BOOL)yn;
- (void)_pushInteger:(NSInteger)i;
- (void)_pushDouble:(double)d;
@end

@interface TDNSPredicateParser ()
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


- (void)_start {
    
    [self expr]; 

    [self fireAssemblerSelector:@selector(parser:didMatch_start:)];
}

- (void)expr {
    
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

- (void)orOrTerm {
    
    [self or]; 
    [self orTerm]; 

    [self fireAssemblerSelector:@selector(parser:didMatchOrOrTerm:)];
}

- (void)orTerm {
    
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

- (void)andAndTerm {
    
    [self and]; 
    [self andTerm]; 

    [self fireAssemblerSelector:@selector(parser:didMatchAndAndTerm:)];
}

- (void)andTerm {
    
    if (LA(1) == TOKEN_KIND_ALL || LA(1) == TOKEN_KIND_ANY || LA(1) == TOKEN_KIND_BANG || LA(1) == TOKEN_KIND_BUILTIN_NUMBER || LA(1) == TOKEN_KIND_BUILTIN_QUOTEDSTRING || LA(1) == TOKEN_KIND_BUILTIN_WORD || LA(1) == TOKEN_KIND_FALSELITERAL || LA(1) == TOKEN_KIND_FALSEPREDICATE || LA(1) == TOKEN_KIND_NONE || LA(1) == TOKEN_KIND_NOT_UPPER || LA(1) == TOKEN_KIND_OPEN_CURLY || LA(1) == TOKEN_KIND_SOME || LA(1) == TOKEN_KIND_TRUELITERAL || LA(1) == TOKEN_KIND_TRUEPREDICATE) {
        [self primaryExpr]; 
    } else if (LA(1) == TOKEN_KIND_OPEN_PAREN) {
        [self compoundExpr]; 
    } else {
        [self raise:@"no viable alternative found in andTerm"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchAndTerm:)];
}

- (void)compoundExpr {
    
    [self match:TOKEN_KIND_OPEN_PAREN]; [self discard:1];
    [self expr]; 
    [self match:TOKEN_KIND_CLOSE_PAREN]; [self discard:1];

    [self fireAssemblerSelector:@selector(parser:didMatchCompoundExpr:)];
}

- (void)primaryExpr {
    
    if (LA(1) == TOKEN_KIND_ALL || LA(1) == TOKEN_KIND_ANY || LA(1) == TOKEN_KIND_BUILTIN_NUMBER || LA(1) == TOKEN_KIND_BUILTIN_QUOTEDSTRING || LA(1) == TOKEN_KIND_BUILTIN_WORD || LA(1) == TOKEN_KIND_FALSELITERAL || LA(1) == TOKEN_KIND_FALSEPREDICATE || LA(1) == TOKEN_KIND_NONE || LA(1) == TOKEN_KIND_OPEN_CURLY || LA(1) == TOKEN_KIND_SOME || LA(1) == TOKEN_KIND_TRUELITERAL || LA(1) == TOKEN_KIND_TRUEPREDICATE) {
        [self predicate]; 
    } else if (LA(1) == TOKEN_KIND_BANG || LA(1) == TOKEN_KIND_NOT_UPPER) {
        [self negatedPredicate]; 
    } else {
        [self raise:@"no viable alternative found in primaryExpr"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchPrimaryExpr:)];
}

- (void)negatedPredicate {
    
    [self not]; 
    [self predicate]; 

    [self fireAssemblerSelector:@selector(parser:didMatchNegatedPredicate:)];
}

- (void)predicate {
    
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

- (void)value {
    
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

- (void)string {
    
    [self QuotedString]; 

    [self fireAssemblerSelector:@selector(parser:didMatchString:)];
}

- (void)num {
    
    [self Number]; 

    [self fireAssemblerSelector:@selector(parser:didMatchNum:)];
}

- (void)bool {
    
    if (LA(1) == TOKEN_KIND_TRUELITERAL) {
        [self trueLiteral]; 
    } else if (LA(1) == TOKEN_KIND_FALSELITERAL) {
        [self falseLiteral]; 
    } else {
        [self raise:@"no viable alternative found in bool"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchBool:)];
}

- (void)trueLiteral {
    
    [self match:TOKEN_KIND_TRUELITERAL]; [self discard:1];

    [self fireAssemblerSelector:@selector(parser:didMatchTrueLiteral:)];
}

- (void)falseLiteral {
    
    [self match:TOKEN_KIND_FALSELITERAL]; [self discard:1];

    [self fireAssemblerSelector:@selector(parser:didMatchFalseLiteral:)];
}

- (void)array {
    
    [self match:TOKEN_KIND_OPEN_CURLY]; 
    [self arrayContentsOpt]; 
    [self match:TOKEN_KIND_CLOSE_CURLY]; [self discard:1];

    [self fireAssemblerSelector:@selector(parser:didMatchArray:)];
}

- (void)arrayContentsOpt {
    
    if (LA(1) == TOKEN_KIND_BUILTIN_NUMBER || LA(1) == TOKEN_KIND_BUILTIN_QUOTEDSTRING || LA(1) == TOKEN_KIND_BUILTIN_WORD || LA(1) == TOKEN_KIND_FALSELITERAL || LA(1) == TOKEN_KIND_OPEN_CURLY || LA(1) == TOKEN_KIND_TRUELITERAL) {
        [self arrayContents]; 
    }

    [self fireAssemblerSelector:@selector(parser:didMatchArrayContentsOpt:)];
}

- (void)arrayContents {
    
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

- (void)commaValue {
    
    [self match:TOKEN_KIND_COMMA]; [self discard:1];
    [self value]; 

    [self fireAssemblerSelector:@selector(parser:didMatchCommaValue:)];
}

- (void)keyPath {
    
    [self Word]; 

    [self fireAssemblerSelector:@selector(parser:didMatchKeyPath:)];
}

- (void)comparisonPredicate {
    
    if (LA(1) == TOKEN_KIND_BUILTIN_NUMBER || LA(1) == TOKEN_KIND_BUILTIN_WORD) {
        [self numComparisonPredicate]; 
    } else if (LA(1) == TOKEN_KIND_ALL || LA(1) == TOKEN_KIND_ANY || LA(1) == TOKEN_KIND_NONE || LA(1) == TOKEN_KIND_SOME) {
        [self collectionComparisonPredicate]; 
    } else {
        [self raise:@"no viable alternative found in comparisonPredicate"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchComparisonPredicate:)];
}

- (void)numComparisonPredicate {
    
    [self numComparisonValue]; 
    [self comparisonOp]; 
    [self numComparisonValue]; 

    [self fireAssemblerSelector:@selector(parser:didMatchNumComparisonPredicate:)];
}

- (void)numComparisonValue {
    
    if (LA(1) == TOKEN_KIND_BUILTIN_WORD) {
        [self keyPath]; 
    } else if (LA(1) == TOKEN_KIND_BUILTIN_NUMBER) {
        [self num]; 
    } else {
        [self raise:@"no viable alternative found in numComparisonValue"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchNumComparisonValue:)];
}

- (void)comparisonOp {
    
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

- (void)eq {
    
    if (LA(1) == TOKEN_KIND_EQUALS) {
        [self match:TOKEN_KIND_EQUALS]; 
    } else if (LA(1) == TOKEN_KIND_DOUBLE_EQUALS) {
        [self match:TOKEN_KIND_DOUBLE_EQUALS]; 
    } else {
        [self raise:@"no viable alternative found in eq"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchEq:)];
}

- (void)gt {
    
    [self match:TOKEN_KIND_GT]; 

    [self fireAssemblerSelector:@selector(parser:didMatchGt:)];
}

- (void)lt {
    
    [self match:TOKEN_KIND_LT]; 

    [self fireAssemblerSelector:@selector(parser:didMatchLt:)];
}

- (void)gtEq {
    
    if (LA(1) == TOKEN_KIND_GE) {
        [self match:TOKEN_KIND_GE]; 
    } else if (LA(1) == TOKEN_KIND_HASH_ROCKET) {
        [self match:TOKEN_KIND_HASH_ROCKET]; 
    } else {
        [self raise:@"no viable alternative found in gtEq"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchGtEq:)];
}

- (void)ltEq {
    
    if (LA(1) == TOKEN_KIND_LE) {
        [self match:TOKEN_KIND_LE]; 
    } else if (LA(1) == TOKEN_KIND_EL) {
        [self match:TOKEN_KIND_EL]; 
    } else {
        [self raise:@"no viable alternative found in ltEq"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchLtEq:)];
}

- (void)notEq {
    
    if (LA(1) == TOKEN_KIND_NE) {
        [self match:TOKEN_KIND_NE]; 
    } else if (LA(1) == TOKEN_KIND_NOT_EQUAL) {
        [self match:TOKEN_KIND_NOT_EQUAL]; 
    } else {
        [self raise:@"no viable alternative found in notEq"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchNotEq:)];
}

- (void)between {
    
    [self match:TOKEN_KIND_BETWEEN]; 

    [self fireAssemblerSelector:@selector(parser:didMatchBetween:)];
}

- (void)collectionComparisonPredicate {
    
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

- (void)collectionLtPredicate {
    
    [self aggregateOp]; 
    [self collection]; 
    [self lt]; 
    [self value]; 

    [self fireAssemblerSelector:@selector(parser:didMatchCollectionLtPredicate:)];
}

- (void)collectionGtPredicate {
    
    [self aggregateOp]; 
    [self collection]; 
    [self gt]; 
    [self value]; 

    [self fireAssemblerSelector:@selector(parser:didMatchCollectionGtPredicate:)];
}

- (void)collectionLtEqPredicate {
    
    [self aggregateOp]; 
    [self collection]; 
    [self ltEq]; 
    [self value]; 

    [self fireAssemblerSelector:@selector(parser:didMatchCollectionLtEqPredicate:)];
}

- (void)collectionGtEqPredicate {
    
    [self aggregateOp]; 
    [self collection]; 
    [self gtEq]; 
    [self value]; 

    [self fireAssemblerSelector:@selector(parser:didMatchCollectionGtEqPredicate:)];
}

- (void)collectionEqPredicate {
    
    [self aggregateOp]; 
    [self collection]; 
    [self eq]; 
    [self value]; 

    [self fireAssemblerSelector:@selector(parser:didMatchCollectionEqPredicate:)];
}

- (void)collectionNotEqPredicate {
    
    [self aggregateOp]; 
    [self collection]; 
    [self notEq]; 
    [self value]; 

    [self fireAssemblerSelector:@selector(parser:didMatchCollectionNotEqPredicate:)];
}

- (void)boolPredicate {
    
    if (LA(1) == TOKEN_KIND_TRUEPREDICATE) {
        [self truePredicate]; 
    } else if (LA(1) == TOKEN_KIND_FALSEPREDICATE) {
        [self falsePredicate]; 
    } else {
        [self raise:@"no viable alternative found in boolPredicate"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchBoolPredicate:)];
}

- (void)truePredicate {
    
    [self match:TOKEN_KIND_TRUEPREDICATE]; [self discard:1];

    [self fireAssemblerSelector:@selector(parser:didMatchTruePredicate:)];
}

- (void)falsePredicate {
    
    [self match:TOKEN_KIND_FALSEPREDICATE]; [self discard:1];

    [self fireAssemblerSelector:@selector(parser:didMatchFalsePredicate:)];
}

- (void)and {
    
    if (LA(1) == TOKEN_KIND_AND_UPPER) {
        [self match:TOKEN_KIND_AND_UPPER]; [self discard:1];
    } else if (LA(1) == TOKEN_KIND_DOUBLE_AMPERSAND) {
        [self match:TOKEN_KIND_DOUBLE_AMPERSAND]; [self discard:1];
    } else {
        [self raise:@"no viable alternative found in and"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchAnd:)];
}

- (void)or {
    
    if (LA(1) == TOKEN_KIND_OR_UPPER) {
        [self match:TOKEN_KIND_OR_UPPER]; [self discard:1];
    } else if (LA(1) == TOKEN_KIND_DOUBLE_PIPE) {
        [self match:TOKEN_KIND_DOUBLE_PIPE]; [self discard:1];
    } else {
        [self raise:@"no viable alternative found in or"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchOr:)];
}

- (void)not {
    
    if (LA(1) == TOKEN_KIND_NOT_UPPER) {
        [self match:TOKEN_KIND_NOT_UPPER]; [self discard:1];
    } else if (LA(1) == TOKEN_KIND_BANG) {
        [self match:TOKEN_KIND_BANG]; [self discard:1];
    } else {
        [self raise:@"no viable alternative found in not"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchNot:)];
}

- (void)stringTestPredicate {
    
    [self string]; 
    [self stringTestOp]; 
    [self value]; 

    [self fireAssemblerSelector:@selector(parser:didMatchStringTestPredicate:)];
}

- (void)stringTestOp {
    
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

- (void)beginswith {
    
    [self match:TOKEN_KIND_BEGINSWITH]; 

    [self fireAssemblerSelector:@selector(parser:didMatchBeginswith:)];
}

- (void)contains {
    
    [self match:TOKEN_KIND_CONTAINS]; 

    [self fireAssemblerSelector:@selector(parser:didMatchContains:)];
}

- (void)endswith {
    
    [self match:TOKEN_KIND_ENDSWITH]; 

    [self fireAssemblerSelector:@selector(parser:didMatchEndswith:)];
}

- (void)like {
    
    [self match:TOKEN_KIND_LIKE]; 

    [self fireAssemblerSelector:@selector(parser:didMatchLike:)];
}

- (void)matches {
    
    [self match:TOKEN_KIND_MATCHES]; 

    [self fireAssemblerSelector:@selector(parser:didMatchMatches:)];
}

- (void)collectionTestPredicate {
    
    [self value]; 
    [self in]; 
    [self collection]; 

    [self fireAssemblerSelector:@selector(parser:didMatchCollectionTestPredicate:)];
}

- (void)collection {
    
    if (LA(1) == TOKEN_KIND_BUILTIN_WORD) {
        [self keyPath]; 
    } else if (LA(1) == TOKEN_KIND_OPEN_CURLY) {
        [self array]; 
    } else {
        [self raise:@"no viable alternative found in collection"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchCollection:)];
}

- (void)in {
    
    [self match:TOKEN_KIND_IN]; [self discard:1];

    [self fireAssemblerSelector:@selector(parser:didMatchIn:)];
}

- (void)aggregateOp {
    
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

- (void)any {
    
    [self match:TOKEN_KIND_ANY]; 

    [self fireAssemblerSelector:@selector(parser:didMatchAny:)];
}

- (void)some {
    
    [self match:TOKEN_KIND_SOME]; 

    [self fireAssemblerSelector:@selector(parser:didMatchSome:)];
}

- (void)all {
    
    [self match:TOKEN_KIND_ALL]; 

    [self fireAssemblerSelector:@selector(parser:didMatchAll:)];
}

- (void)none {
    
    [self match:TOKEN_KIND_NONE]; 

    [self fireAssemblerSelector:@selector(parser:didMatchNone:)];
}

@end