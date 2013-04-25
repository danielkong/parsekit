#import "OKJavaScriptParser.h"
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

#define ABOVE(fence) [self.assembly objectsAbove:(fence)]

#define LOG(obj) do { NSLog(@"%@", (obj)); } while (0);
#define PRINT(str) do { printf("%s\n", (str)); } while (0);

@interface PKSParser ()
@property (nonatomic, retain) NSMutableDictionary *_tokenKindTab;

- (BOOL)_popBool;
- (NSInteger)_popInteger;
- (double)_popDouble;
- (PKToken *)_popToken;
- (NSString *)_popString;

- (void)_pushBool:(BOOL)yn;
- (void)_pushInteger:(NSInteger)i;
- (void)_pushDouble:(double)d;

- (void)fireSyntaxSelector:(SEL)sel withRuleName:(NSString *)ruleName;
@end

@interface OKJavaScriptParser ()
@end

@implementation OKJavaScriptParser

- (id)init {
    self = [super init];
    if (self) {
        self._tokenKindTab[@"|"] = @(OKJAVASCRIPT_TOKEN_KIND_PIPE);
        self._tokenKindTab[@"!="] = @(OKJAVASCRIPT_TOKEN_KIND_NE);
        self._tokenKindTab[@"("] = @(OKJAVASCRIPT_TOKEN_KIND_OPENPAREN);
        self._tokenKindTab[@"}"] = @(OKJAVASCRIPT_TOKEN_KIND_CLOSECURLY);
        self._tokenKindTab[@"return"] = @(OKJAVASCRIPT_TOKEN_KIND_RETURN);
        self._tokenKindTab[@"~"] = @(OKJAVASCRIPT_TOKEN_KIND_TILDE);
        self._tokenKindTab[@")"] = @(OKJAVASCRIPT_TOKEN_KIND_CLOSEPAREN);
        self._tokenKindTab[@"*"] = @(OKJAVASCRIPT_TOKEN_KIND_TIMES);
        self._tokenKindTab[@"delete"] = @(OKJAVASCRIPT_TOKEN_KIND_DELETE);
        self._tokenKindTab[@"!=="] = @(OKJAVASCRIPT_TOKEN_KIND_ISNOT);
        self._tokenKindTab[@"+"] = @(OKJAVASCRIPT_TOKEN_KIND_PLUS);
        self._tokenKindTab[@"*="] = @(OKJAVASCRIPT_TOKEN_KIND_TIMESEQ);
        self._tokenKindTab[@"instanceof"] = @(OKJAVASCRIPT_TOKEN_KIND_INSTANCEOF);
        self._tokenKindTab[@","] = @(OKJAVASCRIPT_TOKEN_KIND_COMMA);
        self._tokenKindTab[@"<<="] = @(OKJAVASCRIPT_TOKEN_KIND_SHIFTLEFTEQ);
        self._tokenKindTab[@"if"] = @(OKJAVASCRIPT_TOKEN_KIND_IF);
        self._tokenKindTab[@"-"] = @(OKJAVASCRIPT_TOKEN_KIND_MINUS);
        self._tokenKindTab[@"null"] = @(OKJAVASCRIPT_TOKEN_KIND_NULL);
        self._tokenKindTab[@"false"] = @(OKJAVASCRIPT_TOKEN_KIND_FALSELITERAL);
        self._tokenKindTab[@"."] = @(OKJAVASCRIPT_TOKEN_KIND_DOT);
        self._tokenKindTab[@"<<"] = @(OKJAVASCRIPT_TOKEN_KIND_SHIFTLEFT);
        self._tokenKindTab[@"/"] = @(OKJAVASCRIPT_TOKEN_KIND_DIV);
        self._tokenKindTab[@"+="] = @(OKJAVASCRIPT_TOKEN_KIND_PLUSEQ);
        self._tokenKindTab[@"<="] = @(OKJAVASCRIPT_TOKEN_KIND_LE);
        self._tokenKindTab[@"^="] = @(OKJAVASCRIPT_TOKEN_KIND_XOREQ);
        self._tokenKindTab[@"["] = @(OKJAVASCRIPT_TOKEN_KIND_OPENBRACKET);
        self._tokenKindTab[@"undefined"] = @(OKJAVASCRIPT_TOKEN_KIND_UNDEFINED);
        self._tokenKindTab[@"typeof"] = @(OKJAVASCRIPT_TOKEN_KIND_TYPEOF);
        self._tokenKindTab[@"||"] = @(OKJAVASCRIPT_TOKEN_KIND_OR);
        self._tokenKindTab[@"function"] = @(OKJAVASCRIPT_TOKEN_KIND_FUNCTION);
        self._tokenKindTab[@"]"] = @(OKJAVASCRIPT_TOKEN_KIND_CLOSEBRACKET);
        self._tokenKindTab[@"^"] = @(OKJAVASCRIPT_TOKEN_KIND_CARET);
        self._tokenKindTab[@"=="] = @(OKJAVASCRIPT_TOKEN_KIND_EQ);
        self._tokenKindTab[@"continue"] = @(OKJAVASCRIPT_TOKEN_KIND_CONTINUE);
        self._tokenKindTab[@"break"] = @(OKJAVASCRIPT_TOKEN_KIND_BREAKSYM);
        self._tokenKindTab[@"-="] = @(OKJAVASCRIPT_TOKEN_KIND_MINUSEQ);
        self._tokenKindTab[@">="] = @(OKJAVASCRIPT_TOKEN_KIND_GE);
        self._tokenKindTab[@":"] = @(OKJAVASCRIPT_TOKEN_KIND_COLON);
        self._tokenKindTab[@"in"] = @(OKJAVASCRIPT_TOKEN_KIND_INSYM);
        self._tokenKindTab[@";"] = @(OKJAVASCRIPT_TOKEN_KIND_SEMI);
        self._tokenKindTab[@"for"] = @(OKJAVASCRIPT_TOKEN_KIND_FOR);
        self._tokenKindTab[@"++"] = @(OKJAVASCRIPT_TOKEN_KIND_PLUSPLUS);
        self._tokenKindTab[@"<"] = @(OKJAVASCRIPT_TOKEN_KIND_LT);
        self._tokenKindTab[@"%="] = @(OKJAVASCRIPT_TOKEN_KIND_MODEQ);
        self._tokenKindTab[@">>"] = @(OKJAVASCRIPT_TOKEN_KIND_SHIFTRIGHT);
        self._tokenKindTab[@"="] = @(OKJAVASCRIPT_TOKEN_KIND_EQUALS);
        self._tokenKindTab[@">"] = @(OKJAVASCRIPT_TOKEN_KIND_GT);
        self._tokenKindTab[@"void"] = @(OKJAVASCRIPT_TOKEN_KIND_VOID);
        self._tokenKindTab[@"?"] = @(OKJAVASCRIPT_TOKEN_KIND_QUESTION);
        self._tokenKindTab[@"while"] = @(OKJAVASCRIPT_TOKEN_KIND_WHILE);
        self._tokenKindTab[@"&="] = @(OKJAVASCRIPT_TOKEN_KIND_ANDEQ);
        self._tokenKindTab[@">>>="] = @(OKJAVASCRIPT_TOKEN_KIND_SHIFTRIGHTEXTEQ);
        self._tokenKindTab[@"else"] = @(OKJAVASCRIPT_TOKEN_KIND_ELSE);
        self._tokenKindTab[@"/="] = @(OKJAVASCRIPT_TOKEN_KIND_DIVEQ);
        self._tokenKindTab[@"&&"] = @(OKJAVASCRIPT_TOKEN_KIND_AND);
        self._tokenKindTab[@"var"] = @(OKJAVASCRIPT_TOKEN_KIND_VAR);
        self._tokenKindTab[@"|="] = @(OKJAVASCRIPT_TOKEN_KIND_OREQ);
        self._tokenKindTab[@">>="] = @(OKJAVASCRIPT_TOKEN_KIND_SHIFTRIGHTEQ);
        self._tokenKindTab[@"--"] = @(OKJAVASCRIPT_TOKEN_KIND_MINUSMINUS);
        self._tokenKindTab[@"new"] = @(OKJAVASCRIPT_TOKEN_KIND_KEYWORDNEW);
        self._tokenKindTab[@"!"] = @(OKJAVASCRIPT_TOKEN_KIND_NOT);
        self._tokenKindTab[@">>>"] = @(OKJAVASCRIPT_TOKEN_KIND_SHIFTRIGHTEXT);
        self._tokenKindTab[@"true"] = @(OKJAVASCRIPT_TOKEN_KIND_TRUELITERAL);
        self._tokenKindTab[@"this"] = @(OKJAVASCRIPT_TOKEN_KIND_THIS);
        self._tokenKindTab[@"with"] = @(OKJAVASCRIPT_TOKEN_KIND_WITH);
        self._tokenKindTab[@"==="] = @(OKJAVASCRIPT_TOKEN_KIND_IS);
        self._tokenKindTab[@"%"] = @(OKJAVASCRIPT_TOKEN_KIND_MOD);
        self._tokenKindTab[@"&"] = @(OKJAVASCRIPT_TOKEN_KIND_AMP);
        self._tokenKindTab[@"{"] = @(OKJAVASCRIPT_TOKEN_KIND_OPENCURLY);

    }
    return self;
}


- (void)_start {
    
    [self execute:(id)^{
        
	
	PKTokenizer *t = self.tokenizer;
	
    // whitespace
    self.silentlyConsumesWhitespace = YES;
    t.whitespaceState.reportsWhitespaceTokens = YES;
    self.assembly.preservesWhitespaceTokens = YES;

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

	t.commentState.reportsCommentTokens = YES;
	
	[t setTokenizerState:t.commentState from:'/' to:'/'];
	[t.commentState addSingleLineStartMarker:@"//"];
	[t.commentState addMultiLineStartMarker:@"/*" endMarker:@"*/"];

    }];
    [self program]; 
    [self matchEOF:YES]; 

}

- (void)if {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"if"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"if"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_IF discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"if"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"if"];
}

- (void)else {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"else"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"else"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_ELSE discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"else"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"else"];
}

- (void)while {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"while"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"while"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_WHILE discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"while"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"while"];
}

- (void)for {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"for"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"for"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_FOR discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"for"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"for"];
}

- (void)inSym {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"inSym"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"inSym"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_INSYM discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"inSym"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"inSym"];
}

- (void)breakSym {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"breakSym"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"breakSym"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_BREAKSYM discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"breakSym"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"breakSym"];
}

- (void)continue {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"continue"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"continue"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_CONTINUE discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"continue"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"continue"];
}

- (void)with {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"with"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"with"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_WITH discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"with"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"with"];
}

- (void)return {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"return"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"return"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_RETURN discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"return"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"return"];
}

- (void)var {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"var"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"var"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_VAR discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"var"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"var"];
}

- (void)delete {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"delete"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"delete"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_DELETE discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"delete"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"delete"];
}

- (void)keywordNew {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"keywordNew"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"keywordNew"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_KEYWORDNEW discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"keywordNew"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"keywordNew"];
}

- (void)this {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"this"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"this"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_THIS discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"this"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"this"];
}

- (void)falseLiteral {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"falseLiteral"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"falseLiteral"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_FALSELITERAL discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"falseLiteral"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"falseLiteral"];
}

- (void)trueLiteral {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"trueLiteral"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"trueLiteral"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_TRUELITERAL discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"trueLiteral"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"trueLiteral"];
}

- (void)null {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"null"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"null"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_NULL discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"null"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"null"];
}

- (void)undefined {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"undefined"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"undefined"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_UNDEFINED discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"undefined"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"undefined"];
}

- (void)void {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"void"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"void"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_VOID discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"void"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"void"];
}

- (void)typeof {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"typeof"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"typeof"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_TYPEOF discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"typeof"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"typeof"];
}

- (void)instanceof {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"instanceof"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"instanceof"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_INSTANCEOF discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"instanceof"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"instanceof"];
}

- (void)function {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"function"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"function"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_FUNCTION discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"function"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"function"];
}

- (void)openCurly {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"openCurly"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"openCurly"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_OPENCURLY discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"openCurly"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"openCurly"];
}

- (void)closeCurly {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"closeCurly"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"closeCurly"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_CLOSECURLY discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"closeCurly"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"closeCurly"];
}

- (void)openParen {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"openParen"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"openParen"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_OPENPAREN discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"openParen"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"openParen"];
}

- (void)closeParen {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"closeParen"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"closeParen"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_CLOSEPAREN discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"closeParen"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"closeParen"];
}

- (void)openBracket {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"openBracket"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"openBracket"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_OPENBRACKET discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"openBracket"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"openBracket"];
}

- (void)closeBracket {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"closeBracket"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"closeBracket"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_CLOSEBRACKET discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"closeBracket"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"closeBracket"];
}

- (void)comma {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"comma"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"comma"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_COMMA discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"comma"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"comma"];
}

- (void)dot {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"dot"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"dot"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_DOT discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"dot"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"dot"];
}

- (void)semi {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"semi"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"semi"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_SEMI discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"semi"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"semi"];
}

- (void)colon {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"colon"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"colon"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_COLON discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"colon"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"colon"];
}

- (void)equals {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"equals"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"equals"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_EQUALS discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"equals"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"equals"];
}

- (void)not {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"not"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"not"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_NOT discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"not"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"not"];
}

- (void)lt {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"lt"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"lt"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_LT discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"lt"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"lt"];
}

- (void)gt {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"gt"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"gt"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_GT discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"gt"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"gt"];
}

- (void)amp {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"amp"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"amp"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_AMP discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"amp"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"amp"];
}

- (void)pipe {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"pipe"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"pipe"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_PIPE discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"pipe"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"pipe"];
}

- (void)caret {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"caret"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"caret"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_CARET discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"caret"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"caret"];
}

- (void)tilde {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"tilde"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"tilde"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_TILDE discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"tilde"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"tilde"];
}

- (void)question {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"question"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"question"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_QUESTION discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"question"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"question"];
}

- (void)plus {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"plus"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"plus"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_PLUS discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"plus"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"plus"];
}

- (void)minus {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"minus"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"minus"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_MINUS discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"minus"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"minus"];
}

- (void)times {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"times"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"times"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_TIMES discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"times"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"times"];
}

- (void)div {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"div"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"div"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_DIV discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"div"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"div"];
}

- (void)mod {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"mod"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"mod"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_MOD discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"mod"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"mod"];
}

- (void)or {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"or"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"or"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_OR discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"or"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"or"];
}

- (void)and {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"and"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"and"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_AND discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"and"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"and"];
}

- (void)ne {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"ne"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"ne"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_NE discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"ne"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"ne"];
}

- (void)isnot {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"isnot"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"isnot"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_ISNOT discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"isnot"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"isnot"];
}

- (void)eq {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"eq"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"eq"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_EQ discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"eq"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"eq"];
}

- (void)is {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"is"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"is"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_IS discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"is"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"is"];
}

- (void)le {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"le"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"le"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_LE discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"le"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"le"];
}

- (void)ge {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"ge"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"ge"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_GE discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"ge"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"ge"];
}

- (void)plusPlus {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"plusPlus"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"plusPlus"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_PLUSPLUS discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"plusPlus"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"plusPlus"];
}

- (void)minusMinus {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"minusMinus"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"minusMinus"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_MINUSMINUS discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"minusMinus"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"minusMinus"];
}

- (void)plusEq {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"plusEq"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"plusEq"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_PLUSEQ discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"plusEq"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"plusEq"];
}

- (void)minusEq {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"minusEq"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"minusEq"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_MINUSEQ discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"minusEq"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"minusEq"];
}

- (void)timesEq {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"timesEq"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"timesEq"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_TIMESEQ discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"timesEq"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"timesEq"];
}

- (void)divEq {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"divEq"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"divEq"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_DIVEQ discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"divEq"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"divEq"];
}

- (void)modEq {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"modEq"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"modEq"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_MODEQ discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"modEq"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"modEq"];
}

- (void)shiftLeft {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"shiftLeft"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"shiftLeft"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_SHIFTLEFT discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"shiftLeft"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"shiftLeft"];
}

- (void)shiftRight {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"shiftRight"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"shiftRight"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_SHIFTRIGHT discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"shiftRight"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"shiftRight"];
}

- (void)shiftRightExt {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"shiftRightExt"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"shiftRightExt"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_SHIFTRIGHTEXT discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"shiftRightExt"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"shiftRightExt"];
}

- (void)shiftLeftEq {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"shiftLeftEq"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"shiftLeftEq"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_SHIFTLEFTEQ discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"shiftLeftEq"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"shiftLeftEq"];
}

- (void)shiftRightEq {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"shiftRightEq"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"shiftRightEq"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_SHIFTRIGHTEQ discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"shiftRightEq"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"shiftRightEq"];
}

- (void)shiftRightExtEq {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"shiftRightExtEq"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"shiftRightExtEq"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_SHIFTRIGHTEXTEQ discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"shiftRightExtEq"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"shiftRightExtEq"];
}

- (void)andEq {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"andEq"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"andEq"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_ANDEQ discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"andEq"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"andEq"];
}

- (void)xorEq {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"xorEq"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"xorEq"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_XOREQ discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"xorEq"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"xorEq"];
}

- (void)orEq {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"orEq"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"orEq"];

    [self match:OKJAVASCRIPT_TOKEN_KIND_OREQ discard:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"orEq"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"orEq"];
}

- (void)assignmentOperator {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"assignmentOperator"];

    if ([self speculate:^{ [self equals]; }]) {
        [self equals]; 
    } else if ([self speculate:^{ [self plusEq]; }]) {
        [self plusEq]; 
    } else if ([self speculate:^{ [self minusEq]; }]) {
        [self minusEq]; 
    } else if ([self speculate:^{ [self timesEq]; }]) {
        [self timesEq]; 
    } else if ([self speculate:^{ [self divEq]; }]) {
        [self divEq]; 
    } else if ([self speculate:^{ [self modEq]; }]) {
        [self modEq]; 
    } else if ([self speculate:^{ [self shiftLeftEq]; }]) {
        [self shiftLeftEq]; 
    } else if ([self speculate:^{ [self shiftRightEq]; }]) {
        [self shiftRightEq]; 
    } else if ([self speculate:^{ [self shiftRightExtEq]; }]) {
        [self shiftRightExtEq]; 
    } else if ([self speculate:^{ [self andEq]; }]) {
        [self andEq]; 
    } else if ([self speculate:^{ [self xorEq]; }]) {
        [self xorEq]; 
    } else if ([self speculate:^{ [self orEq]; }]) {
        [self orEq]; 
    } else {
        [self raise:@"no viable alternative found in assignmentOperator"];
    }

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"assignmentOperator"];
}

- (void)relationalOperator {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"relationalOperator"];

    if ([self speculate:^{ [self lt]; }]) {
        [self lt]; 
    } else if ([self speculate:^{ [self gt]; }]) {
        [self gt]; 
    } else if ([self speculate:^{ [self ge]; }]) {
        [self ge]; 
    } else if ([self speculate:^{ [self le]; }]) {
        [self le]; 
    } else if ([self speculate:^{ [self instanceof]; }]) {
        [self instanceof]; 
    } else {
        [self raise:@"no viable alternative found in relationalOperator"];
    }

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"relationalOperator"];
}

- (void)equalityOperator {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"equalityOperator"];

    if ([self speculate:^{ [self eq]; }]) {
        [self eq]; 
    } else if ([self speculate:^{ [self ne]; }]) {
        [self ne]; 
    } else if ([self speculate:^{ [self is]; }]) {
        [self is]; 
    } else if ([self speculate:^{ [self isnot]; }]) {
        [self isnot]; 
    } else {
        [self raise:@"no viable alternative found in equalityOperator"];
    }

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"equalityOperator"];
}

- (void)shiftOperator {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"shiftOperator"];

    if ([self speculate:^{ [self shiftLeft]; }]) {
        [self shiftLeft]; 
    } else if ([self speculate:^{ [self shiftRight]; }]) {
        [self shiftRight]; 
    } else if ([self speculate:^{ [self shiftRightExt]; }]) {
        [self shiftRightExt]; 
    } else {
        [self raise:@"no viable alternative found in shiftOperator"];
    }

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"shiftOperator"];
}

- (void)incrementOperator {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"incrementOperator"];

    if ([self speculate:^{ [self plusPlus]; }]) {
        [self plusPlus]; 
    } else if ([self speculate:^{ [self minusMinus]; }]) {
        [self minusMinus]; 
    } else {
        [self raise:@"no viable alternative found in incrementOperator"];
    }

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"incrementOperator"];
}

- (void)unaryOperator {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"unaryOperator"];

    if ([self speculate:^{ [self tilde]; }]) {
        [self tilde]; 
    } else if ([self speculate:^{ [self delete]; }]) {
        [self delete]; 
    } else if ([self speculate:^{ [self typeof]; }]) {
        [self typeof]; 
    } else if ([self speculate:^{ [self void]; }]) {
        [self void]; 
    } else {
        [self raise:@"no viable alternative found in unaryOperator"];
    }

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"unaryOperator"];
}

- (void)multiplicativeOperator {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"multiplicativeOperator"];

    if ([self speculate:^{ [self times]; }]) {
        [self times]; 
    } else if ([self speculate:^{ [self div]; }]) {
        [self div]; 
    } else if ([self speculate:^{ [self mod]; }]) {
        [self mod]; 
    } else {
        [self raise:@"no viable alternative found in multiplicativeOperator"];
    }

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"multiplicativeOperator"];
}

- (void)program {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"program"];

    do {
        [self element]; 
    } while ([self speculate:^{ [self element]; }]);

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"program"];
}

- (void)element {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"element"];

    if ([self speculate:^{ [self func]; }]) {
        [self func]; 
    } else if ([self speculate:^{ [self stmt]; }]) {
        [self stmt]; 
    } else {
        [self raise:@"no viable alternative found in element"];
    }

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"element"];
}

- (void)func {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"func"];

    [self function]; 
    [self identifier]; 
    [self openParen]; 
    [self paramListOpt]; 
    [self closeParen]; 
    [self compoundStmt]; 

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"func"];
}

- (void)paramListOpt {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"paramListOpt"];

    if ([self speculate:^{ [self paramList]; }]) {
        [self paramList]; 
    }

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"paramListOpt"];
}

- (void)paramList {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"paramList"];

    [self identifier]; 
    while ([self predicts:OKJAVASCRIPT_TOKEN_KIND_COMMA, 0]) {
        if ([self speculate:^{ [self commaIdentifier]; }]) {
            [self commaIdentifier]; 
        } else {
            break;
        }
    }

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"paramList"];
}

- (void)commaIdentifier {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"commaIdentifier"];

    [self comma]; 
    [self identifier]; 

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"commaIdentifier"];
}

- (void)compoundStmt {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"compoundStmt"];

    [self openCurly]; 
    [self stmts]; 
    [self closeCurly]; 

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"compoundStmt"];
}

- (void)stmts {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"stmts"];

    while ([self predicts:OKJAVASCRIPT_TOKEN_KIND_BREAKSYM, OKJAVASCRIPT_TOKEN_KIND_CONTINUE, OKJAVASCRIPT_TOKEN_KIND_DELETE, OKJAVASCRIPT_TOKEN_KIND_FALSELITERAL, OKJAVASCRIPT_TOKEN_KIND_FOR, OKJAVASCRIPT_TOKEN_KIND_IF, OKJAVASCRIPT_TOKEN_KIND_KEYWORDNEW, OKJAVASCRIPT_TOKEN_KIND_MINUS, OKJAVASCRIPT_TOKEN_KIND_MINUSMINUS, OKJAVASCRIPT_TOKEN_KIND_NULL, OKJAVASCRIPT_TOKEN_KIND_OPENCURLY, OKJAVASCRIPT_TOKEN_KIND_OPENPAREN, OKJAVASCRIPT_TOKEN_KIND_PLUSPLUS, OKJAVASCRIPT_TOKEN_KIND_RETURN, OKJAVASCRIPT_TOKEN_KIND_SEMI, OKJAVASCRIPT_TOKEN_KIND_THIS, OKJAVASCRIPT_TOKEN_KIND_TILDE, OKJAVASCRIPT_TOKEN_KIND_TRUELITERAL, OKJAVASCRIPT_TOKEN_KIND_TYPEOF, OKJAVASCRIPT_TOKEN_KIND_UNDEFINED, OKJAVASCRIPT_TOKEN_KIND_VAR, OKJAVASCRIPT_TOKEN_KIND_VOID, OKJAVASCRIPT_TOKEN_KIND_WHILE, OKJAVASCRIPT_TOKEN_KIND_WITH, TOKEN_KIND_BUILTIN_NUMBER, TOKEN_KIND_BUILTIN_QUOTEDSTRING, TOKEN_KIND_BUILTIN_WORD, 0]) {
        if ([self speculate:^{ [self stmt]; }]) {
            [self stmt]; 
        } else {
            break;
        }
    }

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"stmts"];
}

- (void)stmt {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"stmt"];

    if ([self speculate:^{ [self semi]; }]) {
        [self semi]; 
    } else if ([self speculate:^{ [self ifStmt]; }]) {
        [self ifStmt]; 
    } else if ([self speculate:^{ [self ifElseStmt]; }]) {
        [self ifElseStmt]; 
    } else if ([self speculate:^{ [self whileStmt]; }]) {
        [self whileStmt]; 
    } else if ([self speculate:^{ [self forParenStmt]; }]) {
        [self forParenStmt]; 
    } else if ([self speculate:^{ [self forBeginStmt]; }]) {
        [self forBeginStmt]; 
    } else if ([self speculate:^{ [self forInStmt]; }]) {
        [self forInStmt]; 
    } else if ([self speculate:^{ [self breakStmt]; }]) {
        [self breakStmt]; 
    } else if ([self speculate:^{ [self continueStmt]; }]) {
        [self continueStmt]; 
    } else if ([self speculate:^{ [self withStmt]; }]) {
        [self withStmt]; 
    } else if ([self speculate:^{ [self returnStmt]; }]) {
        [self returnStmt]; 
    } else if ([self speculate:^{ [self compoundStmt]; }]) {
        [self compoundStmt]; 
    } else if ([self speculate:^{ [self variablesOrExprStmt]; }]) {
        [self variablesOrExprStmt]; 
    } else {
        [self raise:@"no viable alternative found in stmt"];
    }

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"stmt"];
}

- (void)ifStmt {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"ifStmt"];

    [self if]; 
    [self condition]; 
    [self stmt]; 

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"ifStmt"];
}

- (void)ifElseStmt {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"ifElseStmt"];

    [self if]; 
    [self condition]; 
    [self stmt]; 
    [self else]; 
    [self stmt]; 

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"ifElseStmt"];
}

- (void)whileStmt {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"whileStmt"];

    [self while]; 
    [self condition]; 
    [self stmt]; 

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"whileStmt"];
}

- (void)forParenStmt {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"forParenStmt"];

    [self forParen]; 
    [self semi]; 
    [self exprOpt]; 
    [self semi]; 
    [self exprOpt]; 
    [self closeParen]; 
    [self stmt]; 

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"forParenStmt"];
}

- (void)forBeginStmt {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"forBeginStmt"];

    [self forBegin]; 
    [self semi]; 
    [self exprOpt]; 
    [self semi]; 
    [self exprOpt]; 
    [self closeParen]; 
    [self stmt]; 

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"forBeginStmt"];
}

- (void)forInStmt {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"forInStmt"];

    [self forBegin]; 
    [self inSym]; 
    [self expr]; 
    [self closeParen]; 
    [self stmt]; 

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"forInStmt"];
}

- (void)breakStmt {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"breakStmt"];

    [self breakSym]; 
    [self semi]; 

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"breakStmt"];
}

- (void)continueStmt {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"continueStmt"];

    [self continue]; 
    [self semi]; 

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"continueStmt"];
}

- (void)withStmt {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"withStmt"];

    [self with]; 
    [self openParen]; 
    [self expr]; 
    [self closeParen]; 
    [self stmt]; 

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"withStmt"];
}

- (void)returnStmt {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"returnStmt"];

    [self return]; 
    [self exprOpt]; 
    [self semi]; 

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"returnStmt"];
}

- (void)variablesOrExprStmt {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"variablesOrExprStmt"];

    [self variablesOrExpr]; 
    [self semi]; 

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"variablesOrExprStmt"];
}

- (void)condition {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"condition"];

    [self openParen]; 
    [self expr]; 
    [self closeParen]; 

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"condition"];
}

- (void)forParen {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"forParen"];

    [self for]; 
    [self openParen]; 

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"forParen"];
}

- (void)forBegin {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"forBegin"];

    [self forParen]; 
    [self variablesOrExpr]; 

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"forBegin"];
}

- (void)variablesOrExpr {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"variablesOrExpr"];

    if ([self speculate:^{ [self varVariables]; }]) {
        [self varVariables]; 
    } else if ([self speculate:^{ [self expr]; }]) {
        [self expr]; 
    } else {
        [self raise:@"no viable alternative found in variablesOrExpr"];
    }

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"variablesOrExpr"];
}

- (void)varVariables {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"varVariables"];

    [self var]; 
    [self variables]; 

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"varVariables"];
}

- (void)variables {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"variables"];

    [self variable]; 
    while ([self predicts:OKJAVASCRIPT_TOKEN_KIND_COMMA, 0]) {
        if ([self speculate:^{ [self commaVariable]; }]) {
            [self commaVariable]; 
        } else {
            break;
        }
    }

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"variables"];
}

- (void)commaVariable {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"commaVariable"];

    [self comma]; 
    [self variable]; 

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"commaVariable"];
}

- (void)variable {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"variable"];

    [self identifier]; 
    if ([self speculate:^{ [self assignment]; }]) {
        [self assignment]; 
    }

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"variable"];
}

- (void)assignment {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"assignment"];

    [self equals]; 
    [self assignmentExpr]; 

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"assignment"];
}

- (void)exprOpt {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"exprOpt"];

    if ([self speculate:^{ [self expr]; }]) {
        [self expr]; 
    }

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"exprOpt"];
}

- (void)expr {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"expr"];

    [self assignmentExpr]; 
    if ([self speculate:^{ [self commaExpr]; }]) {
        [self commaExpr]; 
    }

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"expr"];
}

- (void)commaExpr {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"commaExpr"];

    [self comma]; 
    [self expr]; 

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"commaExpr"];
}

- (void)assignmentExpr {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"assignmentExpr"];

    [self conditionalExpr]; 
    if ([self speculate:^{ [self extraAssignment]; }]) {
        [self extraAssignment]; 
    }

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"assignmentExpr"];
}

- (void)extraAssignment {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"extraAssignment"];

    [self assignmentOperator]; 
    [self assignmentExpr]; 

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"extraAssignment"];
}

- (void)conditionalExpr {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"conditionalExpr"];

    [self orExpr]; 
    if ([self speculate:^{ [self ternaryExpr]; }]) {
        [self ternaryExpr]; 
    }

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"conditionalExpr"];
}

- (void)ternaryExpr {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"ternaryExpr"];

    [self question]; 
    [self assignmentExpr]; 
    [self colon]; 
    [self assignmentExpr]; 

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"ternaryExpr"];
}

- (void)orExpr {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"orExpr"];

    [self andExpr]; 
    while ([self predicts:OKJAVASCRIPT_TOKEN_KIND_OR, 0]) {
        if ([self speculate:^{ [self orAndExpr]; }]) {
            [self orAndExpr]; 
        } else {
            break;
        }
    }

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"orExpr"];
}

- (void)orAndExpr {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"orAndExpr"];

    [self or]; 
    [self andExpr]; 

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"orAndExpr"];
}

- (void)andExpr {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"andExpr"];

    [self bitwiseOrExpr]; 
    if ([self speculate:^{ [self andAndExpr]; }]) {
        [self andAndExpr]; 
    }

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"andExpr"];
}

- (void)andAndExpr {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"andAndExpr"];

    [self and]; 
    [self andExpr]; 

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"andAndExpr"];
}

- (void)bitwiseOrExpr {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"bitwiseOrExpr"];

    [self bitwiseXorExpr]; 
    if ([self speculate:^{ [self pipeBitwiseOrExpr]; }]) {
        [self pipeBitwiseOrExpr]; 
    }

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"bitwiseOrExpr"];
}

- (void)pipeBitwiseOrExpr {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"pipeBitwiseOrExpr"];

    [self pipe]; 
    [self bitwiseOrExpr]; 

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"pipeBitwiseOrExpr"];
}

- (void)bitwiseXorExpr {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"bitwiseXorExpr"];

    [self bitwiseAndExpr]; 
    if ([self speculate:^{ [self caretBitwiseXorExpr]; }]) {
        [self caretBitwiseXorExpr]; 
    }

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"bitwiseXorExpr"];
}

- (void)caretBitwiseXorExpr {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"caretBitwiseXorExpr"];

    [self caret]; 
    [self bitwiseXorExpr]; 

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"caretBitwiseXorExpr"];
}

- (void)bitwiseAndExpr {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"bitwiseAndExpr"];

    [self equalityExpr]; 
    if ([self speculate:^{ [self ampBitwiseAndExpression]; }]) {
        [self ampBitwiseAndExpression]; 
    }

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"bitwiseAndExpr"];
}

- (void)ampBitwiseAndExpression {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"ampBitwiseAndExpression"];

    [self amp]; 
    [self bitwiseAndExpr]; 

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"ampBitwiseAndExpression"];
}

- (void)equalityExpr {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"equalityExpr"];

    [self relationalExpr]; 
    if ([self speculate:^{ [self equalityOpEqualityExpr]; }]) {
        [self equalityOpEqualityExpr]; 
    }

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"equalityExpr"];
}

- (void)equalityOpEqualityExpr {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"equalityOpEqualityExpr"];

    [self equalityOperator]; 
    [self equalityExpr]; 

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"equalityOpEqualityExpr"];
}

- (void)relationalExpr {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"relationalExpr"];

    [self shiftExpr]; 
    while ([self predicts:OKJAVASCRIPT_TOKEN_KIND_GE, OKJAVASCRIPT_TOKEN_KIND_GT, OKJAVASCRIPT_TOKEN_KIND_INSTANCEOF, OKJAVASCRIPT_TOKEN_KIND_LE, OKJAVASCRIPT_TOKEN_KIND_LT, 0]) {
        if ([self speculate:^{ [self relationalOperator]; [self shiftExpr]; }]) {
            [self relationalOperator]; 
            [self shiftExpr]; 
        } else {
            break;
        }
    }

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"relationalExpr"];
}

- (void)shiftExpr {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"shiftExpr"];

    [self additiveExpr]; 
    if ([self speculate:^{ [self shiftOpShiftExpr]; }]) {
        [self shiftOpShiftExpr]; 
    }

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"shiftExpr"];
}

- (void)shiftOpShiftExpr {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"shiftOpShiftExpr"];

    [self shiftOperator]; 
    [self shiftExpr]; 

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"shiftOpShiftExpr"];
}

- (void)additiveExpr {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"additiveExpr"];

    [self multiplicativeExpr]; 
    if ([self speculate:^{ [self plusOrMinusExpr]; }]) {
        [self plusOrMinusExpr]; 
    }

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"additiveExpr"];
}

- (void)plusOrMinusExpr {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"plusOrMinusExpr"];

    if ([self speculate:^{ [self plusExpr]; }]) {
        [self plusExpr]; 
    } else if ([self speculate:^{ [self minusExpr]; }]) {
        [self minusExpr]; 
    } else {
        [self raise:@"no viable alternative found in plusOrMinusExpr"];
    }

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"plusOrMinusExpr"];
}

- (void)plusExpr {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"plusExpr"];

    [self plus]; 
    [self additiveExpr]; 

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"plusExpr"];
}

- (void)minusExpr {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"minusExpr"];

    [self minus]; 
    [self additiveExpr]; 

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"minusExpr"];
}

- (void)multiplicativeExpr {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"multiplicativeExpr"];

    [self unaryExpr]; 
    if ([self speculate:^{ [self multiplicativeOperator]; [self multiplicativeExpr]; }]) {
        [self multiplicativeOperator]; 
        [self multiplicativeExpr]; 
    }

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"multiplicativeExpr"];
}

- (void)unaryExpr {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"unaryExpr"];

    if ([self speculate:^{ [self memberExpr]; }]) {
        [self memberExpr]; 
    } else if ([self speculate:^{ [self unaryExpr1]; }]) {
        [self unaryExpr1]; 
    } else if ([self speculate:^{ [self unaryExpr2]; }]) {
        [self unaryExpr2]; 
    } else if ([self speculate:^{ [self unaryExpr3]; }]) {
        [self unaryExpr3]; 
    } else if ([self speculate:^{ [self unaryExpr4]; }]) {
        [self unaryExpr4]; 
    } else if ([self speculate:^{ [self unaryExpr6]; }]) {
        [self unaryExpr6]; 
    } else {
        [self raise:@"no viable alternative found in unaryExpr"];
    }

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"unaryExpr"];
}

- (void)unaryExpr1 {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"unaryExpr1"];

    [self unaryOperator]; 
    [self unaryExpr]; 

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"unaryExpr1"];
}

- (void)unaryExpr2 {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"unaryExpr2"];

    [self minus]; 
    [self unaryExpr]; 

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"unaryExpr2"];
}

- (void)unaryExpr3 {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"unaryExpr3"];

    [self incrementOperator]; 
    [self memberExpr]; 

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"unaryExpr3"];
}

- (void)unaryExpr4 {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"unaryExpr4"];

    [self memberExpr]; 
    [self incrementOperator]; 

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"unaryExpr4"];
}

- (void)callNewExpr {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"callNewExpr"];

    [self keywordNew]; 
    [self constructor]; 

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"callNewExpr"];
}

- (void)unaryExpr6 {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"unaryExpr6"];

    [self delete]; 
    [self memberExpr]; 

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"unaryExpr6"];
}

- (void)constructor {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"constructor"];

    if ([self speculate:^{ [self this]; [self dot]; }]) {
        [self this]; 
        [self dot]; 
    }
    [self constructorCall]; 

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"constructor"];
}

- (void)constructorCall {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"constructorCall"];

    [self identifier]; 
    if ([self speculate:^{ if ([self speculate:^{ [self parenArgListParen]; }]) {[self parenArgListParen]; } else if ([self speculate:^{ [self dot]; [self constructorCall]; }]) {[self dot]; [self constructorCall]; } else {[self raise:@"no viable alternative found in constructorCall"];}}]) {
        if ([self speculate:^{ [self parenArgListParen]; }]) {
            [self parenArgListParen]; 
        } else if ([self speculate:^{ [self dot]; [self constructorCall]; }]) {
            [self dot]; 
            [self constructorCall]; 
        } else {
            [self raise:@"no viable alternative found in constructorCall"];
        }
    }

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"constructorCall"];
}

- (void)parenArgListParen {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"parenArgListParen"];

    [self openParen]; 
    [self argListOpt]; 
    [self closeParen]; 

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"parenArgListParen"];
}

- (void)memberExpr {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"memberExpr"];

    [self primaryExpr]; 
    if ([self speculate:^{ [self dotBracketOrParenExpr]; }]) {
        [self dotBracketOrParenExpr]; 
    }

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"memberExpr"];
}

- (void)dotBracketOrParenExpr {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"dotBracketOrParenExpr"];

    if ([self speculate:^{ [self dotMemberExpr]; }]) {
        [self dotMemberExpr]; 
    } else if ([self speculate:^{ [self bracketMemberExpr]; }]) {
        [self bracketMemberExpr]; 
    } else if ([self speculate:^{ [self parenMemberExpr]; }]) {
        [self parenMemberExpr]; 
    } else {
        [self raise:@"no viable alternative found in dotBracketOrParenExpr"];
    }

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"dotBracketOrParenExpr"];
}

- (void)dotMemberExpr {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"dotMemberExpr"];

    [self dot]; 
    [self memberExpr]; 

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"dotMemberExpr"];
}

- (void)bracketMemberExpr {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"bracketMemberExpr"];

    [self openBracket]; 
    [self expr]; 
    [self closeBracket]; 

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"bracketMemberExpr"];
}

- (void)parenMemberExpr {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"parenMemberExpr"];

    [self openParen]; 
    [self argListOpt]; 
    [self closeParen]; 

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"parenMemberExpr"];
}

- (void)argListOpt {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"argListOpt"];

    if ([self speculate:^{ [self argList]; }]) {
        [self argList]; 
    }

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"argListOpt"];
}

- (void)argList {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"argList"];

    [self assignmentExpr]; 
    while ([self predicts:OKJAVASCRIPT_TOKEN_KIND_COMMA, 0]) {
        if ([self speculate:^{ [self commaAssignmentExpr]; }]) {
            [self commaAssignmentExpr]; 
        } else {
            break;
        }
    }

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"argList"];
}

- (void)commaAssignmentExpr {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"commaAssignmentExpr"];

    [self comma]; 
    [self assignmentExpr]; 

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"commaAssignmentExpr"];
}

- (void)primaryExpr {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"primaryExpr"];

    if ([self speculate:^{ [self callNewExpr]; }]) {
        [self callNewExpr]; 
    } else if ([self speculate:^{ [self parenExprParen]; }]) {
        [self parenExprParen]; 
    } else if ([self speculate:^{ [self identifier]; }]) {
        [self identifier]; 
    } else if ([self speculate:^{ [self numLiteral]; }]) {
        [self numLiteral]; 
    } else if ([self speculate:^{ [self stringLiteral]; }]) {
        [self stringLiteral]; 
    } else if ([self speculate:^{ [self falseLiteral]; }]) {
        [self falseLiteral]; 
    } else if ([self speculate:^{ [self trueLiteral]; }]) {
        [self trueLiteral]; 
    } else if ([self speculate:^{ [self null]; }]) {
        [self null]; 
    } else if ([self speculate:^{ [self undefined]; }]) {
        [self undefined]; 
    } else if ([self speculate:^{ [self this]; }]) {
        [self this]; 
    } else {
        [self raise:@"no viable alternative found in primaryExpr"];
    }

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"primaryExpr"];
}

- (void)parenExprParen {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"parenExprParen"];

    [self openParen]; 
    [self expr]; 
    [self closeParen]; 

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"parenExprParen"];
}

- (void)identifier {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"identifier"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"identifier"];

    [self matchWord:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"identifier"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"identifier"];
}

- (void)numLiteral {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"numLiteral"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"numLiteral"];

    [self matchNumber:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"numLiteral"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"numLiteral"];
}

- (void)stringLiteral {
    
    [self fireSyntaxSelector:@selector(parser:willMatchInterior:) withRuleName:@"stringLiteral"];
    [self fireSyntaxSelector:@selector(parser:willMatchLeaf:) withRuleName:@"stringLiteral"];

    [self matchQuotedString:NO];

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"stringLiteral"];
    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"stringLiteral"];
}

@end