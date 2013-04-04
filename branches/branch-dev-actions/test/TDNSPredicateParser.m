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
@end

@interface TDNSPredicateParser ()
@property (nonatomic, retain) NSDictionary *_tokenKindTab;
@end

@implementation TDNSPredicateParser

- (id)init {
	self = [super init];
	if (self) {
		self._tokenKindTab = @{
           @"ALL" : @(TOKEN_KIND_ALL),
           @"FALSEPREDICATE" : @(TOKEN_KIND_FALSEPREDICATE),
           @"NOT" : @(TOKEN_KIND_NOT_UPPER),
           @"{" : @(TOKEN_KIND_OPEN_CURLY),
           @"=>" : @(TOKEN_KIND_HASH_ROCKET),
           @">=" : @(TOKEN_KIND_GE),
           @"&&" : @(TOKEN_KIND_DOUBLE_AMPERSAND),
           @"TRUEPREDICATE" : @(TOKEN_KIND_TRUEPREDICATE),
           @"AND" : @(TOKEN_KIND_AND_UPPER),
           @"}" : @(TOKEN_KIND_CLOSE_CURLY),
           @"true" : @(TOKEN_KIND_TRUELITERAL),
           @"!=" : @(TOKEN_KIND_NE),
           @"OR" : @(TOKEN_KIND_OR_UPPER),
           @"!" : @(TOKEN_KIND_BANG),
           @"SOME" : @(TOKEN_KIND_SOME),
           @"IN" : @(TOKEN_KIND_IN),
           @"BEGINSWITH" : @(TOKEN_KIND_BEGINSWITH),
           @"<" : @(TOKEN_KIND_LT),
           @"=" : @(TOKEN_KIND_EQUALS),
           @"CONTAINS" : @(TOKEN_KIND_CONTAINS),
           @">" : @(TOKEN_KIND_GT),
           @"(" : @(TOKEN_KIND_OPEN_PAREN),
           @")" : @(TOKEN_KIND_CLOSE_PAREN),
           @"||" : @(TOKEN_KIND_DOUBLE_PIPE),
           @"MATCHES" : @(TOKEN_KIND_MATCHES),
           @"," : @(TOKEN_KIND_COMMA),
           @"LIKE" : @(TOKEN_KIND_LIKE),
           @"ANY" : @(TOKEN_KIND_ANY),
           @"ENDSWITH" : @(TOKEN_KIND_ENDSWITH),
           @"false" : @(TOKEN_KIND_FALSELITERAL),
           @"<=" : @(TOKEN_KIND_LE),
           @"BETWEEN" : @(TOKEN_KIND_BETWEEN),
           @"=<" : @(TOKEN_KIND_EL),
           @"<>" : @(TOKEN_KIND_NOT_EQUAL),
           @"NONE" : @(TOKEN_KIND_NONE),
           @"==" : @(TOKEN_KIND_DOUBLE_EQUALS),
        };
	}
	return self;
}

- (void)dealloc {
	self._tokenKindTab = nil;
	[super dealloc];
}

- (NSInteger)tokenKindForString:(NSString *)s {
    NSInteger x = TOKEN_KIND_BUILTIN_INVALID;

    id obj = _tokenKindTab[s];
    if (obj) {
        x = [obj integerValue];
    }
    
    return x;
}

- (void)_start {
    
    @try {
        [self expr]; 
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatch_start:)];
}

- (void)expr {
    
    @try {
        [self orTerm]; 
        while (LA(1) == TOKEN_KIND_DOUBLE_PIPE || LA(1) == TOKEN_KIND_OR_UPPER) {
            if ([self speculate:^{ [self orOrTerm]; }]) {
                [self orOrTerm]; 
            } else {
                return;
            }
        }
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchExpr:)];
}

- (void)orOrTerm {
    
    @try {
        [self or]; 
        [self orTerm]; 
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchOrOrTerm:)];
}

- (void)orTerm {
    
    @try {
        [self andTerm]; 
        while (LA(1) == TOKEN_KIND_DOUBLE_AMPERSAND || LA(1) == TOKEN_KIND_AND_UPPER) {
            if ([self speculate:^{ [self andAndTerm]; }]) {
                [self andAndTerm]; 
            } else {
                return;
            }
        }
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchOrTerm:)];
}

- (void)andAndTerm {
    
    @try {
        [self and]; 
        [self andTerm]; 
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchAndAndTerm:)];
}

- (void)andTerm {
    
    @try {
        if (LA(1) == TOKEN_KIND_BUILTIN_WORD || LA(1) == TOKEN_KIND_BUILTIN_WORD || LA(1) == TOKEN_KIND_ALL || LA(1) == TOKEN_KIND_FALSELITERAL || LA(1) == TOKEN_KIND_TRUELITERAL || LA(1) == TOKEN_KIND_FALSEPREDICATE || LA(1) == TOKEN_KIND_ANY || LA(1) == TOKEN_KIND_NOT_UPPER || LA(1) == TOKEN_KIND_BUILTIN_NUMBER || LA(1) == TOKEN_KIND_TRUEPREDICATE || LA(1) == TOKEN_KIND_SOME || LA(1) == TOKEN_KIND_NONE || LA(1) == TOKEN_KIND_BANG || LA(1) == TOKEN_KIND_BUILTIN_QUOTEDSTRING || LA(1) == TOKEN_KIND_OPEN_CURLY) {
            [self primaryExpr]; 
        } else if (LA(1) == TOKEN_KIND_OPEN_PAREN) {
            [self compoundExpr]; 
        } else {
            [self raise:@"no viable alternative found in andTerm"];
        }
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchAndTerm:)];
}

- (void)compoundExpr {
    
    @try {
        [self match:TOKEN_KIND_OPEN_PAREN]; [self discard:1];
        [self expr]; 
        [self match:TOKEN_KIND_CLOSE_PAREN]; [self discard:1];
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchCompoundExpr:)];
}

- (void)primaryExpr {
    
    @try {
        if (LA(1) == TOKEN_KIND_ALL || LA(1) == TOKEN_KIND_FALSELITERAL || LA(1) == TOKEN_KIND_TRUELITERAL || LA(1) == TOKEN_KIND_FALSEPREDICATE || LA(1) == TOKEN_KIND_ANY || LA(1) == TOKEN_KIND_BUILTIN_NUMBER || LA(1) == TOKEN_KIND_TRUEPREDICATE || LA(1) == TOKEN_KIND_NONE || LA(1) == TOKEN_KIND_SOME || LA(1) == TOKEN_KIND_BUILTIN_QUOTEDSTRING || LA(1) == TOKEN_KIND_BUILTIN_NUMBER || LA(1) == TOKEN_KIND_OPEN_CURLY || LA(1) == TOKEN_KIND_BUILTIN_WORD) {
            [self predicate]; 
        } else if (LA(1) == TOKEN_KIND_NOT_UPPER || LA(1) == TOKEN_KIND_BANG) {
            [self negatedPredicate]; 
        } else {
            [self raise:@"no viable alternative found in primaryExpr"];
        }
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchPrimaryExpr:)];
}

- (void)negatedPredicate {
    
    @try {
        [self not]; 
        [self predicate]; 
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchNegatedPredicate:)];
}

- (void)predicate {
    
    @try {
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
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchPredicate:)];
}

- (void)value {
    
    @try {
        if (LA(1) == TOKEN_KIND_BUILTIN_WORD) {
            [self keyPath]; 
        } else if (LA(1) == TOKEN_KIND_BUILTIN_QUOTEDSTRING) {
            [self string]; 
        } else if (LA(1) == TOKEN_KIND_BUILTIN_NUMBER) {
            [self num]; 
        } else if (LA(1) == TOKEN_KIND_TRUELITERAL || LA(1) == TOKEN_KIND_FALSELITERAL) {
            [self bool]; 
        } else if (LA(1) == TOKEN_KIND_OPEN_CURLY) {
            [self array]; 
        } else {
            [self raise:@"no viable alternative found in value"];
        }
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchValue:)];
}

- (void)string {
    
    @try {
        [self QuotedString]; 
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchString:)];
}

- (void)num {
    
    @try {
        [self Number]; 
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchNum:)];
}

- (void)bool {
    
    @try {
        if (LA(1) == TOKEN_KIND_TRUELITERAL) {
            [self trueLiteral]; 
        } else if (LA(1) == TOKEN_KIND_FALSELITERAL) {
            [self falseLiteral]; 
        } else {
            [self raise:@"no viable alternative found in bool"];
        }
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchBool:)];
}

- (void)trueLiteral {
    
    @try {
        [self match:TOKEN_KIND_TRUELITERAL]; [self discard:1];
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchTrueLiteral:)];
}

- (void)falseLiteral {
    
    @try {
        [self match:TOKEN_KIND_FALSELITERAL]; [self discard:1];
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchFalseLiteral:)];
}

- (void)array {
    
    @try {
        [self match:TOKEN_KIND_OPEN_CURLY]; 
        [self arrayContentsOpt]; 
        [self match:TOKEN_KIND_CLOSE_CURLY]; [self discard:1];
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchArray:)];
}

- (void)arrayContentsOpt {
    
    @try {
        if (LA(1) == TOKEN_KIND_TRUELITERAL || LA(1) == TOKEN_KIND_FALSELITERAL || LA(1) == TOKEN_KIND_BUILTIN_NUMBER || LA(1) == TOKEN_KIND_OPEN_CURLY || LA(1) == TOKEN_KIND_BUILTIN_QUOTEDSTRING || LA(1) == TOKEN_KIND_BUILTIN_WORD) {
            [self arrayContents]; 
        }
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchArrayContentsOpt:)];
}

- (void)arrayContents {
    
    @try {
        [self value]; 
        while (LA(1) == TOKEN_KIND_COMMA) {
            if ([self speculate:^{ [self commaValue]; }]) {
                [self commaValue]; 
            } else {
                return;
            }
        }
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchArrayContents:)];
}

- (void)commaValue {
    
    @try {
        [self match:TOKEN_KIND_COMMA]; [self discard:1];
        [self value]; 
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchCommaValue:)];
}

- (void)keyPath {
    
    @try {
        [self Word]; 
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchKeyPath:)];
}

- (void)comparisonPredicate {
    
    @try {
        if (LA(1) == TOKEN_KIND_BUILTIN_NUMBER || LA(1) == TOKEN_KIND_BUILTIN_WORD) {
            [self numComparisonPredicate]; 
        } else if (LA(1) == TOKEN_KIND_ANY || LA(1) == TOKEN_KIND_ALL || LA(1) == TOKEN_KIND_NONE || LA(1) == TOKEN_KIND_SOME) {
            [self collectionComparisonPredicate]; 
        } else {
            [self raise:@"no viable alternative found in comparisonPredicate"];
        }
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchComparisonPredicate:)];
}

- (void)numComparisonPredicate {
    
    @try {
        [self numComparisonValue]; 
        [self comparisonOp]; 
        [self numComparisonValue]; 
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchNumComparisonPredicate:)];
}

- (void)numComparisonValue {
    
    @try {
        if (LA(1) == TOKEN_KIND_BUILTIN_WORD) {
            [self keyPath]; 
        } else if (LA(1) == TOKEN_KIND_BUILTIN_NUMBER) {
            [self num]; 
        } else {
            [self raise:@"no viable alternative found in numComparisonValue"];
        }
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchNumComparisonValue:)];
}

- (void)comparisonOp {
    
    @try {
        if (LA(1) == TOKEN_KIND_EQUALS || LA(1) == TOKEN_KIND_DOUBLE_EQUALS) {
            [self eq]; 
        } else if (LA(1) == TOKEN_KIND_GT) {
            [self gt]; 
        } else if (LA(1) == TOKEN_KIND_LT) {
            [self lt]; 
        } else if (LA(1) == TOKEN_KIND_HASH_ROCKET || LA(1) == TOKEN_KIND_GE) {
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
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchComparisonOp:)];
}

- (void)eq {
    
    @try {
        if (LA(1) == TOKEN_KIND_EQUALS) {
            [self match:TOKEN_KIND_EQUALS]; 
        } else if (LA(1) == TOKEN_KIND_DOUBLE_EQUALS) {
            [self match:TOKEN_KIND_DOUBLE_EQUALS]; 
        } else {
            [self raise:@"no viable alternative found in eq"];
        }
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchEq:)];
}

- (void)gt {
    
    @try {
        [self match:TOKEN_KIND_GT]; 
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchGt:)];
}

- (void)lt {
    
    @try {
        [self match:TOKEN_KIND_LT]; 
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchLt:)];
}

- (void)gtEq {
    
    @try {
        if (LA(1) == TOKEN_KIND_GE) {
            [self match:TOKEN_KIND_GE]; 
        } else if (LA(1) == TOKEN_KIND_HASH_ROCKET) {
            [self match:TOKEN_KIND_HASH_ROCKET]; 
        } else {
            [self raise:@"no viable alternative found in gtEq"];
        }
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchGtEq:)];
}

- (void)ltEq {
    
    @try {
        if (LA(1) == TOKEN_KIND_LE) {
            [self match:TOKEN_KIND_LE]; 
        } else if (LA(1) == TOKEN_KIND_EL) {
            [self match:TOKEN_KIND_EL]; 
        } else {
            [self raise:@"no viable alternative found in ltEq"];
        }
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchLtEq:)];
}

- (void)notEq {
    
    @try {
        if (LA(1) == TOKEN_KIND_NE) {
            [self match:TOKEN_KIND_NE]; 
        } else if (LA(1) == TOKEN_KIND_NOT_EQUAL) {
            [self match:TOKEN_KIND_NOT_EQUAL]; 
        } else {
            [self raise:@"no viable alternative found in notEq"];
        }
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchNotEq:)];
}

- (void)between {
    
    @try {
        [self match:TOKEN_KIND_BETWEEN]; 
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchBetween:)];
}

- (void)collectionComparisonPredicate {
    
    @try {
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
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchCollectionComparisonPredicate:)];
}

- (void)collectionLtPredicate {
    
    @try {
        [self aggregateOp]; 
        [self collection]; 
        [self lt]; 
        [self value]; 
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchCollectionLtPredicate:)];
}

- (void)collectionGtPredicate {
    
    @try {
        [self aggregateOp]; 
        [self collection]; 
        [self gt]; 
        [self value]; 
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchCollectionGtPredicate:)];
}

- (void)collectionLtEqPredicate {
    
    @try {
        [self aggregateOp]; 
        [self collection]; 
        [self ltEq]; 
        [self value]; 
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchCollectionLtEqPredicate:)];
}

- (void)collectionGtEqPredicate {
    
    @try {
        [self aggregateOp]; 
        [self collection]; 
        [self gtEq]; 
        [self value]; 
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchCollectionGtEqPredicate:)];
}

- (void)collectionEqPredicate {
    
    @try {
        [self aggregateOp]; 
        [self collection]; 
        [self eq]; 
        [self value]; 
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchCollectionEqPredicate:)];
}

- (void)collectionNotEqPredicate {
    
    @try {
        [self aggregateOp]; 
        [self collection]; 
        [self notEq]; 
        [self value]; 
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchCollectionNotEqPredicate:)];
}

- (void)boolPredicate {
    
    @try {
        if (LA(1) == TOKEN_KIND_TRUEPREDICATE) {
            [self truePredicate]; 
        } else if (LA(1) == TOKEN_KIND_FALSEPREDICATE) {
            [self falsePredicate]; 
        } else {
            [self raise:@"no viable alternative found in boolPredicate"];
        }
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchBoolPredicate:)];
}

- (void)truePredicate {
    
    @try {
        [self match:TOKEN_KIND_TRUEPREDICATE]; [self discard:1];
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchTruePredicate:)];
}

- (void)falsePredicate {
    
    @try {
        [self match:TOKEN_KIND_FALSEPREDICATE]; [self discard:1];
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchFalsePredicate:)];
}

- (void)and {
    
    @try {
        if (LA(1) == TOKEN_KIND_AND_UPPER) {
            [self match:TOKEN_KIND_AND_UPPER]; [self discard:1];
        } else if (LA(1) == TOKEN_KIND_DOUBLE_AMPERSAND) {
            [self match:TOKEN_KIND_DOUBLE_AMPERSAND]; [self discard:1];
        } else {
            [self raise:@"no viable alternative found in and"];
        }
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchAnd:)];
}

- (void)or {
    
    @try {
        if (LA(1) == TOKEN_KIND_OR_UPPER) {
            [self match:TOKEN_KIND_OR_UPPER]; [self discard:1];
        } else if (LA(1) == TOKEN_KIND_DOUBLE_PIPE) {
            [self match:TOKEN_KIND_DOUBLE_PIPE]; [self discard:1];
        } else {
            [self raise:@"no viable alternative found in or"];
        }
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchOr:)];
}

- (void)not {
    
    @try {
        if (LA(1) == TOKEN_KIND_NOT_UPPER) {
            [self match:TOKEN_KIND_NOT_UPPER]; [self discard:1];
        } else if (LA(1) == TOKEN_KIND_BANG) {
            [self match:TOKEN_KIND_BANG]; [self discard:1];
        } else {
            [self raise:@"no viable alternative found in not"];
        }
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchNot:)];
}

- (void)stringTestPredicate {
    
    @try {
        [self string]; 
        [self stringTestOp]; 
        [self value]; 
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchStringTestPredicate:)];
}

- (void)stringTestOp {
    
    @try {
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
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchStringTestOp:)];
}

- (void)beginswith {
    
    @try {
        [self match:TOKEN_KIND_BEGINSWITH]; 
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchBeginswith:)];
}

- (void)contains {
    
    @try {
        [self match:TOKEN_KIND_CONTAINS]; 
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchContains:)];
}

- (void)endswith {
    
    @try {
        [self match:TOKEN_KIND_ENDSWITH]; 
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchEndswith:)];
}

- (void)like {
    
    @try {
        [self match:TOKEN_KIND_LIKE]; 
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchLike:)];
}

- (void)matches {
    
    @try {
        [self match:TOKEN_KIND_MATCHES]; 
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchMatches:)];
}

- (void)collectionTestPredicate {
    
    @try {
        [self value]; 
        [self in]; 
        [self collection]; 
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchCollectionTestPredicate:)];
}

- (void)collection {
    
    @try {
        if (LA(1) == TOKEN_KIND_BUILTIN_WORD) {
            [self keyPath]; 
        } else if (LA(1) == TOKEN_KIND_OPEN_CURLY) {
            [self array]; 
        } else {
            [self raise:@"no viable alternative found in collection"];
        }
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchCollection:)];
}

- (void)in {
    
    @try {
        [self match:TOKEN_KIND_IN]; [self discard:1];
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchIn:)];
}

- (void)aggregateOp {
    
    @try {
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
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchAggregateOp:)];
}

- (void)any {
    
    @try {
        [self match:TOKEN_KIND_ANY]; 
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchAny:)];
}

- (void)some {
    
    @try {
        [self match:TOKEN_KIND_SOME]; 
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchSome:)];
}

- (void)all {
    
    @try {
        [self match:TOKEN_KIND_ALL]; 
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchAll:)];
}

- (void)none {
    
    @try {
        [self match:TOKEN_KIND_NONE]; 
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchNone:)];
}

@synthesize _tokenKindTab = _tokenKindTab;
@end