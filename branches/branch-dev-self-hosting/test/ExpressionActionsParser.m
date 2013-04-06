#import "ExpressionActionsParser.h"
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

@interface ExpressionActionsParser ()
@property (nonatomic, retain) NSMutableDictionary *expr_memo;
@property (nonatomic, retain) NSMutableDictionary *orExpr_memo;
@property (nonatomic, retain) NSMutableDictionary *orTerm_memo;
@property (nonatomic, retain) NSMutableDictionary *andExpr_memo;
@property (nonatomic, retain) NSMutableDictionary *andTerm_memo;
@property (nonatomic, retain) NSMutableDictionary *relExpr_memo;
@property (nonatomic, retain) NSMutableDictionary *relOp_memo;
@property (nonatomic, retain) NSMutableDictionary *relOpTerm_memo;
@property (nonatomic, retain) NSMutableDictionary *callExpr_memo;
@property (nonatomic, retain) NSMutableDictionary *argList_memo;
@property (nonatomic, retain) NSMutableDictionary *primary_memo;
@property (nonatomic, retain) NSMutableDictionary *atom_memo;
@property (nonatomic, retain) NSMutableDictionary *obj_memo;
@property (nonatomic, retain) NSMutableDictionary *id_memo;
@property (nonatomic, retain) NSMutableDictionary *member_memo;
@property (nonatomic, retain) NSMutableDictionary *literal_memo;
@property (nonatomic, retain) NSMutableDictionary *bool_memo;
@end

@implementation ExpressionActionsParser

- (id)init {
	self = [super init];
	if (self) {
        self._tokenKindTab[@"no"] = @(TOKEN_KIND_NO);
        self._tokenKindTab[@"NO"] = @(TOKEN_KIND_NO_UPPER);
        self._tokenKindTab[@">="] = @(TOKEN_KIND_GE);
        self._tokenKindTab[@","] = @(TOKEN_KIND_COMMA);
        self._tokenKindTab[@"or"] = @(TOKEN_KIND_OR);
        self._tokenKindTab[@"<"] = @(TOKEN_KIND_LT);
        self._tokenKindTab[@"<="] = @(TOKEN_KIND_LE);
        self._tokenKindTab[@"="] = @(TOKEN_KIND_EQUALS);
        self._tokenKindTab[@"."] = @(TOKEN_KIND_DOT);
        self._tokenKindTab[@">"] = @(TOKEN_KIND_GT);
        self._tokenKindTab[@"and"] = @(TOKEN_KIND_AND);
        self._tokenKindTab[@"("] = @(TOKEN_KIND_OPEN_PAREN);
        self._tokenKindTab[@"yes"] = @(TOKEN_KIND_YES);
        self._tokenKindTab[@")"] = @(TOKEN_KIND_CLOSE_PAREN);
        self._tokenKindTab[@"!="] = @(TOKEN_KIND_NE);
        self._tokenKindTab[@"YES"] = @(TOKEN_KIND_YES_UPPER);
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
    self.relOpTerm_memo = nil;
    self.callExpr_memo = nil;
    self.argList_memo = nil;
    self.primary_memo = nil;
    self.atom_memo = nil;
    self.obj_memo = nil;
    self.id_memo = nil;
    self.member_memo = nil;
    self.literal_memo = nil;
    self.bool_memo = nil;

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
    [self.relOpTerm_memo removeAllObjects];
    [self.callExpr_memo removeAllObjects];
    [self.argList_memo removeAllObjects];
    [self.primary_memo removeAllObjects];
    [self.atom_memo removeAllObjects];
    [self.obj_memo removeAllObjects];
    [self.id_memo removeAllObjects];
    [self.member_memo removeAllObjects];
    [self.literal_memo removeAllObjects];
    [self.bool_memo removeAllObjects];
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
    
    [self match:TOKEN_KIND_OR]; [self discard:1];
    [self andExpr]; 
    [self execute:(id)^{
        
	BOOL rhs = POP_BOOL();
	BOOL lhs = POP_BOOL();
	PUSH_BOOL(lhs || rhs);

    }];

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
    
    [self match:TOKEN_KIND_AND]; [self discard:1];
    [self relExpr]; 
    [self execute:(id)^{
        
	BOOL rhs = POP_BOOL();
	BOOL lhs = POP_BOOL();
	PUSH_BOOL(lhs && rhs);

    }];

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
    while (LA(1) == TOKEN_KIND_EQUALS || LA(1) == TOKEN_KIND_GE || LA(1) == TOKEN_KIND_GT || LA(1) == TOKEN_KIND_LE || LA(1) == TOKEN_KIND_LT || LA(1) == TOKEN_KIND_NE) {
        if ([self speculate:^{ [self relOpTerm]; }]) {
            [self relOpTerm]; 
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
        [self match:TOKEN_KIND_LT]; 
    } else if (LA(1) == TOKEN_KIND_GT) {
        [self match:TOKEN_KIND_GT]; 
    } else if (LA(1) == TOKEN_KIND_EQUALS) {
        [self match:TOKEN_KIND_EQUALS]; 
    } else if (LA(1) == TOKEN_KIND_NE) {
        [self match:TOKEN_KIND_NE]; 
    } else if (LA(1) == TOKEN_KIND_LE) {
        [self match:TOKEN_KIND_LE]; 
    } else if (LA(1) == TOKEN_KIND_GE) {
        [self match:TOKEN_KIND_GE]; 
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

- (void)__relOpTerm {
    
    [self relOp]; 
    [self callExpr]; 
    [self execute:(id)^{
        
	NSInteger rhs = POP_INT();
	NSString  *op = POP_STR();
	NSInteger lhs = POP_INT();

	     if (EQ(op, @"<"))  PUSH_BOOL(lhs <  rhs);
	else if (EQ(op, @">"))  PUSH_BOOL(lhs >  rhs);
	else if (EQ(op, @"="))  PUSH_BOOL(lhs == rhs);
	else if (EQ(op, @"!=")) PUSH_BOOL(lhs != rhs);
	else if (EQ(op, @"<=")) PUSH_BOOL(lhs <= rhs);
	else if (EQ(op, @">=")) PUSH_BOOL(lhs >= rhs);

    }];

    [self fireAssemblerSelector:@selector(parser:didMatchRelOpTerm:)];
}

- (void)relOpTerm {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.relOpTerm_memo]) return;
    @try {
        [self __relOpTerm];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.relOpTerm_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__callExpr {
    
    [self primary]; 
    if ((LA(1) == TOKEN_KIND_OPEN_PAREN) && ([self speculate:^{ [self match:TOKEN_KIND_OPEN_PAREN]; if ((LA(1) == TOKEN_KIND_BUILTIN_NUMBER || LA(1) == TOKEN_KIND_BUILTIN_QUOTEDSTRING || LA(1) == TOKEN_KIND_BUILTIN_WORD || LA(1) == TOKEN_KIND_NO || LA(1) == TOKEN_KIND_NO_UPPER || LA(1) == TOKEN_KIND_YES || LA(1) == TOKEN_KIND_YES_UPPER) && ([self speculate:^{ [self argList]; }])) {[self argList]; }[self match:TOKEN_KIND_CLOSE_PAREN]; }])) {
        [self match:TOKEN_KIND_OPEN_PAREN]; 
        if ((LA(1) == TOKEN_KIND_BUILTIN_NUMBER || LA(1) == TOKEN_KIND_BUILTIN_QUOTEDSTRING || LA(1) == TOKEN_KIND_BUILTIN_WORD || LA(1) == TOKEN_KIND_NO || LA(1) == TOKEN_KIND_NO_UPPER || LA(1) == TOKEN_KIND_YES || LA(1) == TOKEN_KIND_YES_UPPER) && ([self speculate:^{ [self argList]; }])) {
            [self argList]; 
        }
        [self match:TOKEN_KIND_CLOSE_PAREN]; 
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
        if ([self speculate:^{ [self match:TOKEN_KIND_COMMA]; [self atom]; }]) {
            [self match:TOKEN_KIND_COMMA]; 
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
    
    if (LA(1) == TOKEN_KIND_BUILTIN_NUMBER || LA(1) == TOKEN_KIND_BUILTIN_QUOTEDSTRING || LA(1) == TOKEN_KIND_BUILTIN_WORD || LA(1) == TOKEN_KIND_NO || LA(1) == TOKEN_KIND_NO_UPPER || LA(1) == TOKEN_KIND_YES || LA(1) == TOKEN_KIND_YES_UPPER) {
        [self atom]; 
    } else if (LA(1) == TOKEN_KIND_OPEN_PAREN) {
        [self match:TOKEN_KIND_OPEN_PAREN]; 
        [self expr]; 
        [self match:TOKEN_KIND_CLOSE_PAREN]; 
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
    } else if (LA(1) == TOKEN_KIND_BUILTIN_NUMBER || LA(1) == TOKEN_KIND_BUILTIN_QUOTEDSTRING || LA(1) == TOKEN_KIND_NO || LA(1) == TOKEN_KIND_NO_UPPER || LA(1) == TOKEN_KIND_YES || LA(1) == TOKEN_KIND_YES_UPPER) {
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
    
    [self match:TOKEN_KIND_DOT]; 
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
    
    if ([self test:(id)^{ return LA(1) != TOKEN_KIND_YES_UPPER; }] && (LA(1) == TOKEN_KIND_NO || LA(1) == TOKEN_KIND_NO_UPPER || LA(1) == TOKEN_KIND_YES || LA(1) == TOKEN_KIND_YES_UPPER)) {
        [self bool]; 
        [self execute:(id)^{
             PUSH_BOOL(EQ_IGNORE_CASE(POP_STR(), @"yes")); 
        }];
    } else if (LA(1) == TOKEN_KIND_BUILTIN_NUMBER) {
        [self Number]; 
        [self execute:(id)^{
             PUSH_FLOAT(POP_FLOAT()); 
        }];
    } else if (LA(1) == TOKEN_KIND_BUILTIN_QUOTEDSTRING) {
        [self QuotedString]; 
        [self execute:(id)^{
             PUSH(POP_STR()); 
        }];
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
        [self match:TOKEN_KIND_YES]; 
    } else if (LA(1) == TOKEN_KIND_YES_UPPER) {
        [self match:TOKEN_KIND_YES_UPPER]; 
    } else if (LA(1) == TOKEN_KIND_NO) {
        [self match:TOKEN_KIND_NO]; 
    } else if ([self test:(id)^{  return NE(LS(1), @"NO");  }] && (LA(1) == TOKEN_KIND_NO_UPPER)) {
        [self match:TOKEN_KIND_NO_UPPER]; 
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

@end