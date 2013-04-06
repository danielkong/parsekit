#import "ExpressionParser.h"
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

@interface ExpressionParser ()
@property (nonatomic, retain) NSMutableDictionary *expr_memo;
@property (nonatomic, retain) NSMutableDictionary *orExpr_memo;
@property (nonatomic, retain) NSMutableDictionary *orTerm_memo;
@property (nonatomic, retain) NSMutableDictionary *andExpr_memo;
@property (nonatomic, retain) NSMutableDictionary *andTerm_memo;
@property (nonatomic, retain) NSMutableDictionary *relExpr_memo;
@property (nonatomic, retain) NSMutableDictionary *relOp_memo;
@property (nonatomic, retain) NSMutableDictionary *callExpr_memo;
@property (nonatomic, retain) NSMutableDictionary *argList_memo;
@property (nonatomic, retain) NSMutableDictionary *primary_memo;
@property (nonatomic, retain) NSMutableDictionary *atom_memo;
@property (nonatomic, retain) NSMutableDictionary *obj_memo;
@property (nonatomic, retain) NSMutableDictionary *id_memo;
@property (nonatomic, retain) NSMutableDictionary *member_memo;
@property (nonatomic, retain) NSMutableDictionary *literal_memo;
@property (nonatomic, retain) NSMutableDictionary *bool_memo;
@property (nonatomic, retain) NSMutableDictionary *lt_memo;
@property (nonatomic, retain) NSMutableDictionary *gt_memo;
@property (nonatomic, retain) NSMutableDictionary *eq_memo;
@property (nonatomic, retain) NSMutableDictionary *ne_memo;
@property (nonatomic, retain) NSMutableDictionary *le_memo;
@property (nonatomic, retain) NSMutableDictionary *ge_memo;
@property (nonatomic, retain) NSMutableDictionary *openParen_memo;
@property (nonatomic, retain) NSMutableDictionary *closeParen_memo;
@property (nonatomic, retain) NSMutableDictionary *yes_memo;
@property (nonatomic, retain) NSMutableDictionary *no_memo;
@property (nonatomic, retain) NSMutableDictionary *dot_memo;
@property (nonatomic, retain) NSMutableDictionary *comma_memo;
@property (nonatomic, retain) NSMutableDictionary *or_memo;
@property (nonatomic, retain) NSMutableDictionary *and_memo;
@end

@implementation ExpressionParser

- (id)init {
	self = [super init];
	if (self) {
        self._tokenKindTab[@">="] = @(TOKEN_KIND_GE);
        self._tokenKindTab[@","] = @(TOKEN_KIND_COMMA);
        self._tokenKindTab[@"or"] = @(TOKEN_KIND_OR);
        self._tokenKindTab[@"<"] = @(TOKEN_KIND_LT);
        self._tokenKindTab[@"<="] = @(TOKEN_KIND_LE);
        self._tokenKindTab[@"="] = @(TOKEN_KIND_EQ);
        self._tokenKindTab[@"."] = @(TOKEN_KIND_DOT);
        self._tokenKindTab[@">"] = @(TOKEN_KIND_GT);
        self._tokenKindTab[@"("] = @(TOKEN_KIND_OPENPAREN);
        self._tokenKindTab[@"yes"] = @(TOKEN_KIND_YES);
        self._tokenKindTab[@"no"] = @(TOKEN_KIND_NO);
        self._tokenKindTab[@")"] = @(TOKEN_KIND_CLOSEPAREN);
        self._tokenKindTab[@"!="] = @(TOKEN_KIND_NE);
        self._tokenKindTab[@"and"] = @(TOKEN_KIND_AND);
    }
	return self;
}

- (void)dealloc {
    self.expr_memo = nil;
    self.orExpr_memo = nil;
    self.orTerm_memo = nil;
    self.andExpr_memo = nil;
    self.andTerm_memo = nil;
    self.relExpr_memo = nil;
    self.relOp_memo = nil;
    self.callExpr_memo = nil;
    self.argList_memo = nil;
    self.primary_memo = nil;
    self.atom_memo = nil;
    self.obj_memo = nil;
    self.id_memo = nil;
    self.member_memo = nil;
    self.literal_memo = nil;
    self.bool_memo = nil;
    self.lt_memo = nil;
    self.gt_memo = nil;
    self.eq_memo = nil;
    self.ne_memo = nil;
    self.le_memo = nil;
    self.ge_memo = nil;
    self.openParen_memo = nil;
    self.closeParen_memo = nil;
    self.yes_memo = nil;
    self.no_memo = nil;
    self.dot_memo = nil;
    self.comma_memo = nil;
    self.or_memo = nil;
    self.and_memo = nil;

    [super dealloc];
}

- (void)_clearMemo {
    [self.expr_memo removeAllObjects];
    [self.orExpr_memo removeAllObjects];
    [self.orTerm_memo removeAllObjects];
    [self.andExpr_memo removeAllObjects];
    [self.andTerm_memo removeAllObjects];
    [self.relExpr_memo removeAllObjects];
    [self.relOp_memo removeAllObjects];
    [self.callExpr_memo removeAllObjects];
    [self.argList_memo removeAllObjects];
    [self.primary_memo removeAllObjects];
    [self.atom_memo removeAllObjects];
    [self.obj_memo removeAllObjects];
    [self.id_memo removeAllObjects];
    [self.member_memo removeAllObjects];
    [self.literal_memo removeAllObjects];
    [self.bool_memo removeAllObjects];
    [self.lt_memo removeAllObjects];
    [self.gt_memo removeAllObjects];
    [self.eq_memo removeAllObjects];
    [self.ne_memo removeAllObjects];
    [self.le_memo removeAllObjects];
    [self.ge_memo removeAllObjects];
    [self.openParen_memo removeAllObjects];
    [self.closeParen_memo removeAllObjects];
    [self.yes_memo removeAllObjects];
    [self.no_memo removeAllObjects];
    [self.dot_memo removeAllObjects];
    [self.comma_memo removeAllObjects];
    [self.or_memo removeAllObjects];
    [self.and_memo removeAllObjects];
}

- (void)_start {
    
    [self expr]; 

    [self fireAssemblerSelector:@selector(parser:didMatch_start:)];
}

- (void)__expr {
    
    [self orExpr]; 

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

- (void)__orExpr {
    
    [self andExpr]; 
    while (LA(1) == TOKEN_KIND_OR) {
        if ([self speculate:^{ [self orTerm]; }]) {
            [self orTerm]; 
        } else {
            break;
        }
    }

    [self fireAssemblerSelector:@selector(parser:didMatchOrExpr:)];
}

- (void)orExpr {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.orExpr_memo]) return;
    @try {
        [self __orExpr];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.orExpr_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__orTerm {
    
    [self or]; 
    [self andExpr]; 

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

- (void)__andExpr {
    
    [self relExpr]; 
    while (LA(1) == TOKEN_KIND_AND) {
        if ([self speculate:^{ [self andTerm]; }]) {
            [self andTerm]; 
        } else {
            break;
        }
    }

    [self fireAssemblerSelector:@selector(parser:didMatchAndExpr:)];
}

- (void)andExpr {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.andExpr_memo]) return;
    @try {
        [self __andExpr];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.andExpr_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__andTerm {
    
    [self and]; 
    [self relExpr]; 

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

- (void)__relExpr {
    
    [self callExpr]; 
    while (LA(1) == TOKEN_KIND_EQ || LA(1) == TOKEN_KIND_GE || LA(1) == TOKEN_KIND_GT || LA(1) == TOKEN_KIND_LE || LA(1) == TOKEN_KIND_LT || LA(1) == TOKEN_KIND_NE) {
        if ([self speculate:^{ [self relOp]; [self callExpr]; }]) {
            [self relOp]; 
            [self callExpr]; 
        } else {
            break;
        }
    }

    [self fireAssemblerSelector:@selector(parser:didMatchRelExpr:)];
}

- (void)relExpr {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.relExpr_memo]) return;
    @try {
        [self __relExpr];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.relExpr_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__relOp {
    
    if (LA(1) == TOKEN_KIND_LT) {
        [self lt]; 
    } else if (LA(1) == TOKEN_KIND_GT) {
        [self gt]; 
    } else if (LA(1) == TOKEN_KIND_EQ) {
        [self eq]; 
    } else if (LA(1) == TOKEN_KIND_NE) {
        [self ne]; 
    } else if (LA(1) == TOKEN_KIND_LE) {
        [self le]; 
    } else if (LA(1) == TOKEN_KIND_GE) {
        [self ge]; 
    } else {
        [self raise:@"no viable alternative found in relOp"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchRelOp:)];
}

- (void)relOp {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.relOp_memo]) return;
    @try {
        [self __relOp];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.relOp_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__callExpr {
    
    [self primary]; 
    if ((LA(1) == TOKEN_KIND_OPENPAREN) && ([self speculate:^{ [self openParen]; if ((LA(1) == TOKEN_KIND_BUILTIN_NUMBER || LA(1) == TOKEN_KIND_BUILTIN_QUOTEDSTRING || LA(1) == TOKEN_KIND_BUILTIN_WORD || LA(1) == TOKEN_KIND_NO || LA(1) == TOKEN_KIND_YES) && ([self speculate:^{ [self argList]; }])) {[self argList]; }[self closeParen]; }])) {
        [self openParen]; 
        if ((LA(1) == TOKEN_KIND_BUILTIN_NUMBER || LA(1) == TOKEN_KIND_BUILTIN_QUOTEDSTRING || LA(1) == TOKEN_KIND_BUILTIN_WORD || LA(1) == TOKEN_KIND_NO || LA(1) == TOKEN_KIND_YES) && ([self speculate:^{ [self argList]; }])) {
            [self argList]; 
        }
        [self closeParen]; 
    }

    [self fireAssemblerSelector:@selector(parser:didMatchCallExpr:)];
}

- (void)callExpr {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.callExpr_memo]) return;
    @try {
        [self __callExpr];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.callExpr_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__argList {
    
    [self atom]; 
    while (LA(1) == TOKEN_KIND_COMMA) {
        if ([self speculate:^{ [self comma]; [self atom]; }]) {
            [self comma]; 
            [self atom]; 
        } else {
            break;
        }
    }

    [self fireAssemblerSelector:@selector(parser:didMatchArgList:)];
}

- (void)argList {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.argList_memo]) return;
    @try {
        [self __argList];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.argList_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__primary {
    
    if (LA(1) == TOKEN_KIND_BUILTIN_NUMBER || LA(1) == TOKEN_KIND_BUILTIN_QUOTEDSTRING || LA(1) == TOKEN_KIND_BUILTIN_WORD || LA(1) == TOKEN_KIND_NO || LA(1) == TOKEN_KIND_YES) {
        [self atom]; 
    } else if (LA(1) == TOKEN_KIND_OPENPAREN) {
        [self openParen]; 
        [self expr]; 
        [self closeParen]; 
    } else {
        [self raise:@"no viable alternative found in primary"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchPrimary:)];
}

- (void)primary {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.primary_memo]) return;
    @try {
        [self __primary];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.primary_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__atom {
    
    if (LA(1) == TOKEN_KIND_BUILTIN_WORD) {
        [self obj]; 
    } else if (LA(1) == TOKEN_KIND_BUILTIN_NUMBER || LA(1) == TOKEN_KIND_BUILTIN_QUOTEDSTRING || LA(1) == TOKEN_KIND_NO || LA(1) == TOKEN_KIND_YES) {
        [self literal]; 
    } else {
        [self raise:@"no viable alternative found in atom"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchAtom:)];
}

- (void)atom {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.atom_memo]) return;
    @try {
        [self __atom];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.atom_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__obj {
    
    [self id]; 
    while (LA(1) == TOKEN_KIND_DOT) {
        if ([self speculate:^{ [self member]; }]) {
            [self member]; 
        } else {
            break;
        }
    }

    [self fireAssemblerSelector:@selector(parser:didMatchObj:)];
}

- (void)obj {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.obj_memo]) return;
    @try {
        [self __obj];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.obj_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__id {
    
    [self Word]; 

    [self fireAssemblerSelector:@selector(parser:didMatchId:)];
}

- (void)id {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.id_memo]) return;
    @try {
        [self __id];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.id_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__member {
    
    [self dot]; 
    [self id]; 

    [self fireAssemblerSelector:@selector(parser:didMatchMember:)];
}

- (void)member {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.member_memo]) return;
    @try {
        [self __member];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.member_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__literal {
    
    if (LA(1) == TOKEN_KIND_BUILTIN_QUOTEDSTRING) {
        [self QuotedString]; 
    } else if (LA(1) == TOKEN_KIND_BUILTIN_NUMBER) {
        [self Number]; 
    } else if (LA(1) == TOKEN_KIND_NO || LA(1) == TOKEN_KIND_YES) {
        [self bool]; 
    } else {
        [self raise:@"no viable alternative found in literal"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchLiteral:)];
}

- (void)literal {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.literal_memo]) return;
    @try {
        [self __literal];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.literal_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__bool {
    
    if (LA(1) == TOKEN_KIND_YES) {
        [self yes]; 
    } else if (LA(1) == TOKEN_KIND_NO) {
        [self no]; 
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

- (void)__eq {
    
    [self match:TOKEN_KIND_EQ]; 

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

- (void)__ne {
    
    [self match:TOKEN_KIND_NE]; 

    [self fireAssemblerSelector:@selector(parser:didMatchNe:)];
}

- (void)ne {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.ne_memo]) return;
    @try {
        [self __ne];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.ne_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__le {
    
    [self match:TOKEN_KIND_LE]; 

    [self fireAssemblerSelector:@selector(parser:didMatchLe:)];
}

- (void)le {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.le_memo]) return;
    @try {
        [self __le];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.le_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__ge {
    
    [self match:TOKEN_KIND_GE]; 

    [self fireAssemblerSelector:@selector(parser:didMatchGe:)];
}

- (void)ge {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.ge_memo]) return;
    @try {
        [self __ge];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.ge_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__openParen {
    
    [self match:TOKEN_KIND_OPENPAREN]; 

    [self fireAssemblerSelector:@selector(parser:didMatchOpenParen:)];
}

- (void)openParen {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.openParen_memo]) return;
    @try {
        [self __openParen];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.openParen_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__closeParen {
    
    [self match:TOKEN_KIND_CLOSEPAREN]; [self discard:1];

    [self fireAssemblerSelector:@selector(parser:didMatchCloseParen:)];
}

- (void)closeParen {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.closeParen_memo]) return;
    @try {
        [self __closeParen];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.closeParen_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__yes {
    
    [self match:TOKEN_KIND_YES]; 

    [self fireAssemblerSelector:@selector(parser:didMatchYes:)];
}

- (void)yes {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.yes_memo]) return;
    @try {
        [self __yes];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.yes_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__no {
    
    [self match:TOKEN_KIND_NO]; 

    [self fireAssemblerSelector:@selector(parser:didMatchNo:)];
}

- (void)no {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.no_memo]) return;
    @try {
        [self __no];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.no_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__dot {
    
    [self match:TOKEN_KIND_DOT]; 

    [self fireAssemblerSelector:@selector(parser:didMatchDot:)];
}

- (void)dot {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.dot_memo]) return;
    @try {
        [self __dot];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.dot_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__comma {
    
    [self match:TOKEN_KIND_COMMA]; 

    [self fireAssemblerSelector:@selector(parser:didMatchComma:)];
}

- (void)comma {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.comma_memo]) return;
    @try {
        [self __comma];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.comma_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__or {
    
    [self match:TOKEN_KIND_OR]; 

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

- (void)__and {
    
    [self match:TOKEN_KIND_AND]; 

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

@end