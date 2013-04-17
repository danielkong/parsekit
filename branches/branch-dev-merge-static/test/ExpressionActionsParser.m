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
@property (nonatomic, retain) PKTokenizer *_tokenizer;
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

        self.expr_memo = [NSMutableDictionary dictionary];
        self.orExpr_memo = [NSMutableDictionary dictionary];
        self.orTerm_memo = [NSMutableDictionary dictionary];
        self.andExpr_memo = [NSMutableDictionary dictionary];
        self.andTerm_memo = [NSMutableDictionary dictionary];
        self.relExpr_memo = [NSMutableDictionary dictionary];
        self.relOp_memo = [NSMutableDictionary dictionary];
        self.relOpTerm_memo = [NSMutableDictionary dictionary];
        self.callExpr_memo = [NSMutableDictionary dictionary];
        self.argList_memo = [NSMutableDictionary dictionary];
        self.primary_memo = [NSMutableDictionary dictionary];
        self.atom_memo = [NSMutableDictionary dictionary];
        self.obj_memo = [NSMutableDictionary dictionary];
        self.id_memo = [NSMutableDictionary dictionary];
        self.member_memo = [NSMutableDictionary dictionary];
        self.literal_memo = [NSMutableDictionary dictionary];
        self.bool_memo = [NSMutableDictionary dictionary];
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
    [_expr_memo removeAllObjects];
    [_orExpr_memo removeAllObjects];
    [_orTerm_memo removeAllObjects];
    [_andExpr_memo removeAllObjects];
    [_andTerm_memo removeAllObjects];
    [_relExpr_memo removeAllObjects];
    [_relOp_memo removeAllObjects];
    [_relOpTerm_memo removeAllObjects];
    [_callExpr_memo removeAllObjects];
    [_argList_memo removeAllObjects];
    [_primary_memo removeAllObjects];
    [_atom_memo removeAllObjects];
    [_obj_memo removeAllObjects];
    [_id_memo removeAllObjects];
    [_member_memo removeAllObjects];
    [_literal_memo removeAllObjects];
    [_bool_memo removeAllObjects];
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
    [self parseRule:@selector(__expr) withMemo:_expr_memo];
}

- (void)__orExpr {
    
    [self andExpr]; 
    while ([self predicts:TOKEN_KIND_OR, 0]) {
        if ([self speculate:^{ [self orTerm]; }]) {
            [self orTerm]; 
        } else {
            break;
        }
    }

    [self fireAssemblerSelector:@selector(parser:didMatchOrExpr:)];
}

- (void)orExpr {
    [self parseRule:@selector(__orExpr) withMemo:_orExpr_memo];
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
    [self parseRule:@selector(__orTerm) withMemo:_orTerm_memo];
}

- (void)__andExpr {
    
    [self relExpr]; 
    while ([self predicts:TOKEN_KIND_AND, 0]) {
        if ([self speculate:^{ [self andTerm]; }]) {
            [self andTerm]; 
        } else {
            break;
        }
    }

    [self fireAssemblerSelector:@selector(parser:didMatchAndExpr:)];
}

- (void)andExpr {
    [self parseRule:@selector(__andExpr) withMemo:_andExpr_memo];
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
    [self parseRule:@selector(__andTerm) withMemo:_andTerm_memo];
}

- (void)__relExpr {
    
    [self callExpr]; 
    while ([self predicts:TOKEN_KIND_EQUALS, TOKEN_KIND_GE, TOKEN_KIND_GT, TOKEN_KIND_LE, TOKEN_KIND_LT, TOKEN_KIND_NE, 0]) {
        if ([self speculate:^{ [self relOpTerm]; }]) {
            [self relOpTerm]; 
        } else {
            break;
        }
    }

    [self fireAssemblerSelector:@selector(parser:didMatchRelExpr:)];
}

- (void)relExpr {
    [self parseRule:@selector(__relExpr) withMemo:_relExpr_memo];
}

- (void)__relOp {
    
    if ([self predicts:TOKEN_KIND_LT, 0]) {
        [self match:TOKEN_KIND_LT]; 
    } else if ([self predicts:TOKEN_KIND_GT, 0]) {
        [self match:TOKEN_KIND_GT]; 
    } else if ([self predicts:TOKEN_KIND_EQUALS, 0]) {
        [self match:TOKEN_KIND_EQUALS]; 
    } else if ([self predicts:TOKEN_KIND_NE, 0]) {
        [self match:TOKEN_KIND_NE]; 
    } else if ([self predicts:TOKEN_KIND_LE, 0]) {
        [self match:TOKEN_KIND_LE]; 
    } else if ([self predicts:TOKEN_KIND_GE, 0]) {
        [self match:TOKEN_KIND_GE]; 
    } else {
        [self raise:@"no viable alternative found in relOp"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchRelOp:)];
}

- (void)relOp {
    [self parseRule:@selector(__relOp) withMemo:_relOp_memo];
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
    [self parseRule:@selector(__relOpTerm) withMemo:_relOpTerm_memo];
}

- (void)__callExpr {
    
    [self primary]; 
    if ([self speculate:^{ [self match:TOKEN_KIND_OPEN_PAREN]; if ([self speculate:^{ [self argList]; }]) {[self argList]; }[self match:TOKEN_KIND_CLOSE_PAREN]; }]) {
        [self match:TOKEN_KIND_OPEN_PAREN]; 
        if ([self speculate:^{ [self argList]; }]) {
            [self argList]; 
        }
        [self match:TOKEN_KIND_CLOSE_PAREN]; 
    }

    [self fireAssemblerSelector:@selector(parser:didMatchCallExpr:)];
}

- (void)callExpr {
    [self parseRule:@selector(__callExpr) withMemo:_callExpr_memo];
}

- (void)__argList {
    
    [self atom]; 
    while ([self predicts:TOKEN_KIND_COMMA, 0]) {
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
    [self parseRule:@selector(__argList) withMemo:_argList_memo];
}

- (void)__primary {
    
    if ([self predicts:TOKEN_KIND_BUILTIN_NUMBER, TOKEN_KIND_BUILTIN_QUOTEDSTRING, TOKEN_KIND_BUILTIN_WORD, TOKEN_KIND_NO, TOKEN_KIND_NO_UPPER, TOKEN_KIND_YES, TOKEN_KIND_YES_UPPER, 0]) {
        [self atom]; 
    } else if ([self predicts:TOKEN_KIND_OPEN_PAREN, 0]) {
        [self match:TOKEN_KIND_OPEN_PAREN]; 
        [self expr]; 
        [self match:TOKEN_KIND_CLOSE_PAREN]; 
    } else {
        [self raise:@"no viable alternative found in primary"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchPrimary:)];
}

- (void)primary {
    [self parseRule:@selector(__primary) withMemo:_primary_memo];
}

- (void)__atom {
    
    if ([self predicts:TOKEN_KIND_BUILTIN_WORD, 0]) {
        [self obj]; 
    } else if ([self predicts:TOKEN_KIND_BUILTIN_NUMBER, TOKEN_KIND_BUILTIN_QUOTEDSTRING, TOKEN_KIND_NO, TOKEN_KIND_NO_UPPER, TOKEN_KIND_YES, TOKEN_KIND_YES_UPPER, 0]) {
        [self literal]; 
    } else {
        [self raise:@"no viable alternative found in atom"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchAtom:)];
}

- (void)atom {
    [self parseRule:@selector(__atom) withMemo:_atom_memo];
}

- (void)__obj {
    
    [self id]; 
    while ([self predicts:TOKEN_KIND_DOT, 0]) {
        if ([self speculate:^{ [self member]; }]) {
            [self member]; 
        } else {
            break;
        }
    }

    [self fireAssemblerSelector:@selector(parser:didMatchObj:)];
}

- (void)obj {
    [self parseRule:@selector(__obj) withMemo:_obj_memo];
}

- (void)__id {
    
    [self Word]; 

    [self fireAssemblerSelector:@selector(parser:didMatchId:)];
}

- (void)id {
    [self parseRule:@selector(__id) withMemo:_id_memo];
}

- (void)__member {
    
    [self match:TOKEN_KIND_DOT]; 
    [self id]; 

    [self fireAssemblerSelector:@selector(parser:didMatchMember:)];
}

- (void)member {
    [self parseRule:@selector(__member) withMemo:_member_memo];
}

- (void)__literal {
    
    if ([self predicts:TOKEN_KIND_NO, TOKEN_KIND_NO_UPPER, TOKEN_KIND_YES, TOKEN_KIND_YES_UPPER, 0]) {
        [self testAndThrow:(id)^{ return LA(1) != TOKEN_KIND_YES_UPPER; }]; 
        [self bool]; 
        [self execute:(id)^{
             PUSH_BOOL(EQ_IGNORE_CASE(POP_STR(), @"yes")); 
        }];
    } else if ([self predicts:TOKEN_KIND_BUILTIN_NUMBER, 0]) {
        [self Number]; 
        [self execute:(id)^{
             PUSH_FLOAT(POP_FLOAT()); 
        }];
    } else if ([self predicts:TOKEN_KIND_BUILTIN_QUOTEDSTRING, 0]) {
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
    [self parseRule:@selector(__literal) withMemo:_literal_memo];
}

- (void)__bool {
    
    if ([self predicts:TOKEN_KIND_YES, 0]) {
        [self match:TOKEN_KIND_YES]; 
    } else if ([self predicts:TOKEN_KIND_YES_UPPER, 0]) {
        [self match:TOKEN_KIND_YES_UPPER]; 
    } else if ([self predicts:TOKEN_KIND_NO, 0]) {
        [self match:TOKEN_KIND_NO]; 
    } else if ([self predicts:TOKEN_KIND_NO_UPPER, 0]) {
        [self testAndThrow:(id)^{ return NE(LS(1), @"NO"); }]; 
        [self match:TOKEN_KIND_NO_UPPER]; 
    } else {
        [self raise:@"no viable alternative found in bool"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchBool:)];
}

- (void)bool {
    [self parseRule:@selector(__bool) withMemo:_bool_memo];
}

@end