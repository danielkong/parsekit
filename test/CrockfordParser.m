#import "CrockfordParser.h"
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

#define MATCHES(pattern, str)               ([[NSRegularExpression regularExpressionWithPattern:(pattern) options:0                                  error:nil] numberOfMatchesInString:(str) options:0 range:NSMakeRange(0, [(str) length])] > 0)
#define MATCHES_IGNORE_CASE(pattern, str)   ([[NSRegularExpression regularExpressionWithPattern:(pattern) options:NSRegularExpressionCaseInsensitive error:nil] numberOfMatchesInString:(str) options:0 range:NSMakeRange(0, [(str) length])] > 0)

#define ABOVE(fence) [self.assembly objectsAbove:(fence)]

#define LOG(obj) do { NSLog(@"%@", (obj)); } while (0);
#define PRINT(str) do { printf("%s\n", (str)); } while (0);

@interface PKSParser ()
@property (nonatomic, retain) NSMutableDictionary *_tokenKindTab;
@property (nonatomic, retain) NSMutableArray *_tokenKindNameTab;
@property (nonatomic, retain) NSString *_startRuleName;
@property (nonatomic, retain) NSString *_incrementalRuleName;

- (BOOL)_popBool;
- (NSInteger)_popInteger;
- (double)_popDouble;
- (PKToken *)_popToken;
- (NSString *)_popString;

- (void)_pushBool:(BOOL)yn;
- (void)_pushInteger:(NSInteger)i;
- (void)_pushDouble:(double)d;
@end

@interface CrockfordParser ()
@end

@implementation CrockfordParser

- (id)init {
    self = [super init];
    if (self) {
        self._startRuleName = @"program";
        self.enableAutomaticErrorRecovery = YES;

        self._tokenKindTab[@"{"] = @(CROCKFORD_TOKEN_KIND_OPEN_CURLY);
        self._tokenKindTab[@">="] = @(CROCKFORD_TOKEN_KIND_GE);
        self._tokenKindTab[@"&&"] = @(CROCKFORD_TOKEN_KIND_DOUBLE_AMPERSAND);
        self._tokenKindTab[@"for"] = @(CROCKFORD_TOKEN_KIND_FOR);
        self._tokenKindTab[@"break"] = @(CROCKFORD_TOKEN_KIND_BREAK);
        self._tokenKindTab[@"}"] = @(CROCKFORD_TOKEN_KIND_CLOSE_CURLY);
        self._tokenKindTab[@"return"] = @(CROCKFORD_TOKEN_KIND_RETURN);
        self._tokenKindTab[@"+="] = @(CROCKFORD_TOKEN_KIND_PLUS_EQUALS);
        self._tokenKindTab[@"function"] = @(CROCKFORD_TOKEN_KIND_FUNCTION);
        self._tokenKindTab[@"if"] = @(CROCKFORD_TOKEN_KIND_IF);
        self._tokenKindTab[@"new"] = @(CROCKFORD_TOKEN_KIND_NEW);
        self._tokenKindTab[@"else"] = @(CROCKFORD_TOKEN_KIND_ELSE);
        self._tokenKindTab[@"!"] = @(CROCKFORD_TOKEN_KIND_BANG);
        self._tokenKindTab[@"finally"] = @(CROCKFORD_TOKEN_KIND_FINALLY);
        self._tokenKindTab[@":"] = @(CROCKFORD_TOKEN_KIND_COLON);
        self._tokenKindTab[@"catch"] = @(CROCKFORD_TOKEN_KIND_CATCH);
        self._tokenKindTab[@";"] = @(CROCKFORD_TOKEN_KIND_SEMI_COLON);
        self._tokenKindTab[@"do"] = @(CROCKFORD_TOKEN_KIND_DO);
        self._tokenKindTab[@"!=="] = @(CROCKFORD_TOKEN_KIND_DOUBLE_NE);
        self._tokenKindTab[@"<"] = @(CROCKFORD_TOKEN_KIND_LT);
        self._tokenKindTab[@"-="] = @(CROCKFORD_TOKEN_KIND_MINUS_EQUALS);
        self._tokenKindTab[@"%"] = @(CROCKFORD_TOKEN_KIND_PERCENT);
        self._tokenKindTab[@"="] = @(CROCKFORD_TOKEN_KIND_EQUALS);
        self._tokenKindTab[@"throw"] = @(CROCKFORD_TOKEN_KIND_THROW);
        self._tokenKindTab[@"try"] = @(CROCKFORD_TOKEN_KIND_TRY);
        self._tokenKindTab[@">"] = @(CROCKFORD_TOKEN_KIND_GT);
        self._tokenKindTab[@"/,/"] = @(CROCKFORD_TOKEN_KIND_REGEXBODY);
        self._tokenKindTab[@"typeof"] = @(CROCKFORD_TOKEN_KIND_TYPEOF);
        self._tokenKindTab[@"("] = @(CROCKFORD_TOKEN_KIND_OPEN_PAREN);
        self._tokenKindTab[@"while"] = @(CROCKFORD_TOKEN_KIND_WHILE);
        self._tokenKindTab[@"var"] = @(CROCKFORD_TOKEN_KIND_VAR);
        self._tokenKindTab[@")"] = @(CROCKFORD_TOKEN_KIND_CLOSE_PAREN);
        self._tokenKindTab[@"*"] = @(CROCKFORD_TOKEN_KIND_STAR);
        self._tokenKindTab[@"||"] = @(CROCKFORD_TOKEN_KIND_DOUBLE_PIPE);
        self._tokenKindTab[@"+"] = @(CROCKFORD_TOKEN_KIND_PLUS);
        self._tokenKindTab[@"["] = @(CROCKFORD_TOKEN_KIND_OPEN_BRACKET);
        self._tokenKindTab[@","] = @(CROCKFORD_TOKEN_KIND_COMMA);
        self._tokenKindTab[@"delete"] = @(CROCKFORD_TOKEN_KIND_DELETE);
        self._tokenKindTab[@"switch"] = @(CROCKFORD_TOKEN_KIND_SWITCH);
        self._tokenKindTab[@"-"] = @(CROCKFORD_TOKEN_KIND_MINUS);
        self._tokenKindTab[@"in"] = @(CROCKFORD_TOKEN_KIND_IN);
        self._tokenKindTab[@"==="] = @(CROCKFORD_TOKEN_KIND_TRIPLE_EQUALS);
        self._tokenKindTab[@"]"] = @(CROCKFORD_TOKEN_KIND_CLOSE_BRACKET);
        self._tokenKindTab[@"."] = @(CROCKFORD_TOKEN_KIND_DOT);
        self._tokenKindTab[@"default"] = @(CROCKFORD_TOKEN_KIND_DEFAULT);
        self._tokenKindTab[@"/"] = @(CROCKFORD_TOKEN_KIND_FORWARD_SLASH);
        self._tokenKindTab[@"case"] = @(CROCKFORD_TOKEN_KIND_CASE);
        self._tokenKindTab[@"<="] = @(CROCKFORD_TOKEN_KIND_LE);

        self._tokenKindNameTab[CROCKFORD_TOKEN_KIND_OPEN_CURLY] = @"{";
        self._tokenKindNameTab[CROCKFORD_TOKEN_KIND_GE] = @">=";
        self._tokenKindNameTab[CROCKFORD_TOKEN_KIND_DOUBLE_AMPERSAND] = @"&&";
        self._tokenKindNameTab[CROCKFORD_TOKEN_KIND_FOR] = @"for";
        self._tokenKindNameTab[CROCKFORD_TOKEN_KIND_BREAK] = @"break";
        self._tokenKindNameTab[CROCKFORD_TOKEN_KIND_CLOSE_CURLY] = @"}";
        self._tokenKindNameTab[CROCKFORD_TOKEN_KIND_RETURN] = @"return";
        self._tokenKindNameTab[CROCKFORD_TOKEN_KIND_PLUS_EQUALS] = @"+=";
        self._tokenKindNameTab[CROCKFORD_TOKEN_KIND_FUNCTION] = @"function";
        self._tokenKindNameTab[CROCKFORD_TOKEN_KIND_IF] = @"if";
        self._tokenKindNameTab[CROCKFORD_TOKEN_KIND_NEW] = @"new";
        self._tokenKindNameTab[CROCKFORD_TOKEN_KIND_ELSE] = @"else";
        self._tokenKindNameTab[CROCKFORD_TOKEN_KIND_BANG] = @"!";
        self._tokenKindNameTab[CROCKFORD_TOKEN_KIND_FINALLY] = @"finally";
        self._tokenKindNameTab[CROCKFORD_TOKEN_KIND_COLON] = @":";
        self._tokenKindNameTab[CROCKFORD_TOKEN_KIND_CATCH] = @"catch";
        self._tokenKindNameTab[CROCKFORD_TOKEN_KIND_SEMI_COLON] = @";";
        self._tokenKindNameTab[CROCKFORD_TOKEN_KIND_DO] = @"do";
        self._tokenKindNameTab[CROCKFORD_TOKEN_KIND_DOUBLE_NE] = @"!==";
        self._tokenKindNameTab[CROCKFORD_TOKEN_KIND_LT] = @"<";
        self._tokenKindNameTab[CROCKFORD_TOKEN_KIND_MINUS_EQUALS] = @"-=";
        self._tokenKindNameTab[CROCKFORD_TOKEN_KIND_PERCENT] = @"%";
        self._tokenKindNameTab[CROCKFORD_TOKEN_KIND_EQUALS] = @"=";
        self._tokenKindNameTab[CROCKFORD_TOKEN_KIND_THROW] = @"throw";
        self._tokenKindNameTab[CROCKFORD_TOKEN_KIND_TRY] = @"try";
        self._tokenKindNameTab[CROCKFORD_TOKEN_KIND_GT] = @">";
        self._tokenKindNameTab[CROCKFORD_TOKEN_KIND_REGEXBODY] = @"/,/";
        self._tokenKindNameTab[CROCKFORD_TOKEN_KIND_TYPEOF] = @"typeof";
        self._tokenKindNameTab[CROCKFORD_TOKEN_KIND_OPEN_PAREN] = @"(";
        self._tokenKindNameTab[CROCKFORD_TOKEN_KIND_WHILE] = @"while";
        self._tokenKindNameTab[CROCKFORD_TOKEN_KIND_VAR] = @"var";
        self._tokenKindNameTab[CROCKFORD_TOKEN_KIND_CLOSE_PAREN] = @")";
        self._tokenKindNameTab[CROCKFORD_TOKEN_KIND_STAR] = @"*";
        self._tokenKindNameTab[CROCKFORD_TOKEN_KIND_DOUBLE_PIPE] = @"||";
        self._tokenKindNameTab[CROCKFORD_TOKEN_KIND_PLUS] = @"+";
        self._tokenKindNameTab[CROCKFORD_TOKEN_KIND_OPEN_BRACKET] = @"[";
        self._tokenKindNameTab[CROCKFORD_TOKEN_KIND_COMMA] = @",";
        self._tokenKindNameTab[CROCKFORD_TOKEN_KIND_DELETE] = @"delete";
        self._tokenKindNameTab[CROCKFORD_TOKEN_KIND_SWITCH] = @"switch";
        self._tokenKindNameTab[CROCKFORD_TOKEN_KIND_MINUS] = @"-";
        self._tokenKindNameTab[CROCKFORD_TOKEN_KIND_IN] = @"in";
        self._tokenKindNameTab[CROCKFORD_TOKEN_KIND_TRIPLE_EQUALS] = @"===";
        self._tokenKindNameTab[CROCKFORD_TOKEN_KIND_CLOSE_BRACKET] = @"]";
        self._tokenKindNameTab[CROCKFORD_TOKEN_KIND_DOT] = @".";
        self._tokenKindNameTab[CROCKFORD_TOKEN_KIND_DEFAULT] = @"default";
        self._tokenKindNameTab[CROCKFORD_TOKEN_KIND_FORWARD_SLASH] = @"/";
        self._tokenKindNameTab[CROCKFORD_TOKEN_KIND_CASE] = @"case";
        self._tokenKindNameTab[CROCKFORD_TOKEN_KIND_LE] = @"<=";

    }
    return self;
}

- (void)_start {
    [self program];
}

- (void)program {
    
    [self execute:(id)^{
    
        PKTokenizer *t = self.tokenizer;
        
        // whitespace
/*		self.silentlyConsumesWhitespace = YES;
		t.whitespaceState.reportsWhitespaceTokens = YES;
		self.assembly.preservesWhitespaceTokens = YES;
*/
        [t.symbolState add:@"||"];
        [t.symbolState add:@"&&"];
        [t.symbolState add:@"!="];
        [t.symbolState add:@"!=="];
        [t.symbolState add:@"=="];
        [t.symbolState add:@"==="];
        [t.symbolState add:@"<="];
        [t.symbolState add:@">="];
        [t.symbolState add:@"++"];
        [t.symbolState add:@"--"];
        [t.symbolState add:@"+="];
        [t.symbolState add:@"-="];
        [t.symbolState add:@"*="];
        [t.symbolState add:@"/="];
        [t.symbolState add:@"%="];
        [t.symbolState add:@"<<"];
        [t.symbolState add:@">>"];
        [t.symbolState add:@">>>"];
        [t.symbolState add:@"<<="];
        [t.symbolState add:@">>="];
        [t.symbolState add:@">>>="];
        [t.symbolState add:@"&="];
        [t.symbolState add:@"^="];
        [t.symbolState add:@"|="];

        // setup comments
        t.commentState.reportsCommentTokens = YES;
        [t setTokenizerState:t.commentState from:'/' to:'/'];
        [t.commentState addSingleLineStartMarker:@"//"];
        [t.commentState addMultiLineStartMarker:@"/*" endMarker:@"*/"];
        
        // comment state should fallback to delimit state to match regex delimited strings
        t.commentState.fallbackState = t.delimitState;
        
        // regex delimited strings
        NSCharacterSet *cs = [[NSCharacterSet newlineCharacterSet] invertedSet];
        [t.delimitState addStartMarker:@"/" endMarker:@"/" allowedCharacterSet:cs];

    }];
    [self tryAndRecover:TOKEN_KIND_BUILTIN_EOF block:^{
        [self stmts]; 
        [self matchEOF:YES]; 
    } completion:^{
        [self matchEOF:YES];
    }];

    [self fireAssemblerSelector:@selector(parser:didMatchProgram:)];
}

- (void)arrayLiteral {
    
    [self match:CROCKFORD_TOKEN_KIND_OPEN_BRACKET discard:NO]; 
    [self tryAndRecover:CROCKFORD_TOKEN_KIND_CLOSE_BRACKET block:^{ 
        if ([self speculate:^{ [self expr]; while ([self speculate:^{ [self match:CROCKFORD_TOKEN_KIND_COMMA discard:NO]; [self expr]; }]) {[self match:CROCKFORD_TOKEN_KIND_COMMA discard:NO]; [self expr]; }}]) {
            [self expr]; 
            while ([self speculate:^{ [self match:CROCKFORD_TOKEN_KIND_COMMA discard:NO]; [self expr]; }]) {
                [self match:CROCKFORD_TOKEN_KIND_COMMA discard:NO]; 
                [self expr]; 
            }
        }
        [self match:CROCKFORD_TOKEN_KIND_CLOSE_BRACKET discard:NO]; 
    } completion:^{ 
        [self match:CROCKFORD_TOKEN_KIND_CLOSE_BRACKET discard:NO]; 
    }];

    [self fireAssemblerSelector:@selector(parser:didMatchArrayLiteral:)];
}

- (void)block {
    
    [self match:CROCKFORD_TOKEN_KIND_OPEN_CURLY discard:NO]; 
    [self tryAndRecover:CROCKFORD_TOKEN_KIND_CLOSE_CURLY block:^{ 
        if ([self speculate:^{ [self stmts]; }]) {
            [self stmts]; 
        }
        [self match:CROCKFORD_TOKEN_KIND_CLOSE_CURLY discard:NO]; 
    } completion:^{ 
        [self match:CROCKFORD_TOKEN_KIND_CLOSE_CURLY discard:NO]; 
    }];

    [self fireAssemblerSelector:@selector(parser:didMatchBlock:)];
}

- (void)breakStmt {
    
    [self match:CROCKFORD_TOKEN_KIND_BREAK discard:NO]; 
    [self tryAndRecover:CROCKFORD_TOKEN_KIND_SEMI_COLON block:^{ 
        if ([self predicts:TOKEN_KIND_BUILTIN_WORD, 0]) {
            [self name]; 
        }
        [self match:CROCKFORD_TOKEN_KIND_SEMI_COLON discard:NO]; 
    } completion:^{ 
        [self match:CROCKFORD_TOKEN_KIND_SEMI_COLON discard:NO]; 
    }];

    [self fireAssemblerSelector:@selector(parser:didMatchBreakStmt:)];
}

- (void)caseClause {
    
    do {
        [self match:CROCKFORD_TOKEN_KIND_CASE discard:NO]; 
        [self tryAndRecover:CROCKFORD_TOKEN_KIND_COLON block:^{ 
            [self expr]; 
            [self match:CROCKFORD_TOKEN_KIND_COLON discard:NO]; 
        } completion:^{ 
            [self match:CROCKFORD_TOKEN_KIND_COLON discard:NO]; 
        }];
    } while ([self speculate:^{ [self match:CROCKFORD_TOKEN_KIND_CASE discard:NO]; [self tryAndRecover:CROCKFORD_TOKEN_KIND_COLON block:^{ [self expr]; [self match:CROCKFORD_TOKEN_KIND_COLON discard:NO]; } completion:^{ [self match:CROCKFORD_TOKEN_KIND_COLON discard:NO]; }];}]);
    [self stmts]; 

    [self fireAssemblerSelector:@selector(parser:didMatchCaseClause:)];
}

- (void)disruptiveStmt {
    
    if ([self predicts:CROCKFORD_TOKEN_KIND_BREAK, 0]) {
        [self breakStmt]; 
    } else if ([self predicts:CROCKFORD_TOKEN_KIND_RETURN, 0]) {
        [self returnStmt]; 
    } else if ([self predicts:CROCKFORD_TOKEN_KIND_THROW, 0]) {
        [self throwStmt]; 
    } else {
        [self raise:@"No viable alternative found in rule 'disruptiveStmt'."];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchDisruptiveStmt:)];
}

- (void)doStmt {
    
    [self match:CROCKFORD_TOKEN_KIND_DO discard:NO]; 
    [self tryAndRecover:CROCKFORD_TOKEN_KIND_WHILE block:^{ 
        [self block]; 
        [self match:CROCKFORD_TOKEN_KIND_WHILE discard:NO]; 
    } completion:^{ 
        [self match:CROCKFORD_TOKEN_KIND_WHILE discard:NO]; 
    }];
    [self tryAndRecover:CROCKFORD_TOKEN_KIND_OPEN_PAREN block:^{ 
        [self match:CROCKFORD_TOKEN_KIND_OPEN_PAREN discard:NO]; 
    } completion:^{ 
        [self match:CROCKFORD_TOKEN_KIND_OPEN_PAREN discard:NO]; 
    }];
    [self tryAndRecover:CROCKFORD_TOKEN_KIND_CLOSE_PAREN block:^{ 
        [self expr]; 
        [self match:CROCKFORD_TOKEN_KIND_CLOSE_PAREN discard:NO]; 
    } completion:^{ 
        [self match:CROCKFORD_TOKEN_KIND_CLOSE_PAREN discard:NO]; 
    }];
    [self tryAndRecover:CROCKFORD_TOKEN_KIND_SEMI_COLON block:^{ 
        [self match:CROCKFORD_TOKEN_KIND_SEMI_COLON discard:NO]; 
    } completion:^{ 
        [self match:CROCKFORD_TOKEN_KIND_SEMI_COLON discard:NO]; 
    }];

    [self fireAssemblerSelector:@selector(parser:didMatchDoStmt:)];
}

- (void)escapedChar {
    
    [self matchSymbol:NO]; 

    [self fireAssemblerSelector:@selector(parser:didMatchEscapedChar:)];
}

- (void)exponent {
    
    [self matchNumber:NO]; 

    [self fireAssemblerSelector:@selector(parser:didMatchExponent:)];
}

- (void)expr {
    
    if ([self predicts:CROCKFORD_TOKEN_KIND_FUNCTION, CROCKFORD_TOKEN_KIND_OPEN_BRACKET, CROCKFORD_TOKEN_KIND_OPEN_CURLY, CROCKFORD_TOKEN_KIND_REGEXBODY, TOKEN_KIND_BUILTIN_NUMBER, TOKEN_KIND_BUILTIN_QUOTEDSTRING, 0]) {
        [self literal]; 
    } else if ([self predicts:TOKEN_KIND_BUILTIN_WORD, 0]) {
        [self name]; 
    } else if ([self predicts:CROCKFORD_TOKEN_KIND_OPEN_PAREN, 0]) {
        [self match:CROCKFORD_TOKEN_KIND_OPEN_PAREN discard:NO]; 
        [self tryAndRecover:CROCKFORD_TOKEN_KIND_CLOSE_PAREN block:^{ 
            [self expr]; 
            [self match:CROCKFORD_TOKEN_KIND_CLOSE_PAREN discard:NO]; 
        } completion:^{ 
            [self match:CROCKFORD_TOKEN_KIND_CLOSE_PAREN discard:NO]; 
        }];
    } else if ([self predicts:CROCKFORD_TOKEN_KIND_BANG, CROCKFORD_TOKEN_KIND_TYPEOF, 0]) {
        [self prefixOp]; 
        [self expr]; 
    } else if ([self predicts:CROCKFORD_TOKEN_KIND_NEW, 0]) {
        [self match:CROCKFORD_TOKEN_KIND_NEW discard:NO]; 
        [self expr]; 
        [self invocation]; 
    } else if ([self predicts:CROCKFORD_TOKEN_KIND_DELETE, 0]) {
        [self match:CROCKFORD_TOKEN_KIND_DELETE discard:NO]; 
        [self expr]; 
        [self refinement]; 
    } else {
        [self raise:@"No viable alternative found in rule 'expr'."];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchExpr:)];
}

- (void)exprStmt {
    
    if ([self speculate:^{ do {[self tryAndRecover:CROCKFORD_TOKEN_KIND_EQUALS block:^{ [self name]; while ([self speculate:^{ [self refinement]; }]) {[self refinement]; }[self match:CROCKFORD_TOKEN_KIND_EQUALS discard:NO]; } completion:^{ [self match:CROCKFORD_TOKEN_KIND_EQUALS discard:NO]; }];} while ([self speculate:^{ [self tryAndRecover:CROCKFORD_TOKEN_KIND_EQUALS block:^{ [self name]; while ([self speculate:^{ [self refinement]; }]) {[self refinement]; }[self match:CROCKFORD_TOKEN_KIND_EQUALS discard:NO]; } completion:^{ [self match:CROCKFORD_TOKEN_KIND_EQUALS discard:NO]; }];}]);[self expr]; }]) {
        do {
            [self tryAndRecover:CROCKFORD_TOKEN_KIND_EQUALS block:^{ 
                [self name]; 
                while ([self speculate:^{ [self refinement]; }]) {
                    [self refinement]; 
                }
                [self match:CROCKFORD_TOKEN_KIND_EQUALS discard:NO]; 
            } completion:^{ 
                [self match:CROCKFORD_TOKEN_KIND_EQUALS discard:NO]; 
            }];
        } while ([self speculate:^{ [self tryAndRecover:CROCKFORD_TOKEN_KIND_EQUALS block:^{ [self name]; while ([self speculate:^{ [self refinement]; }]) {[self refinement]; }[self match:CROCKFORD_TOKEN_KIND_EQUALS discard:NO]; } completion:^{ [self match:CROCKFORD_TOKEN_KIND_EQUALS discard:NO]; }];}]);
        [self expr]; 
    } else if ([self speculate:^{ [self name]; while ([self speculate:^{ [self refinement]; }]) {[self refinement]; }if ([self predicts:CROCKFORD_TOKEN_KIND_PLUS_EQUALS, 0]) {[self match:CROCKFORD_TOKEN_KIND_PLUS_EQUALS discard:NO]; } else if ([self predicts:CROCKFORD_TOKEN_KIND_MINUS_EQUALS, 0]) {[self match:CROCKFORD_TOKEN_KIND_MINUS_EQUALS discard:NO]; } else {[self raise:@"No viable alternative found in rule 'exprStmt'."];}[self expr]; }]) {
        [self name]; 
        while ([self speculate:^{ [self refinement]; }]) {
            [self refinement]; 
        }
        if ([self predicts:CROCKFORD_TOKEN_KIND_PLUS_EQUALS, 0]) {
            [self match:CROCKFORD_TOKEN_KIND_PLUS_EQUALS discard:NO]; 
        } else if ([self predicts:CROCKFORD_TOKEN_KIND_MINUS_EQUALS, 0]) {
            [self match:CROCKFORD_TOKEN_KIND_MINUS_EQUALS discard:NO]; 
        } else {
            [self raise:@"No viable alternative found in rule 'exprStmt'."];
        }
        [self expr]; 
    } else if ([self speculate:^{ [self name]; while ([self speculate:^{ [self refinement]; }]) {[self refinement]; }do {[self invocation]; } while ([self speculate:^{ [self invocation]; }]);}]) {
        [self name]; 
        while ([self speculate:^{ [self refinement]; }]) {
            [self refinement]; 
        }
        do {
            [self invocation]; 
        } while ([self speculate:^{ [self invocation]; }]);
    } else if ([self speculate:^{ [self match:CROCKFORD_TOKEN_KIND_DELETE discard:NO]; [self expr]; [self refinement]; }]) {
        [self match:CROCKFORD_TOKEN_KIND_DELETE discard:NO]; 
        [self expr]; 
        [self refinement]; 
    } else {
        [self raise:@"No viable alternative found in rule 'exprStmt'."];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchExprStmt:)];
}

- (void)forStmt {
    
    if ([self predicts:CROCKFORD_TOKEN_KIND_FOR, 0]) {
        [self match:CROCKFORD_TOKEN_KIND_FOR discard:NO]; 
        [self tryAndRecover:CROCKFORD_TOKEN_KIND_OPEN_PAREN block:^{ 
            [self match:CROCKFORD_TOKEN_KIND_OPEN_PAREN discard:NO]; 
        } completion:^{ 
            [self match:CROCKFORD_TOKEN_KIND_OPEN_PAREN discard:NO]; 
        }];
            [self tryAndRecover:CROCKFORD_TOKEN_KIND_SEMI_COLON block:^{ 
                if ([self speculate:^{ [self exprStmt]; }]) {
                    [self exprStmt]; 
                }
                [self match:CROCKFORD_TOKEN_KIND_SEMI_COLON discard:NO]; 
            } completion:^{ 
                [self match:CROCKFORD_TOKEN_KIND_SEMI_COLON discard:NO]; 
            }];
            [self tryAndRecover:CROCKFORD_TOKEN_KIND_SEMI_COLON block:^{ 
                if ([self speculate:^{ [self expr]; }]) {
                    [self expr]; 
                }
                [self match:CROCKFORD_TOKEN_KIND_SEMI_COLON discard:NO]; 
            } completion:^{ 
                [self match:CROCKFORD_TOKEN_KIND_SEMI_COLON discard:NO]; 
            }];
                if ([self speculate:^{ [self exprStmt]; }]) {
                    [self exprStmt]; 
                }
            } else if ([self predicts:TOKEN_KIND_BUILTIN_WORD, 0]) {
                    [self tryAndRecover:CROCKFORD_TOKEN_KIND_CLOSE_PAREN block:^{ 
                    [self tryAndRecover:CROCKFORD_TOKEN_KIND_IN block:^{ 
                        [self name]; 
                        [self match:CROCKFORD_TOKEN_KIND_IN discard:NO]; 
                    } completion:^{ 
                        [self match:CROCKFORD_TOKEN_KIND_IN discard:NO]; 
                    }];
                        [self expr]; 
                        [self match:CROCKFORD_TOKEN_KIND_CLOSE_PAREN discard:NO]; 
                    } completion:^{ 
                        [self match:CROCKFORD_TOKEN_KIND_CLOSE_PAREN discard:NO]; 
                    }];
                        [self block]; 
                    } else {
                        [self raise:@"No viable alternative found in rule 'forStmt'."];
                    }

    [self fireAssemblerSelector:@selector(parser:didMatchForStmt:)];
}

- (void)fraction {
    
    [self matchNumber:NO]; 

    [self fireAssemblerSelector:@selector(parser:didMatchFraction:)];
}

- (void)function {
    
    [self match:CROCKFORD_TOKEN_KIND_FUNCTION discard:NO]; 
    [self name]; 
    [self parameters]; 
    [self functionBody]; 

    [self fireAssemblerSelector:@selector(parser:didMatchFunction:)];
}

- (void)functionBody {
    
    [self match:CROCKFORD_TOKEN_KIND_OPEN_CURLY discard:NO]; 
    [self tryAndRecover:CROCKFORD_TOKEN_KIND_CLOSE_CURLY block:^{ 
        [self stmts]; 
        [self match:CROCKFORD_TOKEN_KIND_CLOSE_CURLY discard:NO]; 
    } completion:^{ 
        [self match:CROCKFORD_TOKEN_KIND_CLOSE_CURLY discard:NO]; 
    }];

    [self fireAssemblerSelector:@selector(parser:didMatchFunctionBody:)];
}

- (void)functionLiteral {
    
    [self match:CROCKFORD_TOKEN_KIND_FUNCTION discard:NO]; 
    if ([self predicts:TOKEN_KIND_BUILTIN_WORD, 0]) {
        [self name]; 
    }
    [self parameters]; 
    [self functionBody]; 

    [self fireAssemblerSelector:@selector(parser:didMatchFunctionLiteral:)];
}

- (void)ifStmt {
    
    [self match:CROCKFORD_TOKEN_KIND_IF discard:NO]; 
    [self tryAndRecover:CROCKFORD_TOKEN_KIND_OPEN_PAREN block:^{ 
        [self match:CROCKFORD_TOKEN_KIND_OPEN_PAREN discard:NO]; 
    } completion:^{ 
        [self match:CROCKFORD_TOKEN_KIND_OPEN_PAREN discard:NO]; 
    }];
    [self tryAndRecover:CROCKFORD_TOKEN_KIND_CLOSE_PAREN block:^{ 
        [self expr]; 
        [self match:CROCKFORD_TOKEN_KIND_CLOSE_PAREN discard:NO]; 
    } completion:^{ 
        [self match:CROCKFORD_TOKEN_KIND_CLOSE_PAREN discard:NO]; 
    }];
        [self block]; 
        if ([self speculate:^{ [self match:CROCKFORD_TOKEN_KIND_ELSE discard:NO]; if ([self speculate:^{ [self ifStmt]; }]) {[self ifStmt]; }[self block]; }]) {
            [self match:CROCKFORD_TOKEN_KIND_ELSE discard:NO]; 
            if ([self speculate:^{ [self ifStmt]; }]) {
                [self ifStmt]; 
            }
            [self block]; 
        }

    [self fireAssemblerSelector:@selector(parser:didMatchIfStmt:)];
}

- (void)infixOp {
    
    if ([self predicts:CROCKFORD_TOKEN_KIND_STAR, 0]) {
        [self match:CROCKFORD_TOKEN_KIND_STAR discard:NO]; 
    } else if ([self predicts:CROCKFORD_TOKEN_KIND_FORWARD_SLASH, 0]) {
        [self match:CROCKFORD_TOKEN_KIND_FORWARD_SLASH discard:NO]; 
    } else if ([self predicts:CROCKFORD_TOKEN_KIND_PERCENT, 0]) {
        [self match:CROCKFORD_TOKEN_KIND_PERCENT discard:NO]; 
    } else if ([self predicts:CROCKFORD_TOKEN_KIND_PLUS, 0]) {
        [self match:CROCKFORD_TOKEN_KIND_PLUS discard:NO]; 
    } else if ([self predicts:CROCKFORD_TOKEN_KIND_MINUS, 0]) {
        [self match:CROCKFORD_TOKEN_KIND_MINUS discard:NO]; 
    } else if ([self predicts:CROCKFORD_TOKEN_KIND_GE, 0]) {
        [self match:CROCKFORD_TOKEN_KIND_GE discard:NO]; 
    } else if ([self predicts:CROCKFORD_TOKEN_KIND_LE, 0]) {
        [self match:CROCKFORD_TOKEN_KIND_LE discard:NO]; 
    } else if ([self predicts:CROCKFORD_TOKEN_KIND_GT, 0]) {
        [self match:CROCKFORD_TOKEN_KIND_GT discard:NO]; 
    } else if ([self predicts:CROCKFORD_TOKEN_KIND_LT, 0]) {
        [self match:CROCKFORD_TOKEN_KIND_LT discard:NO]; 
    } else if ([self predicts:CROCKFORD_TOKEN_KIND_TRIPLE_EQUALS, 0]) {
        [self match:CROCKFORD_TOKEN_KIND_TRIPLE_EQUALS discard:NO]; 
    } else if ([self predicts:CROCKFORD_TOKEN_KIND_DOUBLE_NE, 0]) {
        [self match:CROCKFORD_TOKEN_KIND_DOUBLE_NE discard:NO]; 
    } else if ([self predicts:CROCKFORD_TOKEN_KIND_DOUBLE_PIPE, 0]) {
        [self match:CROCKFORD_TOKEN_KIND_DOUBLE_PIPE discard:NO]; 
    } else if ([self predicts:CROCKFORD_TOKEN_KIND_DOUBLE_AMPERSAND, 0]) {
        [self match:CROCKFORD_TOKEN_KIND_DOUBLE_AMPERSAND discard:NO]; 
    } else {
        [self raise:@"No viable alternative found in rule 'infixOp'."];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchInfixOp:)];
}

- (void)integer {
    
    [self matchNumber:NO]; 

    [self fireAssemblerSelector:@selector(parser:didMatchInteger:)];
}

- (void)invocation {
    
    [self match:CROCKFORD_TOKEN_KIND_OPEN_PAREN discard:NO]; 
    [self tryAndRecover:CROCKFORD_TOKEN_KIND_CLOSE_PAREN block:^{ 
        if ([self speculate:^{ [self expr]; while ([self speculate:^{ [self match:CROCKFORD_TOKEN_KIND_COMMA discard:NO]; [self expr]; }]) {[self match:CROCKFORD_TOKEN_KIND_COMMA discard:NO]; [self expr]; }}]) {
            [self expr]; 
            while ([self speculate:^{ [self match:CROCKFORD_TOKEN_KIND_COMMA discard:NO]; [self expr]; }]) {
                [self match:CROCKFORD_TOKEN_KIND_COMMA discard:NO]; 
                [self expr]; 
            }
        }
        [self match:CROCKFORD_TOKEN_KIND_CLOSE_PAREN discard:NO]; 
    } completion:^{ 
        [self match:CROCKFORD_TOKEN_KIND_CLOSE_PAREN discard:NO]; 
    }];

    [self fireAssemblerSelector:@selector(parser:didMatchInvocation:)];
}

- (void)literal {
    
    if ([self predicts:TOKEN_KIND_BUILTIN_NUMBER, 0]) {
        [self numberLiteral]; 
    } else if ([self predicts:TOKEN_KIND_BUILTIN_QUOTEDSTRING, 0]) {
        [self stringLiteral]; 
    } else if ([self predicts:CROCKFORD_TOKEN_KIND_OPEN_CURLY, 0]) {
        [self objectLiteral]; 
    } else if ([self predicts:CROCKFORD_TOKEN_KIND_OPEN_BRACKET, 0]) {
        [self arrayLiteral]; 
    } else if ([self predicts:CROCKFORD_TOKEN_KIND_FUNCTION, 0]) {
        [self functionLiteral]; 
    } else if ([self predicts:CROCKFORD_TOKEN_KIND_REGEXBODY, 0]) {
        [self regexLiteral]; 
    } else {
        [self raise:@"No viable alternative found in rule 'literal'."];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchLiteral:)];
}

- (void)name {
    
    [self matchWord:NO]; 

    [self fireAssemblerSelector:@selector(parser:didMatchName:)];
}

- (void)numberLiteral {
    
    [self matchNumber:NO]; 

    [self fireAssemblerSelector:@selector(parser:didMatchNumberLiteral:)];
}

- (void)objectLiteral {
    
    [self match:CROCKFORD_TOKEN_KIND_OPEN_CURLY discard:NO]; 
    [self tryAndRecover:CROCKFORD_TOKEN_KIND_CLOSE_CURLY block:^{ 
        if ([self speculate:^{ [self nameValPair]; while ([self speculate:^{ [self match:CROCKFORD_TOKEN_KIND_COMMA discard:NO]; [self nameValPair]; }]) {[self match:CROCKFORD_TOKEN_KIND_COMMA discard:NO]; [self nameValPair]; }}]) {
            [self nameValPair]; 
            while ([self speculate:^{ [self match:CROCKFORD_TOKEN_KIND_COMMA discard:NO]; [self nameValPair]; }]) {
                [self match:CROCKFORD_TOKEN_KIND_COMMA discard:NO]; 
                [self nameValPair]; 
            }
        }
        [self match:CROCKFORD_TOKEN_KIND_CLOSE_CURLY discard:NO]; 
    } completion:^{ 
        [self match:CROCKFORD_TOKEN_KIND_CLOSE_CURLY discard:NO]; 
    }];

    [self fireAssemblerSelector:@selector(parser:didMatchObjectLiteral:)];
}

- (void)nameValPair {
    
    [self tryAndRecover:CROCKFORD_TOKEN_KIND_COLON block:^{ 
        if ([self predicts:TOKEN_KIND_BUILTIN_WORD, 0]) {
            [self name]; 
        } else if ([self predicts:TOKEN_KIND_BUILTIN_QUOTEDSTRING, 0]) {
            [self stringLiteral]; 
        } else {
            [self raise:@"No viable alternative found in rule 'nameValPair'."];
        }
        [self match:CROCKFORD_TOKEN_KIND_COLON discard:NO]; 
    } completion:^{ 
        [self match:CROCKFORD_TOKEN_KIND_COLON discard:NO]; 
    }];
        [self expr]; 

    [self fireAssemblerSelector:@selector(parser:didMatchNameValPair:)];
}

- (void)parameters {
    
    [self match:CROCKFORD_TOKEN_KIND_OPEN_PAREN discard:NO]; 
    [self tryAndRecover:CROCKFORD_TOKEN_KIND_CLOSE_PAREN block:^{ 
        if ([self speculate:^{ [self name]; while ([self speculate:^{ [self match:CROCKFORD_TOKEN_KIND_COMMA discard:NO]; [self name]; }]) {[self match:CROCKFORD_TOKEN_KIND_COMMA discard:NO]; [self name]; }}]) {
            [self name]; 
            while ([self speculate:^{ [self match:CROCKFORD_TOKEN_KIND_COMMA discard:NO]; [self name]; }]) {
                [self match:CROCKFORD_TOKEN_KIND_COMMA discard:NO]; 
                [self name]; 
            }
        }
        [self match:CROCKFORD_TOKEN_KIND_CLOSE_PAREN discard:NO]; 
    } completion:^{ 
        [self match:CROCKFORD_TOKEN_KIND_CLOSE_PAREN discard:NO]; 
    }];

    [self fireAssemblerSelector:@selector(parser:didMatchParameters:)];
}

- (void)prefixOp {
    
    if ([self predicts:CROCKFORD_TOKEN_KIND_TYPEOF, 0]) {
        [self match:CROCKFORD_TOKEN_KIND_TYPEOF discard:NO]; 
    } else if ([self predicts:CROCKFORD_TOKEN_KIND_BANG, 0]) {
        [self match:CROCKFORD_TOKEN_KIND_BANG discard:NO]; 
    } else {
        [self raise:@"No viable alternative found in rule 'prefixOp'."];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchPrefixOp:)];
}

- (void)refinement {
    
    if ([self predicts:CROCKFORD_TOKEN_KIND_DOT, 0]) {
        [self match:CROCKFORD_TOKEN_KIND_DOT discard:NO]; 
        [self name]; 
    } else if ([self predicts:CROCKFORD_TOKEN_KIND_OPEN_BRACKET, 0]) {
        [self match:CROCKFORD_TOKEN_KIND_OPEN_BRACKET discard:NO]; 
        [self tryAndRecover:CROCKFORD_TOKEN_KIND_CLOSE_BRACKET block:^{ 
            [self expr]; 
            [self match:CROCKFORD_TOKEN_KIND_CLOSE_BRACKET discard:NO]; 
        } completion:^{ 
            [self match:CROCKFORD_TOKEN_KIND_CLOSE_BRACKET discard:NO]; 
        }];
    } else {
        [self raise:@"No viable alternative found in rule 'refinement'."];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchRefinement:)];
}

- (void)regexLiteral {
    
    [self regexBody]; 
    if ([self predicts:TOKEN_KIND_BUILTIN_WORD, 0]) {
        [self regexMods]; 
    }

    [self fireAssemblerSelector:@selector(parser:didMatchRegexLiteral:)];
}

- (void)regexBody {
    
    [self match:CROCKFORD_TOKEN_KIND_REGEXBODY discard:NO]; 

    [self fireAssemblerSelector:@selector(parser:didMatchRegexBody:)];
}

- (void)regexMods {
    
    [self testAndThrow:(id)^{ return MATCHES_IGNORE_CASE(@"[imxs]+", LS(1)); }]; 
    [self matchWord:NO]; 

    [self fireAssemblerSelector:@selector(parser:didMatchRegexMods:)];
}

- (void)returnStmt {
    
    [self match:CROCKFORD_TOKEN_KIND_RETURN discard:NO]; 
    [self tryAndRecover:CROCKFORD_TOKEN_KIND_SEMI_COLON block:^{ 
        if ([self speculate:^{ [self expr]; }]) {
            [self expr]; 
        }
        [self match:CROCKFORD_TOKEN_KIND_SEMI_COLON discard:NO]; 
    } completion:^{ 
        [self match:CROCKFORD_TOKEN_KIND_SEMI_COLON discard:NO]; 
    }];

    [self fireAssemblerSelector:@selector(parser:didMatchReturnStmt:)];
}

- (void)stmts {
    
    while ([self speculate:^{ [self stmt]; }]) {
        [self stmt]; 
    }

    [self fireAssemblerSelector:@selector(parser:didMatchStmts:)];
}

- (void)stmt {
    
    if ([self predicts:CROCKFORD_TOKEN_KIND_VAR, 0]) {
        [self varStmt]; 
    } else if ([self predicts:CROCKFORD_TOKEN_KIND_FUNCTION, 0]) {
        [self function]; 
    } else if ([self predicts:TOKEN_KIND_BUILTIN_WORD, 0]) {
        [self nonFunction]; 
    } else {
        [self raise:@"No viable alternative found in rule 'stmt'."];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchStmt:)];
}

- (void)nonFunction {
    
    if ([self speculate:^{ [self tryAndRecover:CROCKFORD_TOKEN_KIND_COLON block:^{ [self name]; [self match:CROCKFORD_TOKEN_KIND_COLON discard:NO]; } completion:^{ [self match:CROCKFORD_TOKEN_KIND_COLON discard:NO]; }];}]) {
        [self tryAndRecover:CROCKFORD_TOKEN_KIND_COLON block:^{ 
            [self name]; 
            [self match:CROCKFORD_TOKEN_KIND_COLON discard:NO]; 
        } completion:^{ 
            [self match:CROCKFORD_TOKEN_KIND_COLON discard:NO]; 
        }];
    }
    if ([self speculate:^{ [self tryAndRecover:CROCKFORD_TOKEN_KIND_SEMI_COLON block:^{ [self exprStmt]; [self match:CROCKFORD_TOKEN_KIND_SEMI_COLON discard:NO]; } completion:^{ [self match:CROCKFORD_TOKEN_KIND_SEMI_COLON discard:NO]; }];}]) {
        [self tryAndRecover:CROCKFORD_TOKEN_KIND_SEMI_COLON block:^{ 
            [self exprStmt]; 
            [self match:CROCKFORD_TOKEN_KIND_SEMI_COLON discard:NO]; 
        } completion:^{ 
            [self match:CROCKFORD_TOKEN_KIND_SEMI_COLON discard:NO]; 
        }];
    } else if ([self speculate:^{ [self disruptiveStmt]; }]) {
        [self disruptiveStmt]; 
    } else if ([self speculate:^{ [self tryStmt]; }]) {
        [self tryStmt]; 
    } else if ([self speculate:^{ [self ifStmt]; }]) {
        [self ifStmt]; 
    } else if ([self speculate:^{ [self switchStmt]; }]) {
        [self switchStmt]; 
    } else if ([self speculate:^{ [self whileStmt]; }]) {
        [self whileStmt]; 
    } else if ([self speculate:^{ [self forStmt]; }]) {
        [self forStmt]; 
    } else if ([self speculate:^{ [self doStmt]; }]) {
        [self doStmt]; 
    } else {
        [self raise:@"No viable alternative found in rule 'nonFunction'."];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchNonFunction:)];
}

- (void)stringLiteral {
    
    [self matchQuotedString:NO]; 

    [self fireAssemblerSelector:@selector(parser:didMatchStringLiteral:)];
}

- (void)switchStmt {
    
    [self match:CROCKFORD_TOKEN_KIND_SWITCH discard:NO]; 
    [self tryAndRecover:CROCKFORD_TOKEN_KIND_OPEN_PAREN block:^{ 
        [self match:CROCKFORD_TOKEN_KIND_OPEN_PAREN discard:NO]; 
    } completion:^{ 
        [self match:CROCKFORD_TOKEN_KIND_OPEN_PAREN discard:NO]; 
    }];
    [self tryAndRecover:CROCKFORD_TOKEN_KIND_CLOSE_PAREN block:^{ 
        [self expr]; 
        [self match:CROCKFORD_TOKEN_KIND_CLOSE_PAREN discard:NO]; 
    } completion:^{ 
        [self match:CROCKFORD_TOKEN_KIND_CLOSE_PAREN discard:NO]; 
    }];
    [self tryAndRecover:CROCKFORD_TOKEN_KIND_OPEN_CURLY block:^{ 
        [self match:CROCKFORD_TOKEN_KIND_OPEN_CURLY discard:NO]; 
    } completion:^{ 
        [self match:CROCKFORD_TOKEN_KIND_OPEN_CURLY discard:NO]; 
    }];
            [self tryAndRecover:CROCKFORD_TOKEN_KIND_CLOSE_CURLY block:^{ 
        do {
            [self caseClause]; 
            if ([self speculate:^{ [self disruptiveStmt]; }]) {
                [self disruptiveStmt]; 
            }
        } while ([self speculate:^{ [self caseClause]; if ([self speculate:^{ [self disruptiveStmt]; }]) {[self disruptiveStmt]; }}]);
                if ([self speculate:^{ [self match:CROCKFORD_TOKEN_KIND_DEFAULT discard:NO]; [self tryAndRecover:CROCKFORD_TOKEN_KIND_COLON block:^{ [self match:CROCKFORD_TOKEN_KIND_COLON discard:NO]; } completion:^{ [self match:CROCKFORD_TOKEN_KIND_COLON discard:NO]; }];[self stmts]; }]) {
                [self match:CROCKFORD_TOKEN_KIND_DEFAULT discard:NO]; 
                [self tryAndRecover:CROCKFORD_TOKEN_KIND_COLON block:^{ 
                    [self match:CROCKFORD_TOKEN_KIND_COLON discard:NO]; 
                } completion:^{ 
                    [self match:CROCKFORD_TOKEN_KIND_COLON discard:NO]; 
                }];
                    [self stmts]; 
                }
                [self match:CROCKFORD_TOKEN_KIND_CLOSE_CURLY discard:NO]; 
            } completion:^{ 
                [self match:CROCKFORD_TOKEN_KIND_CLOSE_CURLY discard:NO]; 
            }];

    [self fireAssemblerSelector:@selector(parser:didMatchSwitchStmt:)];
}

- (void)throwStmt {
    
    [self match:CROCKFORD_TOKEN_KIND_THROW discard:NO]; 
    [self tryAndRecover:CROCKFORD_TOKEN_KIND_SEMI_COLON block:^{ 
        [self expr]; 
        [self match:CROCKFORD_TOKEN_KIND_SEMI_COLON discard:NO]; 
    } completion:^{ 
        [self match:CROCKFORD_TOKEN_KIND_SEMI_COLON discard:NO]; 
    }];

    [self fireAssemblerSelector:@selector(parser:didMatchThrowStmt:)];
}

- (void)tryStmt {
    
    [self match:CROCKFORD_TOKEN_KIND_TRY discard:NO]; 
    [self tryAndRecover:CROCKFORD_TOKEN_KIND_CATCH block:^{ 
        [self block]; 
        [self match:CROCKFORD_TOKEN_KIND_CATCH discard:NO]; 
    } completion:^{ 
        [self match:CROCKFORD_TOKEN_KIND_CATCH discard:NO]; 
    }];
    [self tryAndRecover:CROCKFORD_TOKEN_KIND_OPEN_PAREN block:^{ 
        [self match:CROCKFORD_TOKEN_KIND_OPEN_PAREN discard:NO]; 
    } completion:^{ 
        [self match:CROCKFORD_TOKEN_KIND_OPEN_PAREN discard:NO]; 
    }];
    [self tryAndRecover:CROCKFORD_TOKEN_KIND_CLOSE_PAREN block:^{ 
        [self name]; 
        [self match:CROCKFORD_TOKEN_KIND_CLOSE_PAREN discard:NO]; 
    } completion:^{ 
        [self match:CROCKFORD_TOKEN_KIND_CLOSE_PAREN discard:NO]; 
    }];
        [self block]; 
        if ([self speculate:^{ [self match:CROCKFORD_TOKEN_KIND_FINALLY discard:NO]; [self block]; }]) {
            [self match:CROCKFORD_TOKEN_KIND_FINALLY discard:NO]; 
            [self block]; 
        }

    [self fireAssemblerSelector:@selector(parser:didMatchTryStmt:)];
}

- (void)varStmt {
    
    while ([self speculate:^{ [self match:CROCKFORD_TOKEN_KIND_VAR discard:NO]; [self tryAndRecover:CROCKFORD_TOKEN_KIND_SEMI_COLON block:^{ [self nameExprPair]; while ([self speculate:^{ [self match:CROCKFORD_TOKEN_KIND_COMMA discard:NO]; [self nameExprPair]; }]) {[self match:CROCKFORD_TOKEN_KIND_COMMA discard:NO]; [self nameExprPair]; }[self match:CROCKFORD_TOKEN_KIND_SEMI_COLON discard:NO]; } completion:^{ [self match:CROCKFORD_TOKEN_KIND_SEMI_COLON discard:NO]; }];}]) {
        [self match:CROCKFORD_TOKEN_KIND_VAR discard:NO]; 
        [self tryAndRecover:CROCKFORD_TOKEN_KIND_SEMI_COLON block:^{ 
            [self nameExprPair]; 
            while ([self speculate:^{ [self match:CROCKFORD_TOKEN_KIND_COMMA discard:NO]; [self nameExprPair]; }]) {
                [self match:CROCKFORD_TOKEN_KIND_COMMA discard:NO]; 
                [self nameExprPair]; 
            }
            [self match:CROCKFORD_TOKEN_KIND_SEMI_COLON discard:NO]; 
        } completion:^{ 
            [self match:CROCKFORD_TOKEN_KIND_SEMI_COLON discard:NO]; 
        }];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchVarStmt:)];
}

- (void)nameExprPair {
    
    [self name]; 
    if ([self speculate:^{ [self match:CROCKFORD_TOKEN_KIND_EQUALS discard:NO]; [self expr]; }]) {
        [self match:CROCKFORD_TOKEN_KIND_EQUALS discard:NO]; 
        [self expr]; 
    }

    [self fireAssemblerSelector:@selector(parser:didMatchNameExprPair:)];
}

- (void)whileStmt {
    
    [self match:CROCKFORD_TOKEN_KIND_WHILE discard:NO]; 
    [self tryAndRecover:CROCKFORD_TOKEN_KIND_OPEN_PAREN block:^{ 
        [self match:CROCKFORD_TOKEN_KIND_OPEN_PAREN discard:NO]; 
    } completion:^{ 
        [self match:CROCKFORD_TOKEN_KIND_OPEN_PAREN discard:NO]; 
    }];
    [self tryAndRecover:CROCKFORD_TOKEN_KIND_CLOSE_PAREN block:^{ 
        [self expr]; 
        [self match:CROCKFORD_TOKEN_KIND_CLOSE_PAREN discard:NO]; 
    } completion:^{ 
        [self match:CROCKFORD_TOKEN_KIND_CLOSE_PAREN discard:NO]; 
    }];
        [self block]; 

    [self fireAssemblerSelector:@selector(parser:didMatchWhileStmt:)];
}

@end