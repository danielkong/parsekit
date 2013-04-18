#import "JavaScriptParser.h"
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

@interface JavaScriptParser ()
@property (nonatomic, retain) NSMutableDictionary *if_memo;
@property (nonatomic, retain) NSMutableDictionary *else_memo;
@property (nonatomic, retain) NSMutableDictionary *while_memo;
@property (nonatomic, retain) NSMutableDictionary *for_memo;
@property (nonatomic, retain) NSMutableDictionary *in_memo;
@property (nonatomic, retain) NSMutableDictionary *break_memo;
@property (nonatomic, retain) NSMutableDictionary *continue_memo;
@property (nonatomic, retain) NSMutableDictionary *with_memo;
@property (nonatomic, retain) NSMutableDictionary *return_memo;
@property (nonatomic, retain) NSMutableDictionary *var_memo;
@property (nonatomic, retain) NSMutableDictionary *delete_memo;
@property (nonatomic, retain) NSMutableDictionary *keywordNew_memo;
@property (nonatomic, retain) NSMutableDictionary *this_memo;
@property (nonatomic, retain) NSMutableDictionary *falseLiteral_memo;
@property (nonatomic, retain) NSMutableDictionary *trueLiteral_memo;
@property (nonatomic, retain) NSMutableDictionary *null_memo;
@property (nonatomic, retain) NSMutableDictionary *undefined_memo;
@property (nonatomic, retain) NSMutableDictionary *void_memo;
@property (nonatomic, retain) NSMutableDictionary *typeof_memo;
@property (nonatomic, retain) NSMutableDictionary *instanceof_memo;
@property (nonatomic, retain) NSMutableDictionary *function_memo;
@property (nonatomic, retain) NSMutableDictionary *openCurly_memo;
@property (nonatomic, retain) NSMutableDictionary *closeCurly_memo;
@property (nonatomic, retain) NSMutableDictionary *openParen_memo;
@property (nonatomic, retain) NSMutableDictionary *closeParen_memo;
@property (nonatomic, retain) NSMutableDictionary *openBracket_memo;
@property (nonatomic, retain) NSMutableDictionary *closeBracket_memo;
@property (nonatomic, retain) NSMutableDictionary *comma_memo;
@property (nonatomic, retain) NSMutableDictionary *dot_memo;
@property (nonatomic, retain) NSMutableDictionary *semi_memo;
@property (nonatomic, retain) NSMutableDictionary *colon_memo;
@property (nonatomic, retain) NSMutableDictionary *equals_memo;
@property (nonatomic, retain) NSMutableDictionary *not_memo;
@property (nonatomic, retain) NSMutableDictionary *lt_memo;
@property (nonatomic, retain) NSMutableDictionary *gt_memo;
@property (nonatomic, retain) NSMutableDictionary *amp_memo;
@property (nonatomic, retain) NSMutableDictionary *pipe_memo;
@property (nonatomic, retain) NSMutableDictionary *caret_memo;
@property (nonatomic, retain) NSMutableDictionary *tilde_memo;
@property (nonatomic, retain) NSMutableDictionary *question_memo;
@property (nonatomic, retain) NSMutableDictionary *plus_memo;
@property (nonatomic, retain) NSMutableDictionary *minus_memo;
@property (nonatomic, retain) NSMutableDictionary *times_memo;
@property (nonatomic, retain) NSMutableDictionary *div_memo;
@property (nonatomic, retain) NSMutableDictionary *mod_memo;
@property (nonatomic, retain) NSMutableDictionary *or_memo;
@property (nonatomic, retain) NSMutableDictionary *and_memo;
@property (nonatomic, retain) NSMutableDictionary *ne_memo;
@property (nonatomic, retain) NSMutableDictionary *isnot_memo;
@property (nonatomic, retain) NSMutableDictionary *eq_memo;
@property (nonatomic, retain) NSMutableDictionary *is_memo;
@property (nonatomic, retain) NSMutableDictionary *le_memo;
@property (nonatomic, retain) NSMutableDictionary *ge_memo;
@property (nonatomic, retain) NSMutableDictionary *plusPlus_memo;
@property (nonatomic, retain) NSMutableDictionary *minusMinus_memo;
@property (nonatomic, retain) NSMutableDictionary *plusEq_memo;
@property (nonatomic, retain) NSMutableDictionary *minusEq_memo;
@property (nonatomic, retain) NSMutableDictionary *timesEq_memo;
@property (nonatomic, retain) NSMutableDictionary *divEq_memo;
@property (nonatomic, retain) NSMutableDictionary *modEq_memo;
@property (nonatomic, retain) NSMutableDictionary *shiftLeft_memo;
@property (nonatomic, retain) NSMutableDictionary *shiftRight_memo;
@property (nonatomic, retain) NSMutableDictionary *shiftRightExt_memo;
@property (nonatomic, retain) NSMutableDictionary *shiftLeftEq_memo;
@property (nonatomic, retain) NSMutableDictionary *shiftRightEq_memo;
@property (nonatomic, retain) NSMutableDictionary *shiftRightExtEq_memo;
@property (nonatomic, retain) NSMutableDictionary *andEq_memo;
@property (nonatomic, retain) NSMutableDictionary *xorEq_memo;
@property (nonatomic, retain) NSMutableDictionary *orEq_memo;
@property (nonatomic, retain) NSMutableDictionary *assignmentOperator_memo;
@property (nonatomic, retain) NSMutableDictionary *relationalOperator_memo;
@property (nonatomic, retain) NSMutableDictionary *equalityOperator_memo;
@property (nonatomic, retain) NSMutableDictionary *shiftOperator_memo;
@property (nonatomic, retain) NSMutableDictionary *incrementOperator_memo;
@property (nonatomic, retain) NSMutableDictionary *unaryOperator_memo;
@property (nonatomic, retain) NSMutableDictionary *multiplicativeOperator_memo;
@property (nonatomic, retain) NSMutableDictionary *program_memo;
@property (nonatomic, retain) NSMutableDictionary *element_memo;
@property (nonatomic, retain) NSMutableDictionary *func_memo;
@property (nonatomic, retain) NSMutableDictionary *paramListOpt_memo;
@property (nonatomic, retain) NSMutableDictionary *paramList_memo;
@property (nonatomic, retain) NSMutableDictionary *commaIdentifier_memo;
@property (nonatomic, retain) NSMutableDictionary *compoundStmt_memo;
@property (nonatomic, retain) NSMutableDictionary *stmts_memo;
@property (nonatomic, retain) NSMutableDictionary *stmt_memo;
@property (nonatomic, retain) NSMutableDictionary *ifStmt_memo;
@property (nonatomic, retain) NSMutableDictionary *ifElseStmt_memo;
@property (nonatomic, retain) NSMutableDictionary *whileStmt_memo;
@property (nonatomic, retain) NSMutableDictionary *forParenStmt_memo;
@property (nonatomic, retain) NSMutableDictionary *forBeginStmt_memo;
@property (nonatomic, retain) NSMutableDictionary *forInStmt_memo;
@property (nonatomic, retain) NSMutableDictionary *breakStmt_memo;
@property (nonatomic, retain) NSMutableDictionary *continueStmt_memo;
@property (nonatomic, retain) NSMutableDictionary *withStmt_memo;
@property (nonatomic, retain) NSMutableDictionary *returnStmt_memo;
@property (nonatomic, retain) NSMutableDictionary *variablesOrExprStmt_memo;
@property (nonatomic, retain) NSMutableDictionary *condition_memo;
@property (nonatomic, retain) NSMutableDictionary *forParen_memo;
@property (nonatomic, retain) NSMutableDictionary *forBegin_memo;
@property (nonatomic, retain) NSMutableDictionary *variablesOrExpr_memo;
@property (nonatomic, retain) NSMutableDictionary *varVariables_memo;
@property (nonatomic, retain) NSMutableDictionary *variables_memo;
@property (nonatomic, retain) NSMutableDictionary *commaVariable_memo;
@property (nonatomic, retain) NSMutableDictionary *variable_memo;
@property (nonatomic, retain) NSMutableDictionary *assignment_memo;
@property (nonatomic, retain) NSMutableDictionary *exprOpt_memo;
@property (nonatomic, retain) NSMutableDictionary *expr_memo;
@property (nonatomic, retain) NSMutableDictionary *commaExpr_memo;
@property (nonatomic, retain) NSMutableDictionary *assignmentExpr_memo;
@property (nonatomic, retain) NSMutableDictionary *extraAssignment_memo;
@property (nonatomic, retain) NSMutableDictionary *conditionalExpr_memo;
@property (nonatomic, retain) NSMutableDictionary *ternaryExpr_memo;
@property (nonatomic, retain) NSMutableDictionary *orExpr_memo;
@property (nonatomic, retain) NSMutableDictionary *orAndExpr_memo;
@property (nonatomic, retain) NSMutableDictionary *andExpr_memo;
@property (nonatomic, retain) NSMutableDictionary *andAndExpr_memo;
@property (nonatomic, retain) NSMutableDictionary *bitwiseOrExpr_memo;
@property (nonatomic, retain) NSMutableDictionary *pipeBitwiseOrExpr_memo;
@property (nonatomic, retain) NSMutableDictionary *bitwiseXorExpr_memo;
@property (nonatomic, retain) NSMutableDictionary *caretBitwiseXorExpr_memo;
@property (nonatomic, retain) NSMutableDictionary *bitwiseAndExpr_memo;
@property (nonatomic, retain) NSMutableDictionary *ampBitwiseAndExpression_memo;
@property (nonatomic, retain) NSMutableDictionary *equalityExpr_memo;
@property (nonatomic, retain) NSMutableDictionary *equalityOpEqualityExpr_memo;
@property (nonatomic, retain) NSMutableDictionary *relationalExpr_memo;
@property (nonatomic, retain) NSMutableDictionary *shiftExpr_memo;
@property (nonatomic, retain) NSMutableDictionary *shiftOpShiftExpr_memo;
@property (nonatomic, retain) NSMutableDictionary *additiveExpr_memo;
@property (nonatomic, retain) NSMutableDictionary *plusOrMinusExpr_memo;
@property (nonatomic, retain) NSMutableDictionary *plusExpr_memo;
@property (nonatomic, retain) NSMutableDictionary *minusExpr_memo;
@property (nonatomic, retain) NSMutableDictionary *multiplicativeExpr_memo;
@property (nonatomic, retain) NSMutableDictionary *unaryExpr_memo;
@property (nonatomic, retain) NSMutableDictionary *unaryExpr1_memo;
@property (nonatomic, retain) NSMutableDictionary *unaryExpr2_memo;
@property (nonatomic, retain) NSMutableDictionary *unaryExpr3_memo;
@property (nonatomic, retain) NSMutableDictionary *unaryExpr4_memo;
@property (nonatomic, retain) NSMutableDictionary *callNewExpr_memo;
@property (nonatomic, retain) NSMutableDictionary *unaryExpr6_memo;
@property (nonatomic, retain) NSMutableDictionary *constructor_memo;
@property (nonatomic, retain) NSMutableDictionary *constructorCall_memo;
@property (nonatomic, retain) NSMutableDictionary *parenArgListParen_memo;
@property (nonatomic, retain) NSMutableDictionary *memberExpr_memo;
@property (nonatomic, retain) NSMutableDictionary *dotBracketOrParenExpr_memo;
@property (nonatomic, retain) NSMutableDictionary *dotMemberExpr_memo;
@property (nonatomic, retain) NSMutableDictionary *bracketMemberExpr_memo;
@property (nonatomic, retain) NSMutableDictionary *parenMemberExpr_memo;
@property (nonatomic, retain) NSMutableDictionary *argListOpt_memo;
@property (nonatomic, retain) NSMutableDictionary *argList_memo;
@property (nonatomic, retain) NSMutableDictionary *commaAssignmentExpr_memo;
@property (nonatomic, retain) NSMutableDictionary *primaryExpr_memo;
@property (nonatomic, retain) NSMutableDictionary *parenExprParen_memo;
@property (nonatomic, retain) NSMutableDictionary *identifier_memo;
@end

@implementation JavaScriptParser

- (id)init {
	self = [super init];
	if (self) {
        self._tokenKindTab[@"|"] = @(TOKEN_KIND_PIPE);
        self._tokenKindTab[@"!="] = @(TOKEN_KIND_NE);
        self._tokenKindTab[@"("] = @(TOKEN_KIND_OPENPAREN);
        self._tokenKindTab[@"}"] = @(TOKEN_KIND_CLOSECURLY);
        self._tokenKindTab[@"return"] = @(TOKEN_KIND_RETURN);
        self._tokenKindTab[@"~"] = @(TOKEN_KIND_TILDE);
        self._tokenKindTab[@")"] = @(TOKEN_KIND_CLOSEPAREN);
        self._tokenKindTab[@"*"] = @(TOKEN_KIND_TIMES);
        self._tokenKindTab[@"delete"] = @(TOKEN_KIND_DELETE);
        self._tokenKindTab[@"!=="] = @(TOKEN_KIND_ISNOT);
        self._tokenKindTab[@"+"] = @(TOKEN_KIND_PLUS);
        self._tokenKindTab[@"*="] = @(TOKEN_KIND_TIMESEQ);
        self._tokenKindTab[@"instanceof"] = @(TOKEN_KIND_INSTANCEOF);
        self._tokenKindTab[@","] = @(TOKEN_KIND_COMMA);
        self._tokenKindTab[@"<<="] = @(TOKEN_KIND_SHIFTLEFTEQ);
        self._tokenKindTab[@"if"] = @(TOKEN_KIND_IF);
        self._tokenKindTab[@"-"] = @(TOKEN_KIND_MINUS);
        self._tokenKindTab[@"null"] = @(TOKEN_KIND_NULL);
        self._tokenKindTab[@"false"] = @(TOKEN_KIND_FALSELITERAL);
        self._tokenKindTab[@"."] = @(TOKEN_KIND_DOT);
        self._tokenKindTab[@"<<"] = @(TOKEN_KIND_SHIFTLEFT);
        self._tokenKindTab[@"/"] = @(TOKEN_KIND_DIV);
        self._tokenKindTab[@"+="] = @(TOKEN_KIND_PLUSEQ);
        self._tokenKindTab[@"<="] = @(TOKEN_KIND_LE);
        self._tokenKindTab[@"^="] = @(TOKEN_KIND_XOREQ);
        self._tokenKindTab[@"["] = @(TOKEN_KIND_OPENBRACKET);
        self._tokenKindTab[@"undefined"] = @(TOKEN_KIND_UNDEFINED);
        self._tokenKindTab[@"typeof"] = @(TOKEN_KIND_TYPEOF);
        self._tokenKindTab[@"or"] = @(TOKEN_KIND_OR);
        self._tokenKindTab[@"function"] = @(TOKEN_KIND_FUNCTION);
        self._tokenKindTab[@"]"] = @(TOKEN_KIND_CLOSEBRACKET);
        self._tokenKindTab[@"^"] = @(TOKEN_KIND_CARET);
        self._tokenKindTab[@"="] = @(TOKEN_KIND_EQ);
        self._tokenKindTab[@"continue"] = @(TOKEN_KIND_CONTINUE);
        self._tokenKindTab[@"break"] = @(TOKEN_KIND_BREAK);
        self._tokenKindTab[@"-="] = @(TOKEN_KIND_MINUSEQ);
        self._tokenKindTab[@">="] = @(TOKEN_KIND_GE);
        self._tokenKindTab[@":"] = @(TOKEN_KIND_COLON);
        self._tokenKindTab[@"in"] = @(TOKEN_KIND_IN);
        self._tokenKindTab[@";"] = @(TOKEN_KIND_SEMI);
        self._tokenKindTab[@"for"] = @(TOKEN_KIND_FOR);
        self._tokenKindTab[@"++"] = @(TOKEN_KIND_PLUSPLUS);
        self._tokenKindTab[@"<"] = @(TOKEN_KIND_LT);
        self._tokenKindTab[@"%="] = @(TOKEN_KIND_MODEQ);
        self._tokenKindTab[@">>"] = @(TOKEN_KIND_SHIFTRIGHT);
        self._tokenKindTab[@"="] = @(TOKEN_KIND_EQUALS);
        self._tokenKindTab[@">"] = @(TOKEN_KIND_GT);
        self._tokenKindTab[@"void"] = @(TOKEN_KIND_VOID);
        self._tokenKindTab[@"?"] = @(TOKEN_KIND_QUESTION);
        self._tokenKindTab[@"while"] = @(TOKEN_KIND_WHILE);
        self._tokenKindTab[@"&="] = @(TOKEN_KIND_ANDEQ);
        self._tokenKindTab[@">>>="] = @(TOKEN_KIND_SHIFTRIGHTEXTEQ);
        self._tokenKindTab[@"else"] = @(TOKEN_KIND_ELSE);
        self._tokenKindTab[@"/="] = @(TOKEN_KIND_DIVEQ);
        self._tokenKindTab[@"and"] = @(TOKEN_KIND_AND);
        self._tokenKindTab[@"var"] = @(TOKEN_KIND_VAR);
        self._tokenKindTab[@"|="] = @(TOKEN_KIND_OREQ);
        self._tokenKindTab[@">>="] = @(TOKEN_KIND_SHIFTRIGHTEQ);
        self._tokenKindTab[@"--"] = @(TOKEN_KIND_MINUSMINUS);
        self._tokenKindTab[@"new"] = @(TOKEN_KIND_KEYWORDNEW);
        self._tokenKindTab[@"!"] = @(TOKEN_KIND_NOT);
        self._tokenKindTab[@">>>"] = @(TOKEN_KIND_SHIFTRIGHTEXT);
        self._tokenKindTab[@"true"] = @(TOKEN_KIND_TRUELITERAL);
        self._tokenKindTab[@"this"] = @(TOKEN_KIND_THIS);
        self._tokenKindTab[@"with"] = @(TOKEN_KIND_WITH);
        self._tokenKindTab[@"==="] = @(TOKEN_KIND_IS);
        self._tokenKindTab[@"%"] = @(TOKEN_KIND_MOD);
        self._tokenKindTab[@"&"] = @(TOKEN_KIND_AMP);
        self._tokenKindTab[@"{"] = @(TOKEN_KIND_OPENCURLY);

        self.if_memo = [NSMutableDictionary dictionary];
        self.else_memo = [NSMutableDictionary dictionary];
        self.while_memo = [NSMutableDictionary dictionary];
        self.for_memo = [NSMutableDictionary dictionary];
        self.in_memo = [NSMutableDictionary dictionary];
        self.break_memo = [NSMutableDictionary dictionary];
        self.continue_memo = [NSMutableDictionary dictionary];
        self.with_memo = [NSMutableDictionary dictionary];
        self.return_memo = [NSMutableDictionary dictionary];
        self.var_memo = [NSMutableDictionary dictionary];
        self.delete_memo = [NSMutableDictionary dictionary];
        self.keywordNew_memo = [NSMutableDictionary dictionary];
        self.this_memo = [NSMutableDictionary dictionary];
        self.falseLiteral_memo = [NSMutableDictionary dictionary];
        self.trueLiteral_memo = [NSMutableDictionary dictionary];
        self.null_memo = [NSMutableDictionary dictionary];
        self.undefined_memo = [NSMutableDictionary dictionary];
        self.void_memo = [NSMutableDictionary dictionary];
        self.typeof_memo = [NSMutableDictionary dictionary];
        self.instanceof_memo = [NSMutableDictionary dictionary];
        self.function_memo = [NSMutableDictionary dictionary];
        self.openCurly_memo = [NSMutableDictionary dictionary];
        self.closeCurly_memo = [NSMutableDictionary dictionary];
        self.openParen_memo = [NSMutableDictionary dictionary];
        self.closeParen_memo = [NSMutableDictionary dictionary];
        self.openBracket_memo = [NSMutableDictionary dictionary];
        self.closeBracket_memo = [NSMutableDictionary dictionary];
        self.comma_memo = [NSMutableDictionary dictionary];
        self.dot_memo = [NSMutableDictionary dictionary];
        self.semi_memo = [NSMutableDictionary dictionary];
        self.colon_memo = [NSMutableDictionary dictionary];
        self.equals_memo = [NSMutableDictionary dictionary];
        self.not_memo = [NSMutableDictionary dictionary];
        self.lt_memo = [NSMutableDictionary dictionary];
        self.gt_memo = [NSMutableDictionary dictionary];
        self.amp_memo = [NSMutableDictionary dictionary];
        self.pipe_memo = [NSMutableDictionary dictionary];
        self.caret_memo = [NSMutableDictionary dictionary];
        self.tilde_memo = [NSMutableDictionary dictionary];
        self.question_memo = [NSMutableDictionary dictionary];
        self.plus_memo = [NSMutableDictionary dictionary];
        self.minus_memo = [NSMutableDictionary dictionary];
        self.times_memo = [NSMutableDictionary dictionary];
        self.div_memo = [NSMutableDictionary dictionary];
        self.mod_memo = [NSMutableDictionary dictionary];
        self.or_memo = [NSMutableDictionary dictionary];
        self.and_memo = [NSMutableDictionary dictionary];
        self.ne_memo = [NSMutableDictionary dictionary];
        self.isnot_memo = [NSMutableDictionary dictionary];
        self.eq_memo = [NSMutableDictionary dictionary];
        self.is_memo = [NSMutableDictionary dictionary];
        self.le_memo = [NSMutableDictionary dictionary];
        self.ge_memo = [NSMutableDictionary dictionary];
        self.plusPlus_memo = [NSMutableDictionary dictionary];
        self.minusMinus_memo = [NSMutableDictionary dictionary];
        self.plusEq_memo = [NSMutableDictionary dictionary];
        self.minusEq_memo = [NSMutableDictionary dictionary];
        self.timesEq_memo = [NSMutableDictionary dictionary];
        self.divEq_memo = [NSMutableDictionary dictionary];
        self.modEq_memo = [NSMutableDictionary dictionary];
        self.shiftLeft_memo = [NSMutableDictionary dictionary];
        self.shiftRight_memo = [NSMutableDictionary dictionary];
        self.shiftRightExt_memo = [NSMutableDictionary dictionary];
        self.shiftLeftEq_memo = [NSMutableDictionary dictionary];
        self.shiftRightEq_memo = [NSMutableDictionary dictionary];
        self.shiftRightExtEq_memo = [NSMutableDictionary dictionary];
        self.andEq_memo = [NSMutableDictionary dictionary];
        self.xorEq_memo = [NSMutableDictionary dictionary];
        self.orEq_memo = [NSMutableDictionary dictionary];
        self.assignmentOperator_memo = [NSMutableDictionary dictionary];
        self.relationalOperator_memo = [NSMutableDictionary dictionary];
        self.equalityOperator_memo = [NSMutableDictionary dictionary];
        self.shiftOperator_memo = [NSMutableDictionary dictionary];
        self.incrementOperator_memo = [NSMutableDictionary dictionary];
        self.unaryOperator_memo = [NSMutableDictionary dictionary];
        self.multiplicativeOperator_memo = [NSMutableDictionary dictionary];
        self.program_memo = [NSMutableDictionary dictionary];
        self.element_memo = [NSMutableDictionary dictionary];
        self.func_memo = [NSMutableDictionary dictionary];
        self.paramListOpt_memo = [NSMutableDictionary dictionary];
        self.paramList_memo = [NSMutableDictionary dictionary];
        self.commaIdentifier_memo = [NSMutableDictionary dictionary];
        self.compoundStmt_memo = [NSMutableDictionary dictionary];
        self.stmts_memo = [NSMutableDictionary dictionary];
        self.stmt_memo = [NSMutableDictionary dictionary];
        self.ifStmt_memo = [NSMutableDictionary dictionary];
        self.ifElseStmt_memo = [NSMutableDictionary dictionary];
        self.whileStmt_memo = [NSMutableDictionary dictionary];
        self.forParenStmt_memo = [NSMutableDictionary dictionary];
        self.forBeginStmt_memo = [NSMutableDictionary dictionary];
        self.forInStmt_memo = [NSMutableDictionary dictionary];
        self.breakStmt_memo = [NSMutableDictionary dictionary];
        self.continueStmt_memo = [NSMutableDictionary dictionary];
        self.withStmt_memo = [NSMutableDictionary dictionary];
        self.returnStmt_memo = [NSMutableDictionary dictionary];
        self.variablesOrExprStmt_memo = [NSMutableDictionary dictionary];
        self.condition_memo = [NSMutableDictionary dictionary];
        self.forParen_memo = [NSMutableDictionary dictionary];
        self.forBegin_memo = [NSMutableDictionary dictionary];
        self.variablesOrExpr_memo = [NSMutableDictionary dictionary];
        self.varVariables_memo = [NSMutableDictionary dictionary];
        self.variables_memo = [NSMutableDictionary dictionary];
        self.commaVariable_memo = [NSMutableDictionary dictionary];
        self.variable_memo = [NSMutableDictionary dictionary];
        self.assignment_memo = [NSMutableDictionary dictionary];
        self.exprOpt_memo = [NSMutableDictionary dictionary];
        self.expr_memo = [NSMutableDictionary dictionary];
        self.commaExpr_memo = [NSMutableDictionary dictionary];
        self.assignmentExpr_memo = [NSMutableDictionary dictionary];
        self.extraAssignment_memo = [NSMutableDictionary dictionary];
        self.conditionalExpr_memo = [NSMutableDictionary dictionary];
        self.ternaryExpr_memo = [NSMutableDictionary dictionary];
        self.orExpr_memo = [NSMutableDictionary dictionary];
        self.orAndExpr_memo = [NSMutableDictionary dictionary];
        self.andExpr_memo = [NSMutableDictionary dictionary];
        self.andAndExpr_memo = [NSMutableDictionary dictionary];
        self.bitwiseOrExpr_memo = [NSMutableDictionary dictionary];
        self.pipeBitwiseOrExpr_memo = [NSMutableDictionary dictionary];
        self.bitwiseXorExpr_memo = [NSMutableDictionary dictionary];
        self.caretBitwiseXorExpr_memo = [NSMutableDictionary dictionary];
        self.bitwiseAndExpr_memo = [NSMutableDictionary dictionary];
        self.ampBitwiseAndExpression_memo = [NSMutableDictionary dictionary];
        self.equalityExpr_memo = [NSMutableDictionary dictionary];
        self.equalityOpEqualityExpr_memo = [NSMutableDictionary dictionary];
        self.relationalExpr_memo = [NSMutableDictionary dictionary];
        self.shiftExpr_memo = [NSMutableDictionary dictionary];
        self.shiftOpShiftExpr_memo = [NSMutableDictionary dictionary];
        self.additiveExpr_memo = [NSMutableDictionary dictionary];
        self.plusOrMinusExpr_memo = [NSMutableDictionary dictionary];
        self.plusExpr_memo = [NSMutableDictionary dictionary];
        self.minusExpr_memo = [NSMutableDictionary dictionary];
        self.multiplicativeExpr_memo = [NSMutableDictionary dictionary];
        self.unaryExpr_memo = [NSMutableDictionary dictionary];
        self.unaryExpr1_memo = [NSMutableDictionary dictionary];
        self.unaryExpr2_memo = [NSMutableDictionary dictionary];
        self.unaryExpr3_memo = [NSMutableDictionary dictionary];
        self.unaryExpr4_memo = [NSMutableDictionary dictionary];
        self.callNewExpr_memo = [NSMutableDictionary dictionary];
        self.unaryExpr6_memo = [NSMutableDictionary dictionary];
        self.constructor_memo = [NSMutableDictionary dictionary];
        self.constructorCall_memo = [NSMutableDictionary dictionary];
        self.parenArgListParen_memo = [NSMutableDictionary dictionary];
        self.memberExpr_memo = [NSMutableDictionary dictionary];
        self.dotBracketOrParenExpr_memo = [NSMutableDictionary dictionary];
        self.dotMemberExpr_memo = [NSMutableDictionary dictionary];
        self.bracketMemberExpr_memo = [NSMutableDictionary dictionary];
        self.parenMemberExpr_memo = [NSMutableDictionary dictionary];
        self.argListOpt_memo = [NSMutableDictionary dictionary];
        self.argList_memo = [NSMutableDictionary dictionary];
        self.commaAssignmentExpr_memo = [NSMutableDictionary dictionary];
        self.primaryExpr_memo = [NSMutableDictionary dictionary];
        self.parenExprParen_memo = [NSMutableDictionary dictionary];
        self.identifier_memo = [NSMutableDictionary dictionary];
    }
	return self;
}

- (void)dealloc {
    self.if_memo = nil;
    self.else_memo = nil;
    self.while_memo = nil;
    self.for_memo = nil;
    self.in_memo = nil;
    self.break_memo = nil;
    self.continue_memo = nil;
    self.with_memo = nil;
    self.return_memo = nil;
    self.var_memo = nil;
    self.delete_memo = nil;
    self.keywordNew_memo = nil;
    self.this_memo = nil;
    self.falseLiteral_memo = nil;
    self.trueLiteral_memo = nil;
    self.null_memo = nil;
    self.undefined_memo = nil;
    self.void_memo = nil;
    self.typeof_memo = nil;
    self.instanceof_memo = nil;
    self.function_memo = nil;
    self.openCurly_memo = nil;
    self.closeCurly_memo = nil;
    self.openParen_memo = nil;
    self.closeParen_memo = nil;
    self.openBracket_memo = nil;
    self.closeBracket_memo = nil;
    self.comma_memo = nil;
    self.dot_memo = nil;
    self.semi_memo = nil;
    self.colon_memo = nil;
    self.equals_memo = nil;
    self.not_memo = nil;
    self.lt_memo = nil;
    self.gt_memo = nil;
    self.amp_memo = nil;
    self.pipe_memo = nil;
    self.caret_memo = nil;
    self.tilde_memo = nil;
    self.question_memo = nil;
    self.plus_memo = nil;
    self.minus_memo = nil;
    self.times_memo = nil;
    self.div_memo = nil;
    self.mod_memo = nil;
    self.or_memo = nil;
    self.and_memo = nil;
    self.ne_memo = nil;
    self.isnot_memo = nil;
    self.eq_memo = nil;
    self.is_memo = nil;
    self.le_memo = nil;
    self.ge_memo = nil;
    self.plusPlus_memo = nil;
    self.minusMinus_memo = nil;
    self.plusEq_memo = nil;
    self.minusEq_memo = nil;
    self.timesEq_memo = nil;
    self.divEq_memo = nil;
    self.modEq_memo = nil;
    self.shiftLeft_memo = nil;
    self.shiftRight_memo = nil;
    self.shiftRightExt_memo = nil;
    self.shiftLeftEq_memo = nil;
    self.shiftRightEq_memo = nil;
    self.shiftRightExtEq_memo = nil;
    self.andEq_memo = nil;
    self.xorEq_memo = nil;
    self.orEq_memo = nil;
    self.assignmentOperator_memo = nil;
    self.relationalOperator_memo = nil;
    self.equalityOperator_memo = nil;
    self.shiftOperator_memo = nil;
    self.incrementOperator_memo = nil;
    self.unaryOperator_memo = nil;
    self.multiplicativeOperator_memo = nil;
    self.program_memo = nil;
    self.element_memo = nil;
    self.func_memo = nil;
    self.paramListOpt_memo = nil;
    self.paramList_memo = nil;
    self.commaIdentifier_memo = nil;
    self.compoundStmt_memo = nil;
    self.stmts_memo = nil;
    self.stmt_memo = nil;
    self.ifStmt_memo = nil;
    self.ifElseStmt_memo = nil;
    self.whileStmt_memo = nil;
    self.forParenStmt_memo = nil;
    self.forBeginStmt_memo = nil;
    self.forInStmt_memo = nil;
    self.breakStmt_memo = nil;
    self.continueStmt_memo = nil;
    self.withStmt_memo = nil;
    self.returnStmt_memo = nil;
    self.variablesOrExprStmt_memo = nil;
    self.condition_memo = nil;
    self.forParen_memo = nil;
    self.forBegin_memo = nil;
    self.variablesOrExpr_memo = nil;
    self.varVariables_memo = nil;
    self.variables_memo = nil;
    self.commaVariable_memo = nil;
    self.variable_memo = nil;
    self.assignment_memo = nil;
    self.exprOpt_memo = nil;
    self.expr_memo = nil;
    self.commaExpr_memo = nil;
    self.assignmentExpr_memo = nil;
    self.extraAssignment_memo = nil;
    self.conditionalExpr_memo = nil;
    self.ternaryExpr_memo = nil;
    self.orExpr_memo = nil;
    self.orAndExpr_memo = nil;
    self.andExpr_memo = nil;
    self.andAndExpr_memo = nil;
    self.bitwiseOrExpr_memo = nil;
    self.pipeBitwiseOrExpr_memo = nil;
    self.bitwiseXorExpr_memo = nil;
    self.caretBitwiseXorExpr_memo = nil;
    self.bitwiseAndExpr_memo = nil;
    self.ampBitwiseAndExpression_memo = nil;
    self.equalityExpr_memo = nil;
    self.equalityOpEqualityExpr_memo = nil;
    self.relationalExpr_memo = nil;
    self.shiftExpr_memo = nil;
    self.shiftOpShiftExpr_memo = nil;
    self.additiveExpr_memo = nil;
    self.plusOrMinusExpr_memo = nil;
    self.plusExpr_memo = nil;
    self.minusExpr_memo = nil;
    self.multiplicativeExpr_memo = nil;
    self.unaryExpr_memo = nil;
    self.unaryExpr1_memo = nil;
    self.unaryExpr2_memo = nil;
    self.unaryExpr3_memo = nil;
    self.unaryExpr4_memo = nil;
    self.callNewExpr_memo = nil;
    self.unaryExpr6_memo = nil;
    self.constructor_memo = nil;
    self.constructorCall_memo = nil;
    self.parenArgListParen_memo = nil;
    self.memberExpr_memo = nil;
    self.dotBracketOrParenExpr_memo = nil;
    self.dotMemberExpr_memo = nil;
    self.bracketMemberExpr_memo = nil;
    self.parenMemberExpr_memo = nil;
    self.argListOpt_memo = nil;
    self.argList_memo = nil;
    self.commaAssignmentExpr_memo = nil;
    self.primaryExpr_memo = nil;
    self.parenExprParen_memo = nil;
    self.identifier_memo = nil;

    [super dealloc];
}

- (void)_clearMemo {
    [_if_memo removeAllObjects];
    [_else_memo removeAllObjects];
    [_while_memo removeAllObjects];
    [_for_memo removeAllObjects];
    [_in_memo removeAllObjects];
    [_break_memo removeAllObjects];
    [_continue_memo removeAllObjects];
    [_with_memo removeAllObjects];
    [_return_memo removeAllObjects];
    [_var_memo removeAllObjects];
    [_delete_memo removeAllObjects];
    [_keywordNew_memo removeAllObjects];
    [_this_memo removeAllObjects];
    [_falseLiteral_memo removeAllObjects];
    [_trueLiteral_memo removeAllObjects];
    [_null_memo removeAllObjects];
    [_undefined_memo removeAllObjects];
    [_void_memo removeAllObjects];
    [_typeof_memo removeAllObjects];
    [_instanceof_memo removeAllObjects];
    [_function_memo removeAllObjects];
    [_openCurly_memo removeAllObjects];
    [_closeCurly_memo removeAllObjects];
    [_openParen_memo removeAllObjects];
    [_closeParen_memo removeAllObjects];
    [_openBracket_memo removeAllObjects];
    [_closeBracket_memo removeAllObjects];
    [_comma_memo removeAllObjects];
    [_dot_memo removeAllObjects];
    [_semi_memo removeAllObjects];
    [_colon_memo removeAllObjects];
    [_equals_memo removeAllObjects];
    [_not_memo removeAllObjects];
    [_lt_memo removeAllObjects];
    [_gt_memo removeAllObjects];
    [_amp_memo removeAllObjects];
    [_pipe_memo removeAllObjects];
    [_caret_memo removeAllObjects];
    [_tilde_memo removeAllObjects];
    [_question_memo removeAllObjects];
    [_plus_memo removeAllObjects];
    [_minus_memo removeAllObjects];
    [_times_memo removeAllObjects];
    [_div_memo removeAllObjects];
    [_mod_memo removeAllObjects];
    [_or_memo removeAllObjects];
    [_and_memo removeAllObjects];
    [_ne_memo removeAllObjects];
    [_isnot_memo removeAllObjects];
    [_eq_memo removeAllObjects];
    [_is_memo removeAllObjects];
    [_le_memo removeAllObjects];
    [_ge_memo removeAllObjects];
    [_plusPlus_memo removeAllObjects];
    [_minusMinus_memo removeAllObjects];
    [_plusEq_memo removeAllObjects];
    [_minusEq_memo removeAllObjects];
    [_timesEq_memo removeAllObjects];
    [_divEq_memo removeAllObjects];
    [_modEq_memo removeAllObjects];
    [_shiftLeft_memo removeAllObjects];
    [_shiftRight_memo removeAllObjects];
    [_shiftRightExt_memo removeAllObjects];
    [_shiftLeftEq_memo removeAllObjects];
    [_shiftRightEq_memo removeAllObjects];
    [_shiftRightExtEq_memo removeAllObjects];
    [_andEq_memo removeAllObjects];
    [_xorEq_memo removeAllObjects];
    [_orEq_memo removeAllObjects];
    [_assignmentOperator_memo removeAllObjects];
    [_relationalOperator_memo removeAllObjects];
    [_equalityOperator_memo removeAllObjects];
    [_shiftOperator_memo removeAllObjects];
    [_incrementOperator_memo removeAllObjects];
    [_unaryOperator_memo removeAllObjects];
    [_multiplicativeOperator_memo removeAllObjects];
    [_program_memo removeAllObjects];
    [_element_memo removeAllObjects];
    [_func_memo removeAllObjects];
    [_paramListOpt_memo removeAllObjects];
    [_paramList_memo removeAllObjects];
    [_commaIdentifier_memo removeAllObjects];
    [_compoundStmt_memo removeAllObjects];
    [_stmts_memo removeAllObjects];
    [_stmt_memo removeAllObjects];
    [_ifStmt_memo removeAllObjects];
    [_ifElseStmt_memo removeAllObjects];
    [_whileStmt_memo removeAllObjects];
    [_forParenStmt_memo removeAllObjects];
    [_forBeginStmt_memo removeAllObjects];
    [_forInStmt_memo removeAllObjects];
    [_breakStmt_memo removeAllObjects];
    [_continueStmt_memo removeAllObjects];
    [_withStmt_memo removeAllObjects];
    [_returnStmt_memo removeAllObjects];
    [_variablesOrExprStmt_memo removeAllObjects];
    [_condition_memo removeAllObjects];
    [_forParen_memo removeAllObjects];
    [_forBegin_memo removeAllObjects];
    [_variablesOrExpr_memo removeAllObjects];
    [_varVariables_memo removeAllObjects];
    [_variables_memo removeAllObjects];
    [_commaVariable_memo removeAllObjects];
    [_variable_memo removeAllObjects];
    [_assignment_memo removeAllObjects];
    [_exprOpt_memo removeAllObjects];
    [_expr_memo removeAllObjects];
    [_commaExpr_memo removeAllObjects];
    [_assignmentExpr_memo removeAllObjects];
    [_extraAssignment_memo removeAllObjects];
    [_conditionalExpr_memo removeAllObjects];
    [_ternaryExpr_memo removeAllObjects];
    [_orExpr_memo removeAllObjects];
    [_orAndExpr_memo removeAllObjects];
    [_andExpr_memo removeAllObjects];
    [_andAndExpr_memo removeAllObjects];
    [_bitwiseOrExpr_memo removeAllObjects];
    [_pipeBitwiseOrExpr_memo removeAllObjects];
    [_bitwiseXorExpr_memo removeAllObjects];
    [_caretBitwiseXorExpr_memo removeAllObjects];
    [_bitwiseAndExpr_memo removeAllObjects];
    [_ampBitwiseAndExpression_memo removeAllObjects];
    [_equalityExpr_memo removeAllObjects];
    [_equalityOpEqualityExpr_memo removeAllObjects];
    [_relationalExpr_memo removeAllObjects];
    [_shiftExpr_memo removeAllObjects];
    [_shiftOpShiftExpr_memo removeAllObjects];
    [_additiveExpr_memo removeAllObjects];
    [_plusOrMinusExpr_memo removeAllObjects];
    [_plusExpr_memo removeAllObjects];
    [_minusExpr_memo removeAllObjects];
    [_multiplicativeExpr_memo removeAllObjects];
    [_unaryExpr_memo removeAllObjects];
    [_unaryExpr1_memo removeAllObjects];
    [_unaryExpr2_memo removeAllObjects];
    [_unaryExpr3_memo removeAllObjects];
    [_unaryExpr4_memo removeAllObjects];
    [_callNewExpr_memo removeAllObjects];
    [_unaryExpr6_memo removeAllObjects];
    [_constructor_memo removeAllObjects];
    [_constructorCall_memo removeAllObjects];
    [_parenArgListParen_memo removeAllObjects];
    [_memberExpr_memo removeAllObjects];
    [_dotBracketOrParenExpr_memo removeAllObjects];
    [_dotMemberExpr_memo removeAllObjects];
    [_bracketMemberExpr_memo removeAllObjects];
    [_parenMemberExpr_memo removeAllObjects];
    [_argListOpt_memo removeAllObjects];
    [_argList_memo removeAllObjects];
    [_commaAssignmentExpr_memo removeAllObjects];
    [_primaryExpr_memo removeAllObjects];
    [_parenExprParen_memo removeAllObjects];
    [_identifier_memo removeAllObjects];
}

- (void)_start {
    
    [self execute:(id)^{
        
	
	PKTokenizer *t = self.tokenizer;
	
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

    [self fireAssemblerSelector:@selector(parser:didMatch_start:)];
}

- (void)__if {
    
    [self match:TOKEN_KIND_IF]; 

    [self fireAssemblerSelector:@selector(parser:didMatchIf:)];
}

- (void)if {
    [self parseRule:@selector(__if) withMemo:_if_memo];
}

- (void)__else {
    
    [self match:TOKEN_KIND_ELSE]; 

    [self fireAssemblerSelector:@selector(parser:didMatchElse:)];
}

- (void)else {
    [self parseRule:@selector(__else) withMemo:_else_memo];
}

- (void)__while {
    
    [self match:TOKEN_KIND_WHILE]; 

    [self fireAssemblerSelector:@selector(parser:didMatchWhile:)];
}

- (void)while {
    [self parseRule:@selector(__while) withMemo:_while_memo];
}

- (void)__for {
    
    [self match:TOKEN_KIND_FOR]; 

    [self fireAssemblerSelector:@selector(parser:didMatchFor:)];
}

- (void)for {
    [self parseRule:@selector(__for) withMemo:_for_memo];
}

- (void)__in {
    
    [self match:TOKEN_KIND_IN]; 

    [self fireAssemblerSelector:@selector(parser:didMatchIn:)];
}

- (void)in {
    [self parseRule:@selector(__in) withMemo:_in_memo];
}

- (void)__break {
    
    [self match:TOKEN_KIND_BREAK]; 

    [self fireAssemblerSelector:@selector(parser:didMatchBreak:)];
}

- (void)break {
    [self parseRule:@selector(__break) withMemo:_break_memo];
}

- (void)__continue {
    
    [self match:TOKEN_KIND_CONTINUE]; 

    [self fireAssemblerSelector:@selector(parser:didMatchContinue:)];
}

- (void)continue {
    [self parseRule:@selector(__continue) withMemo:_continue_memo];
}

- (void)__with {
    
    [self match:TOKEN_KIND_WITH]; 

    [self fireAssemblerSelector:@selector(parser:didMatchWith:)];
}

- (void)with {
    [self parseRule:@selector(__with) withMemo:_with_memo];
}

- (void)__return {
    
    [self match:TOKEN_KIND_RETURN]; 

    [self fireAssemblerSelector:@selector(parser:didMatchReturn:)];
}

- (void)return {
    [self parseRule:@selector(__return) withMemo:_return_memo];
}

- (void)__var {
    
    [self match:TOKEN_KIND_VAR]; 

    [self fireAssemblerSelector:@selector(parser:didMatchVar:)];
}

- (void)var {
    [self parseRule:@selector(__var) withMemo:_var_memo];
}

- (void)__delete {
    
    [self match:TOKEN_KIND_DELETE]; 

    [self fireAssemblerSelector:@selector(parser:didMatchDelete:)];
}

- (void)delete {
    [self parseRule:@selector(__delete) withMemo:_delete_memo];
}

- (void)__keywordNew {
    
    [self match:TOKEN_KIND_KEYWORDNEW]; 

    [self fireAssemblerSelector:@selector(parser:didMatchKeywordNew:)];
}

- (void)keywordNew {
    [self parseRule:@selector(__keywordNew) withMemo:_keywordNew_memo];
}

- (void)__this {
    
    [self match:TOKEN_KIND_THIS]; 

    [self fireAssemblerSelector:@selector(parser:didMatchThis:)];
}

- (void)this {
    [self parseRule:@selector(__this) withMemo:_this_memo];
}

- (void)__falseLiteral {
    
    [self match:TOKEN_KIND_FALSELITERAL]; 

    [self fireAssemblerSelector:@selector(parser:didMatchFalseLiteral:)];
}

- (void)falseLiteral {
    [self parseRule:@selector(__falseLiteral) withMemo:_falseLiteral_memo];
}

- (void)__trueLiteral {
    
    [self match:TOKEN_KIND_TRUELITERAL]; 

    [self fireAssemblerSelector:@selector(parser:didMatchTrueLiteral:)];
}

- (void)trueLiteral {
    [self parseRule:@selector(__trueLiteral) withMemo:_trueLiteral_memo];
}

- (void)__null {
    
    [self match:TOKEN_KIND_NULL]; 

    [self fireAssemblerSelector:@selector(parser:didMatchNull:)];
}

- (void)null {
    [self parseRule:@selector(__null) withMemo:_null_memo];
}

- (void)__undefined {
    
    [self match:TOKEN_KIND_UNDEFINED]; 

    [self fireAssemblerSelector:@selector(parser:didMatchUndefined:)];
}

- (void)undefined {
    [self parseRule:@selector(__undefined) withMemo:_undefined_memo];
}

- (void)__void {
    
    [self match:TOKEN_KIND_VOID]; 

    [self fireAssemblerSelector:@selector(parser:didMatchVoid:)];
}

- (void)void {
    [self parseRule:@selector(__void) withMemo:_void_memo];
}

- (void)__typeof {
    
    [self match:TOKEN_KIND_TYPEOF]; 

    [self fireAssemblerSelector:@selector(parser:didMatchTypeof:)];
}

- (void)typeof {
    [self parseRule:@selector(__typeof) withMemo:_typeof_memo];
}

- (void)__instanceof {
    
    [self match:TOKEN_KIND_INSTANCEOF]; 

    [self fireAssemblerSelector:@selector(parser:didMatchInstanceof:)];
}

- (void)instanceof {
    [self parseRule:@selector(__instanceof) withMemo:_instanceof_memo];
}

- (void)__function {
    
    [self match:TOKEN_KIND_FUNCTION]; 

    [self fireAssemblerSelector:@selector(parser:didMatchFunction:)];
}

- (void)function {
    [self parseRule:@selector(__function) withMemo:_function_memo];
}

- (void)__openCurly {
    
    [self match:TOKEN_KIND_OPENCURLY]; 

    [self fireAssemblerSelector:@selector(parser:didMatchOpenCurly:)];
}

- (void)openCurly {
    [self parseRule:@selector(__openCurly) withMemo:_openCurly_memo];
}

- (void)__closeCurly {
    
    [self match:TOKEN_KIND_CLOSECURLY]; 

    [self fireAssemblerSelector:@selector(parser:didMatchCloseCurly:)];
}

- (void)closeCurly {
    [self parseRule:@selector(__closeCurly) withMemo:_closeCurly_memo];
}

- (void)__openParen {
    
    [self match:TOKEN_KIND_OPENPAREN]; 

    [self fireAssemblerSelector:@selector(parser:didMatchOpenParen:)];
}

- (void)openParen {
    [self parseRule:@selector(__openParen) withMemo:_openParen_memo];
}

- (void)__closeParen {
    
    [self match:TOKEN_KIND_CLOSEPAREN]; 

    [self fireAssemblerSelector:@selector(parser:didMatchCloseParen:)];
}

- (void)closeParen {
    [self parseRule:@selector(__closeParen) withMemo:_closeParen_memo];
}

- (void)__openBracket {
    
    [self match:TOKEN_KIND_OPENBRACKET]; 

    [self fireAssemblerSelector:@selector(parser:didMatchOpenBracket:)];
}

- (void)openBracket {
    [self parseRule:@selector(__openBracket) withMemo:_openBracket_memo];
}

- (void)__closeBracket {
    
    [self match:TOKEN_KIND_CLOSEBRACKET]; 

    [self fireAssemblerSelector:@selector(parser:didMatchCloseBracket:)];
}

- (void)closeBracket {
    [self parseRule:@selector(__closeBracket) withMemo:_closeBracket_memo];
}

- (void)__comma {
    
    [self match:TOKEN_KIND_COMMA]; 

    [self fireAssemblerSelector:@selector(parser:didMatchComma:)];
}

- (void)comma {
    [self parseRule:@selector(__comma) withMemo:_comma_memo];
}

- (void)__dot {
    
    [self match:TOKEN_KIND_DOT]; 

    [self fireAssemblerSelector:@selector(parser:didMatchDot:)];
}

- (void)dot {
    [self parseRule:@selector(__dot) withMemo:_dot_memo];
}

- (void)__semi {
    
    [self match:TOKEN_KIND_SEMI]; 

    [self fireAssemblerSelector:@selector(parser:didMatchSemi:)];
}

- (void)semi {
    [self parseRule:@selector(__semi) withMemo:_semi_memo];
}

- (void)__colon {
    
    [self match:TOKEN_KIND_COLON]; 

    [self fireAssemblerSelector:@selector(parser:didMatchColon:)];
}

- (void)colon {
    [self parseRule:@selector(__colon) withMemo:_colon_memo];
}

- (void)__equals {
    
    [self match:TOKEN_KIND_EQUALS]; 

    [self fireAssemblerSelector:@selector(parser:didMatchEquals:)];
}

- (void)equals {
    [self parseRule:@selector(__equals) withMemo:_equals_memo];
}

- (void)__not {
    
    [self match:TOKEN_KIND_NOT]; 

    [self fireAssemblerSelector:@selector(parser:didMatchNot:)];
}

- (void)not {
    [self parseRule:@selector(__not) withMemo:_not_memo];
}

- (void)__lt {
    
    [self match:TOKEN_KIND_LT]; 

    [self fireAssemblerSelector:@selector(parser:didMatchLt:)];
}

- (void)lt {
    [self parseRule:@selector(__lt) withMemo:_lt_memo];
}

- (void)__gt {
    
    [self match:TOKEN_KIND_GT]; 

    [self fireAssemblerSelector:@selector(parser:didMatchGt:)];
}

- (void)gt {
    [self parseRule:@selector(__gt) withMemo:_gt_memo];
}

- (void)__amp {
    
    [self match:TOKEN_KIND_AMP]; 

    [self fireAssemblerSelector:@selector(parser:didMatchAmp:)];
}

- (void)amp {
    [self parseRule:@selector(__amp) withMemo:_amp_memo];
}

- (void)__pipe {
    
    [self match:TOKEN_KIND_PIPE]; 

    [self fireAssemblerSelector:@selector(parser:didMatchPipe:)];
}

- (void)pipe {
    [self parseRule:@selector(__pipe) withMemo:_pipe_memo];
}

- (void)__caret {
    
    [self match:TOKEN_KIND_CARET]; 

    [self fireAssemblerSelector:@selector(parser:didMatchCaret:)];
}

- (void)caret {
    [self parseRule:@selector(__caret) withMemo:_caret_memo];
}

- (void)__tilde {
    
    [self match:TOKEN_KIND_TILDE]; 

    [self fireAssemblerSelector:@selector(parser:didMatchTilde:)];
}

- (void)tilde {
    [self parseRule:@selector(__tilde) withMemo:_tilde_memo];
}

- (void)__question {
    
    [self match:TOKEN_KIND_QUESTION]; 

    [self fireAssemblerSelector:@selector(parser:didMatchQuestion:)];
}

- (void)question {
    [self parseRule:@selector(__question) withMemo:_question_memo];
}

- (void)__plus {
    
    [self match:TOKEN_KIND_PLUS]; 

    [self fireAssemblerSelector:@selector(parser:didMatchPlus:)];
}

- (void)plus {
    [self parseRule:@selector(__plus) withMemo:_plus_memo];
}

- (void)__minus {
    
    [self match:TOKEN_KIND_MINUS]; 

    [self fireAssemblerSelector:@selector(parser:didMatchMinus:)];
}

- (void)minus {
    [self parseRule:@selector(__minus) withMemo:_minus_memo];
}

- (void)__times {
    
    [self match:TOKEN_KIND_TIMES]; 

    [self fireAssemblerSelector:@selector(parser:didMatchTimes:)];
}

- (void)times {
    [self parseRule:@selector(__times) withMemo:_times_memo];
}

- (void)__div {
    
    [self match:TOKEN_KIND_DIV]; 

    [self fireAssemblerSelector:@selector(parser:didMatchDiv:)];
}

- (void)div {
    [self parseRule:@selector(__div) withMemo:_div_memo];
}

- (void)__mod {
    
    [self match:TOKEN_KIND_MOD]; 

    [self fireAssemblerSelector:@selector(parser:didMatchMod:)];
}

- (void)mod {
    [self parseRule:@selector(__mod) withMemo:_mod_memo];
}

- (void)__or {
    
    [self match:TOKEN_KIND_OR]; 

    [self fireAssemblerSelector:@selector(parser:didMatchOr:)];
}

- (void)or {
    [self parseRule:@selector(__or) withMemo:_or_memo];
}

- (void)__and {
    
    [self match:TOKEN_KIND_AND]; 

    [self fireAssemblerSelector:@selector(parser:didMatchAnd:)];
}

- (void)and {
    [self parseRule:@selector(__and) withMemo:_and_memo];
}

- (void)__ne {
    
    [self match:TOKEN_KIND_NE]; 

    [self fireAssemblerSelector:@selector(parser:didMatchNe:)];
}

- (void)ne {
    [self parseRule:@selector(__ne) withMemo:_ne_memo];
}

- (void)__isnot {
    
    [self match:TOKEN_KIND_ISNOT]; 

    [self fireAssemblerSelector:@selector(parser:didMatchIsnot:)];
}

- (void)isnot {
    [self parseRule:@selector(__isnot) withMemo:_isnot_memo];
}

- (void)__eq {
    
    [self match:TOKEN_KIND_EQ]; 

    [self fireAssemblerSelector:@selector(parser:didMatchEq:)];
}

- (void)eq {
    [self parseRule:@selector(__eq) withMemo:_eq_memo];
}

- (void)__is {
    
    [self match:TOKEN_KIND_IS]; 

    [self fireAssemblerSelector:@selector(parser:didMatchIs:)];
}

- (void)is {
    [self parseRule:@selector(__is) withMemo:_is_memo];
}

- (void)__le {
    
    [self match:TOKEN_KIND_LE]; 

    [self fireAssemblerSelector:@selector(parser:didMatchLe:)];
}

- (void)le {
    [self parseRule:@selector(__le) withMemo:_le_memo];
}

- (void)__ge {
    
    [self match:TOKEN_KIND_GE]; 

    [self fireAssemblerSelector:@selector(parser:didMatchGe:)];
}

- (void)ge {
    [self parseRule:@selector(__ge) withMemo:_ge_memo];
}

- (void)__plusPlus {
    
    [self match:TOKEN_KIND_PLUSPLUS]; 

    [self fireAssemblerSelector:@selector(parser:didMatchPlusPlus:)];
}

- (void)plusPlus {
    [self parseRule:@selector(__plusPlus) withMemo:_plusPlus_memo];
}

- (void)__minusMinus {
    
    [self match:TOKEN_KIND_MINUSMINUS]; 

    [self fireAssemblerSelector:@selector(parser:didMatchMinusMinus:)];
}

- (void)minusMinus {
    [self parseRule:@selector(__minusMinus) withMemo:_minusMinus_memo];
}

- (void)__plusEq {
    
    [self match:TOKEN_KIND_PLUSEQ]; 

    [self fireAssemblerSelector:@selector(parser:didMatchPlusEq:)];
}

- (void)plusEq {
    [self parseRule:@selector(__plusEq) withMemo:_plusEq_memo];
}

- (void)__minusEq {
    
    [self match:TOKEN_KIND_MINUSEQ]; 

    [self fireAssemblerSelector:@selector(parser:didMatchMinusEq:)];
}

- (void)minusEq {
    [self parseRule:@selector(__minusEq) withMemo:_minusEq_memo];
}

- (void)__timesEq {
    
    [self match:TOKEN_KIND_TIMESEQ]; 

    [self fireAssemblerSelector:@selector(parser:didMatchTimesEq:)];
}

- (void)timesEq {
    [self parseRule:@selector(__timesEq) withMemo:_timesEq_memo];
}

- (void)__divEq {
    
    [self match:TOKEN_KIND_DIVEQ]; 

    [self fireAssemblerSelector:@selector(parser:didMatchDivEq:)];
}

- (void)divEq {
    [self parseRule:@selector(__divEq) withMemo:_divEq_memo];
}

- (void)__modEq {
    
    [self match:TOKEN_KIND_MODEQ]; 

    [self fireAssemblerSelector:@selector(parser:didMatchModEq:)];
}

- (void)modEq {
    [self parseRule:@selector(__modEq) withMemo:_modEq_memo];
}

- (void)__shiftLeft {
    
    [self match:TOKEN_KIND_SHIFTLEFT]; 

    [self fireAssemblerSelector:@selector(parser:didMatchShiftLeft:)];
}

- (void)shiftLeft {
    [self parseRule:@selector(__shiftLeft) withMemo:_shiftLeft_memo];
}

- (void)__shiftRight {
    
    [self match:TOKEN_KIND_SHIFTRIGHT]; 

    [self fireAssemblerSelector:@selector(parser:didMatchShiftRight:)];
}

- (void)shiftRight {
    [self parseRule:@selector(__shiftRight) withMemo:_shiftRight_memo];
}

- (void)__shiftRightExt {
    
    [self match:TOKEN_KIND_SHIFTRIGHTEXT]; 

    [self fireAssemblerSelector:@selector(parser:didMatchShiftRightExt:)];
}

- (void)shiftRightExt {
    [self parseRule:@selector(__shiftRightExt) withMemo:_shiftRightExt_memo];
}

- (void)__shiftLeftEq {
    
    [self match:TOKEN_KIND_SHIFTLEFTEQ]; 

    [self fireAssemblerSelector:@selector(parser:didMatchShiftLeftEq:)];
}

- (void)shiftLeftEq {
    [self parseRule:@selector(__shiftLeftEq) withMemo:_shiftLeftEq_memo];
}

- (void)__shiftRightEq {
    
    [self match:TOKEN_KIND_SHIFTRIGHTEQ]; 

    [self fireAssemblerSelector:@selector(parser:didMatchShiftRightEq:)];
}

- (void)shiftRightEq {
    [self parseRule:@selector(__shiftRightEq) withMemo:_shiftRightEq_memo];
}

- (void)__shiftRightExtEq {
    
    [self match:TOKEN_KIND_SHIFTRIGHTEXTEQ]; 

    [self fireAssemblerSelector:@selector(parser:didMatchShiftRightExtEq:)];
}

- (void)shiftRightExtEq {
    [self parseRule:@selector(__shiftRightExtEq) withMemo:_shiftRightExtEq_memo];
}

- (void)__andEq {
    
    [self match:TOKEN_KIND_ANDEQ]; 

    [self fireAssemblerSelector:@selector(parser:didMatchAndEq:)];
}

- (void)andEq {
    [self parseRule:@selector(__andEq) withMemo:_andEq_memo];
}

- (void)__xorEq {
    
    [self match:TOKEN_KIND_XOREQ]; 

    [self fireAssemblerSelector:@selector(parser:didMatchXorEq:)];
}

- (void)xorEq {
    [self parseRule:@selector(__xorEq) withMemo:_xorEq_memo];
}

- (void)__orEq {
    
    [self match:TOKEN_KIND_OREQ]; 

    [self fireAssemblerSelector:@selector(parser:didMatchOrEq:)];
}

- (void)orEq {
    [self parseRule:@selector(__orEq) withMemo:_orEq_memo];
}

- (void)__assignmentOperator {
    
    if ([self predicts:TOKEN_KIND_EQUALS, 0]) {
        [self equals]; 
    } else if ([self predicts:TOKEN_KIND_PLUSEQ, 0]) {
        [self plusEq]; 
    } else if ([self predicts:TOKEN_KIND_MINUSEQ, 0]) {
        [self minusEq]; 
    } else if ([self predicts:TOKEN_KIND_TIMESEQ, 0]) {
        [self timesEq]; 
    } else if ([self predicts:TOKEN_KIND_DIVEQ, 0]) {
        [self divEq]; 
    } else if ([self predicts:TOKEN_KIND_MODEQ, 0]) {
        [self modEq]; 
    } else if ([self predicts:TOKEN_KIND_SHIFTLEFTEQ, 0]) {
        [self shiftLeftEq]; 
    } else if ([self predicts:TOKEN_KIND_SHIFTRIGHTEQ, 0]) {
        [self shiftRightEq]; 
    } else if ([self predicts:TOKEN_KIND_SHIFTRIGHTEXTEQ, 0]) {
        [self shiftRightExtEq]; 
    } else if ([self predicts:TOKEN_KIND_ANDEQ, 0]) {
        [self andEq]; 
    } else if ([self predicts:TOKEN_KIND_XOREQ, 0]) {
        [self xorEq]; 
    } else if ([self predicts:TOKEN_KIND_OREQ, 0]) {
        [self orEq]; 
    } else {
        [self raise:@"no viable alternative found in assignmentOperator"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchAssignmentOperator:)];
}

- (void)assignmentOperator {
    [self parseRule:@selector(__assignmentOperator) withMemo:_assignmentOperator_memo];
}

- (void)__relationalOperator {
    
    if ([self predicts:TOKEN_KIND_LT, 0]) {
        [self lt]; 
    } else if ([self predicts:TOKEN_KIND_GT, 0]) {
        [self gt]; 
    } else if ([self predicts:TOKEN_KIND_GE, 0]) {
        [self ge]; 
    } else if ([self predicts:TOKEN_KIND_LE, 0]) {
        [self le]; 
    } else if ([self predicts:TOKEN_KIND_INSTANCEOF, 0]) {
        [self instanceof]; 
    } else {
        [self raise:@"no viable alternative found in relationalOperator"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchRelationalOperator:)];
}

- (void)relationalOperator {
    [self parseRule:@selector(__relationalOperator) withMemo:_relationalOperator_memo];
}

- (void)__equalityOperator {
    
    if ([self predicts:TOKEN_KIND_EQ, 0]) {
        [self eq]; 
    } else if ([self predicts:TOKEN_KIND_NE, 0]) {
        [self ne]; 
    } else if ([self predicts:TOKEN_KIND_IS, 0]) {
        [self is]; 
    } else if ([self predicts:TOKEN_KIND_ISNOT, 0]) {
        [self isnot]; 
    } else {
        [self raise:@"no viable alternative found in equalityOperator"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchEqualityOperator:)];
}

- (void)equalityOperator {
    [self parseRule:@selector(__equalityOperator) withMemo:_equalityOperator_memo];
}

- (void)__shiftOperator {
    
    if ([self predicts:TOKEN_KIND_SHIFTLEFT, 0]) {
        [self shiftLeft]; 
    } else if ([self predicts:TOKEN_KIND_SHIFTRIGHT, 0]) {
        [self shiftRight]; 
    } else if ([self predicts:TOKEN_KIND_SHIFTRIGHTEXT, 0]) {
        [self shiftRightExt]; 
    } else {
        [self raise:@"no viable alternative found in shiftOperator"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchShiftOperator:)];
}

- (void)shiftOperator {
    [self parseRule:@selector(__shiftOperator) withMemo:_shiftOperator_memo];
}

- (void)__incrementOperator {
    
    if ([self predicts:TOKEN_KIND_PLUSPLUS, 0]) {
        [self plusPlus]; 
    } else if ([self predicts:TOKEN_KIND_MINUSMINUS, 0]) {
        [self minusMinus]; 
    } else {
        [self raise:@"no viable alternative found in incrementOperator"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchIncrementOperator:)];
}

- (void)incrementOperator {
    [self parseRule:@selector(__incrementOperator) withMemo:_incrementOperator_memo];
}

- (void)__unaryOperator {
    
    if ([self predicts:TOKEN_KIND_TILDE, 0]) {
        [self tilde]; 
    } else if ([self predicts:TOKEN_KIND_DELETE, 0]) {
        [self delete]; 
    } else if ([self predicts:TOKEN_KIND_TYPEOF, 0]) {
        [self typeof]; 
    } else if ([self predicts:TOKEN_KIND_VOID, 0]) {
        [self void]; 
    } else {
        [self raise:@"no viable alternative found in unaryOperator"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchUnaryOperator:)];
}

- (void)unaryOperator {
    [self parseRule:@selector(__unaryOperator) withMemo:_unaryOperator_memo];
}

- (void)__multiplicativeOperator {
    
    if ([self predicts:TOKEN_KIND_TIMES, 0]) {
        [self times]; 
    } else if ([self predicts:TOKEN_KIND_DIV, 0]) {
        [self div]; 
    } else if ([self predicts:TOKEN_KIND_MOD, 0]) {
        [self mod]; 
    } else {
        [self raise:@"no viable alternative found in multiplicativeOperator"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchMultiplicativeOperator:)];
}

- (void)multiplicativeOperator {
    [self parseRule:@selector(__multiplicativeOperator) withMemo:_multiplicativeOperator_memo];
}

- (void)__program {
    
    do {
        [self element]; 
    } while ([self speculate:^{ [self element]; }]);

    [self fireAssemblerSelector:@selector(parser:didMatchProgram:)];
}

- (void)program {
    [self parseRule:@selector(__program) withMemo:_program_memo];
}

- (void)__element {
    
    if ([self predicts:TOKEN_KIND_FUNCTION, 0]) {
        [self func]; 
    } else if ([self predicts:TOKEN_KIND_BREAK, TOKEN_KIND_BUILTIN_NUMBER, TOKEN_KIND_BUILTIN_QUOTEDSTRING, TOKEN_KIND_BUILTIN_WORD, TOKEN_KIND_CONTINUE, TOKEN_KIND_DELETE, TOKEN_KIND_FALSELITERAL, TOKEN_KIND_FOR, TOKEN_KIND_IF, TOKEN_KIND_KEYWORDNEW, TOKEN_KIND_MINUS, TOKEN_KIND_MINUSMINUS, TOKEN_KIND_NULL, TOKEN_KIND_OPENCURLY, TOKEN_KIND_OPENPAREN, TOKEN_KIND_PLUSPLUS, TOKEN_KIND_RETURN, TOKEN_KIND_SEMI, TOKEN_KIND_THIS, TOKEN_KIND_TILDE, TOKEN_KIND_TRUELITERAL, TOKEN_KIND_TYPEOF, TOKEN_KIND_UNDEFINED, TOKEN_KIND_VAR, TOKEN_KIND_VOID, TOKEN_KIND_WHILE, TOKEN_KIND_WITH, 0]) {
        [self stmt]; 
    } else {
        [self raise:@"no viable alternative found in element"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchElement:)];
}

- (void)element {
    [self parseRule:@selector(__element) withMemo:_element_memo];
}

- (void)__func {
    
    [self function]; 
    [self identifier]; 
    [self openParen]; 
    [self paramListOpt]; 
    [self closeParen]; 
    [self compoundStmt]; 

    [self fireAssemblerSelector:@selector(parser:didMatchFunc:)];
}

- (void)func {
    [self parseRule:@selector(__func) withMemo:_func_memo];
}

- (void)__paramListOpt {
    
    if ([self predicts:TOKEN_KIND_BUILTIN_WORD, 0]) {
        [self paramList]; 
    }

    [self fireAssemblerSelector:@selector(parser:didMatchParamListOpt:)];
}

- (void)paramListOpt {
    [self parseRule:@selector(__paramListOpt) withMemo:_paramListOpt_memo];
}

- (void)__paramList {
    
    [self identifier]; 
    while ([self predicts:TOKEN_KIND_COMMA, 0]) {
        if ([self speculate:^{ [self commaIdentifier]; }]) {
            [self commaIdentifier]; 
        } else {
            break;
        }
    }

    [self fireAssemblerSelector:@selector(parser:didMatchParamList:)];
}

- (void)paramList {
    [self parseRule:@selector(__paramList) withMemo:_paramList_memo];
}

- (void)__commaIdentifier {
    
    [self comma]; 
    [self identifier]; 

    [self fireAssemblerSelector:@selector(parser:didMatchCommaIdentifier:)];
}

- (void)commaIdentifier {
    [self parseRule:@selector(__commaIdentifier) withMemo:_commaIdentifier_memo];
}

- (void)__compoundStmt {
    
    [self openCurly]; 
    [self stmts]; 
    [self closeCurly]; 

    [self fireAssemblerSelector:@selector(parser:didMatchCompoundStmt:)];
}

- (void)compoundStmt {
    [self parseRule:@selector(__compoundStmt) withMemo:_compoundStmt_memo];
}

- (void)__stmts {
    
    while ([self predicts:TOKEN_KIND_BREAK, TOKEN_KIND_BUILTIN_NUMBER, TOKEN_KIND_BUILTIN_QUOTEDSTRING, TOKEN_KIND_BUILTIN_WORD, TOKEN_KIND_CONTINUE, TOKEN_KIND_DELETE, TOKEN_KIND_FALSELITERAL, TOKEN_KIND_FOR, TOKEN_KIND_IF, TOKEN_KIND_KEYWORDNEW, TOKEN_KIND_MINUS, TOKEN_KIND_MINUSMINUS, TOKEN_KIND_NULL, TOKEN_KIND_OPENCURLY, TOKEN_KIND_OPENPAREN, TOKEN_KIND_PLUSPLUS, TOKEN_KIND_RETURN, TOKEN_KIND_SEMI, TOKEN_KIND_THIS, TOKEN_KIND_TILDE, TOKEN_KIND_TRUELITERAL, TOKEN_KIND_TYPEOF, TOKEN_KIND_UNDEFINED, TOKEN_KIND_VAR, TOKEN_KIND_VOID, TOKEN_KIND_WHILE, TOKEN_KIND_WITH, 0]) {
        if ([self speculate:^{ [self stmt]; }]) {
            [self stmt]; 
        } else {
            break;
        }
    }

    [self fireAssemblerSelector:@selector(parser:didMatchStmts:)];
}

- (void)stmts {
    [self parseRule:@selector(__stmts) withMemo:_stmts_memo];
}

- (void)__stmt {
    
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

    [self fireAssemblerSelector:@selector(parser:didMatchStmt:)];
}

- (void)stmt {
    [self parseRule:@selector(__stmt) withMemo:_stmt_memo];
}

- (void)__ifStmt {
    
    [self if]; 
    [self condition]; 
    [self stmt]; 

    [self fireAssemblerSelector:@selector(parser:didMatchIfStmt:)];
}

- (void)ifStmt {
    [self parseRule:@selector(__ifStmt) withMemo:_ifStmt_memo];
}

- (void)__ifElseStmt {
    
    [self if]; 
    [self condition]; 
    [self stmt]; 
    [self else]; 
    [self stmt]; 

    [self fireAssemblerSelector:@selector(parser:didMatchIfElseStmt:)];
}

- (void)ifElseStmt {
    [self parseRule:@selector(__ifElseStmt) withMemo:_ifElseStmt_memo];
}

- (void)__whileStmt {
    
    [self while]; 
    [self condition]; 
    [self stmt]; 

    [self fireAssemblerSelector:@selector(parser:didMatchWhileStmt:)];
}

- (void)whileStmt {
    [self parseRule:@selector(__whileStmt) withMemo:_whileStmt_memo];
}

- (void)__forParenStmt {
    
    [self forParen]; 
    [self semi]; 
    [self exprOpt]; 
    [self semi]; 
    [self exprOpt]; 
    [self closeParen]; 
    [self stmt]; 

    [self fireAssemblerSelector:@selector(parser:didMatchForParenStmt:)];
}

- (void)forParenStmt {
    [self parseRule:@selector(__forParenStmt) withMemo:_forParenStmt_memo];
}

- (void)__forBeginStmt {
    
    [self forBegin]; 
    [self semi]; 
    [self exprOpt]; 
    [self semi]; 
    [self exprOpt]; 
    [self closeParen]; 
    [self stmt]; 

    [self fireAssemblerSelector:@selector(parser:didMatchForBeginStmt:)];
}

- (void)forBeginStmt {
    [self parseRule:@selector(__forBeginStmt) withMemo:_forBeginStmt_memo];
}

- (void)__forInStmt {
    
    [self forBegin]; 
    [self in]; 
    [self expr]; 
    [self closeParen]; 
    [self stmt]; 

    [self fireAssemblerSelector:@selector(parser:didMatchForInStmt:)];
}

- (void)forInStmt {
    [self parseRule:@selector(__forInStmt) withMemo:_forInStmt_memo];
}

- (void)__breakStmt {
    
    [self break]; 
    [self semi]; 

    [self fireAssemblerSelector:@selector(parser:didMatchBreakStmt:)];
}

- (void)breakStmt {
    [self parseRule:@selector(__breakStmt) withMemo:_breakStmt_memo];
}

- (void)__continueStmt {
    
    [self continue]; 
    [self semi]; 

    [self fireAssemblerSelector:@selector(parser:didMatchContinueStmt:)];
}

- (void)continueStmt {
    [self parseRule:@selector(__continueStmt) withMemo:_continueStmt_memo];
}

- (void)__withStmt {
    
    [self with]; 
    [self openParen]; 
    [self expr]; 
    [self closeParen]; 
    [self stmt]; 

    [self fireAssemblerSelector:@selector(parser:didMatchWithStmt:)];
}

- (void)withStmt {
    [self parseRule:@selector(__withStmt) withMemo:_withStmt_memo];
}

- (void)__returnStmt {
    
    [self return]; 
    [self exprOpt]; 
    [self semi]; 

    [self fireAssemblerSelector:@selector(parser:didMatchReturnStmt:)];
}

- (void)returnStmt {
    [self parseRule:@selector(__returnStmt) withMemo:_returnStmt_memo];
}

- (void)__variablesOrExprStmt {
    
    [self variablesOrExpr]; 
    [self semi]; 

    [self fireAssemblerSelector:@selector(parser:didMatchVariablesOrExprStmt:)];
}

- (void)variablesOrExprStmt {
    [self parseRule:@selector(__variablesOrExprStmt) withMemo:_variablesOrExprStmt_memo];
}

- (void)__condition {
    
    [self openParen]; 
    [self expr]; 
    [self closeParen]; 

    [self fireAssemblerSelector:@selector(parser:didMatchCondition:)];
}

- (void)condition {
    [self parseRule:@selector(__condition) withMemo:_condition_memo];
}

- (void)__forParen {
    
    [self for]; 
    [self openParen]; 

    [self fireAssemblerSelector:@selector(parser:didMatchForParen:)];
}

- (void)forParen {
    [self parseRule:@selector(__forParen) withMemo:_forParen_memo];
}

- (void)__forBegin {
    
    [self forParen]; 
    [self variablesOrExpr]; 

    [self fireAssemblerSelector:@selector(parser:didMatchForBegin:)];
}

- (void)forBegin {
    [self parseRule:@selector(__forBegin) withMemo:_forBegin_memo];
}

- (void)__variablesOrExpr {
    
    if ([self predicts:TOKEN_KIND_VAR, 0]) {
        [self varVariables]; 
    } else if ([self predicts:TOKEN_KIND_BUILTIN_NUMBER, TOKEN_KIND_BUILTIN_QUOTEDSTRING, TOKEN_KIND_BUILTIN_WORD, TOKEN_KIND_DELETE, TOKEN_KIND_FALSELITERAL, TOKEN_KIND_KEYWORDNEW, TOKEN_KIND_MINUS, TOKEN_KIND_MINUSMINUS, TOKEN_KIND_NULL, TOKEN_KIND_OPENPAREN, TOKEN_KIND_PLUSPLUS, TOKEN_KIND_THIS, TOKEN_KIND_TILDE, TOKEN_KIND_TRUELITERAL, TOKEN_KIND_TYPEOF, TOKEN_KIND_UNDEFINED, TOKEN_KIND_VOID, 0]) {
        [self expr]; 
    } else {
        [self raise:@"no viable alternative found in variablesOrExpr"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchVariablesOrExpr:)];
}

- (void)variablesOrExpr {
    [self parseRule:@selector(__variablesOrExpr) withMemo:_variablesOrExpr_memo];
}

- (void)__varVariables {
    
    [self var]; 
    [self variables]; 

    [self fireAssemblerSelector:@selector(parser:didMatchVarVariables:)];
}

- (void)varVariables {
    [self parseRule:@selector(__varVariables) withMemo:_varVariables_memo];
}

- (void)__variables {
    
    [self variable]; 
    while ([self predicts:TOKEN_KIND_COMMA, 0]) {
        if ([self speculate:^{ [self commaVariable]; }]) {
            [self commaVariable]; 
        } else {
            break;
        }
    }

    [self fireAssemblerSelector:@selector(parser:didMatchVariables:)];
}

- (void)variables {
    [self parseRule:@selector(__variables) withMemo:_variables_memo];
}

- (void)__commaVariable {
    
    [self comma]; 
    [self variable]; 

    [self fireAssemblerSelector:@selector(parser:didMatchCommaVariable:)];
}

- (void)commaVariable {
    [self parseRule:@selector(__commaVariable) withMemo:_commaVariable_memo];
}

- (void)__variable {
    
    [self identifier]; 
    if ([self speculate:^{ [self assignment]; }]) {
        [self assignment]; 
    }

    [self fireAssemblerSelector:@selector(parser:didMatchVariable:)];
}

- (void)variable {
    [self parseRule:@selector(__variable) withMemo:_variable_memo];
}

- (void)__assignment {
    
    [self equals]; 
    [self assignmentExpr]; 

    [self fireAssemblerSelector:@selector(parser:didMatchAssignment:)];
}

- (void)assignment {
    [self parseRule:@selector(__assignment) withMemo:_assignment_memo];
}

- (void)__exprOpt {
    
    if ([self predicts:TOKEN_KIND_BUILTIN_NUMBER, TOKEN_KIND_BUILTIN_QUOTEDSTRING, TOKEN_KIND_BUILTIN_WORD, TOKEN_KIND_DELETE, TOKEN_KIND_FALSELITERAL, TOKEN_KIND_KEYWORDNEW, TOKEN_KIND_MINUS, TOKEN_KIND_MINUSMINUS, TOKEN_KIND_NULL, TOKEN_KIND_OPENPAREN, TOKEN_KIND_PLUSPLUS, TOKEN_KIND_THIS, TOKEN_KIND_TILDE, TOKEN_KIND_TRUELITERAL, TOKEN_KIND_TYPEOF, TOKEN_KIND_UNDEFINED, TOKEN_KIND_VOID, 0]) {
        [self expr]; 
    }

    [self fireAssemblerSelector:@selector(parser:didMatchExprOpt:)];
}

- (void)exprOpt {
    [self parseRule:@selector(__exprOpt) withMemo:_exprOpt_memo];
}

- (void)__expr {
    
    [self assignmentExpr]; 
    if ([self speculate:^{ [self commaExpr]; }]) {
        [self commaExpr]; 
    }

    [self fireAssemblerSelector:@selector(parser:didMatchExpr:)];
}

- (void)expr {
    [self parseRule:@selector(__expr) withMemo:_expr_memo];
}

- (void)__commaExpr {
    
    [self comma]; 
    [self expr]; 

    [self fireAssemblerSelector:@selector(parser:didMatchCommaExpr:)];
}

- (void)commaExpr {
    [self parseRule:@selector(__commaExpr) withMemo:_commaExpr_memo];
}

- (void)__assignmentExpr {
    
    [self conditionalExpr]; 
    if ([self speculate:^{ [self extraAssignment]; }]) {
        [self extraAssignment]; 
    }

    [self fireAssemblerSelector:@selector(parser:didMatchAssignmentExpr:)];
}

- (void)assignmentExpr {
    [self parseRule:@selector(__assignmentExpr) withMemo:_assignmentExpr_memo];
}

- (void)__extraAssignment {
    
    [self assignmentOperator]; 
    [self assignmentExpr]; 

    [self fireAssemblerSelector:@selector(parser:didMatchExtraAssignment:)];
}

- (void)extraAssignment {
    [self parseRule:@selector(__extraAssignment) withMemo:_extraAssignment_memo];
}

- (void)__conditionalExpr {
    
    [self orExpr]; 
    if ([self speculate:^{ [self ternaryExpr]; }]) {
        [self ternaryExpr]; 
    }

    [self fireAssemblerSelector:@selector(parser:didMatchConditionalExpr:)];
}

- (void)conditionalExpr {
    [self parseRule:@selector(__conditionalExpr) withMemo:_conditionalExpr_memo];
}

- (void)__ternaryExpr {
    
    [self question]; 
    [self assignmentExpr]; 
    [self colon]; 
    [self assignmentExpr]; 

    [self fireAssemblerSelector:@selector(parser:didMatchTernaryExpr:)];
}

- (void)ternaryExpr {
    [self parseRule:@selector(__ternaryExpr) withMemo:_ternaryExpr_memo];
}

- (void)__orExpr {
    
    [self andExpr]; 
    while ([self predicts:TOKEN_KIND_OR, 0]) {
        if ([self speculate:^{ [self orAndExpr]; }]) {
            [self orAndExpr]; 
        } else {
            break;
        }
    }

    [self fireAssemblerSelector:@selector(parser:didMatchOrExpr:)];
}

- (void)orExpr {
    [self parseRule:@selector(__orExpr) withMemo:_orExpr_memo];
}

- (void)__orAndExpr {
    
    [self or]; 
    [self andExpr]; 

    [self fireAssemblerSelector:@selector(parser:didMatchOrAndExpr:)];
}

- (void)orAndExpr {
    [self parseRule:@selector(__orAndExpr) withMemo:_orAndExpr_memo];
}

- (void)__andExpr {
    
    [self bitwiseOrExpr]; 
    if ([self speculate:^{ [self andAndExpr]; }]) {
        [self andAndExpr]; 
    }

    [self fireAssemblerSelector:@selector(parser:didMatchAndExpr:)];
}

- (void)andExpr {
    [self parseRule:@selector(__andExpr) withMemo:_andExpr_memo];
}

- (void)__andAndExpr {
    
    [self and]; 
    [self andExpr]; 

    [self fireAssemblerSelector:@selector(parser:didMatchAndAndExpr:)];
}

- (void)andAndExpr {
    [self parseRule:@selector(__andAndExpr) withMemo:_andAndExpr_memo];
}

- (void)__bitwiseOrExpr {
    
    [self bitwiseXorExpr]; 
    if ([self speculate:^{ [self pipeBitwiseOrExpr]; }]) {
        [self pipeBitwiseOrExpr]; 
    }

    [self fireAssemblerSelector:@selector(parser:didMatchBitwiseOrExpr:)];
}

- (void)bitwiseOrExpr {
    [self parseRule:@selector(__bitwiseOrExpr) withMemo:_bitwiseOrExpr_memo];
}

- (void)__pipeBitwiseOrExpr {
    
    [self pipe]; 
    [self bitwiseOrExpr]; 

    [self fireAssemblerSelector:@selector(parser:didMatchPipeBitwiseOrExpr:)];
}

- (void)pipeBitwiseOrExpr {
    [self parseRule:@selector(__pipeBitwiseOrExpr) withMemo:_pipeBitwiseOrExpr_memo];
}

- (void)__bitwiseXorExpr {
    
    [self bitwiseAndExpr]; 
    if ([self speculate:^{ [self caretBitwiseXorExpr]; }]) {
        [self caretBitwiseXorExpr]; 
    }

    [self fireAssemblerSelector:@selector(parser:didMatchBitwiseXorExpr:)];
}

- (void)bitwiseXorExpr {
    [self parseRule:@selector(__bitwiseXorExpr) withMemo:_bitwiseXorExpr_memo];
}

- (void)__caretBitwiseXorExpr {
    
    [self caret]; 
    [self bitwiseXorExpr]; 

    [self fireAssemblerSelector:@selector(parser:didMatchCaretBitwiseXorExpr:)];
}

- (void)caretBitwiseXorExpr {
    [self parseRule:@selector(__caretBitwiseXorExpr) withMemo:_caretBitwiseXorExpr_memo];
}

- (void)__bitwiseAndExpr {
    
    [self equalityExpr]; 
    if ([self speculate:^{ [self ampBitwiseAndExpression]; }]) {
        [self ampBitwiseAndExpression]; 
    }

    [self fireAssemblerSelector:@selector(parser:didMatchBitwiseAndExpr:)];
}

- (void)bitwiseAndExpr {
    [self parseRule:@selector(__bitwiseAndExpr) withMemo:_bitwiseAndExpr_memo];
}

- (void)__ampBitwiseAndExpression {
    
    [self amp]; 
    [self bitwiseAndExpr]; 

    [self fireAssemblerSelector:@selector(parser:didMatchAmpBitwiseAndExpression:)];
}

- (void)ampBitwiseAndExpression {
    [self parseRule:@selector(__ampBitwiseAndExpression) withMemo:_ampBitwiseAndExpression_memo];
}

- (void)__equalityExpr {
    
    [self relationalExpr]; 
    if ([self speculate:^{ [self equalityOpEqualityExpr]; }]) {
        [self equalityOpEqualityExpr]; 
    }

    [self fireAssemblerSelector:@selector(parser:didMatchEqualityExpr:)];
}

- (void)equalityExpr {
    [self parseRule:@selector(__equalityExpr) withMemo:_equalityExpr_memo];
}

- (void)__equalityOpEqualityExpr {
    
    [self equalityOperator]; 
    [self equalityExpr]; 

    [self fireAssemblerSelector:@selector(parser:didMatchEqualityOpEqualityExpr:)];
}

- (void)equalityOpEqualityExpr {
    [self parseRule:@selector(__equalityOpEqualityExpr) withMemo:_equalityOpEqualityExpr_memo];
}

- (void)__relationalExpr {
    
    [self shiftExpr]; 
    while ([self predicts:TOKEN_KIND_GE, TOKEN_KIND_GT, TOKEN_KIND_INSTANCEOF, TOKEN_KIND_LE, TOKEN_KIND_LT, 0]) {
        if ([self speculate:^{ [self relationalOperator]; [self shiftExpr]; }]) {
            [self relationalOperator]; 
            [self shiftExpr]; 
        } else {
            break;
        }
    }

    [self fireAssemblerSelector:@selector(parser:didMatchRelationalExpr:)];
}

- (void)relationalExpr {
    [self parseRule:@selector(__relationalExpr) withMemo:_relationalExpr_memo];
}

- (void)__shiftExpr {
    
    [self additiveExpr]; 
    if ([self speculate:^{ [self shiftOpShiftExpr]; }]) {
        [self shiftOpShiftExpr]; 
    }

    [self fireAssemblerSelector:@selector(parser:didMatchShiftExpr:)];
}

- (void)shiftExpr {
    [self parseRule:@selector(__shiftExpr) withMemo:_shiftExpr_memo];
}

- (void)__shiftOpShiftExpr {
    
    [self shiftOperator]; 
    [self shiftExpr]; 

    [self fireAssemblerSelector:@selector(parser:didMatchShiftOpShiftExpr:)];
}

- (void)shiftOpShiftExpr {
    [self parseRule:@selector(__shiftOpShiftExpr) withMemo:_shiftOpShiftExpr_memo];
}

- (void)__additiveExpr {
    
    [self multiplicativeExpr]; 
    if ([self speculate:^{ [self plusOrMinusExpr]; }]) {
        [self plusOrMinusExpr]; 
    }

    [self fireAssemblerSelector:@selector(parser:didMatchAdditiveExpr:)];
}

- (void)additiveExpr {
    [self parseRule:@selector(__additiveExpr) withMemo:_additiveExpr_memo];
}

- (void)__plusOrMinusExpr {
    
    if ([self predicts:TOKEN_KIND_PLUS, 0]) {
        [self plusExpr]; 
    } else if ([self predicts:TOKEN_KIND_MINUS, 0]) {
        [self minusExpr]; 
    } else {
        [self raise:@"no viable alternative found in plusOrMinusExpr"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchPlusOrMinusExpr:)];
}

- (void)plusOrMinusExpr {
    [self parseRule:@selector(__plusOrMinusExpr) withMemo:_plusOrMinusExpr_memo];
}

- (void)__plusExpr {
    
    [self plus]; 
    [self additiveExpr]; 

    [self fireAssemblerSelector:@selector(parser:didMatchPlusExpr:)];
}

- (void)plusExpr {
    [self parseRule:@selector(__plusExpr) withMemo:_plusExpr_memo];
}

- (void)__minusExpr {
    
    [self minus]; 
    [self additiveExpr]; 

    [self fireAssemblerSelector:@selector(parser:didMatchMinusExpr:)];
}

- (void)minusExpr {
    [self parseRule:@selector(__minusExpr) withMemo:_minusExpr_memo];
}

- (void)__multiplicativeExpr {
    
    [self unaryExpr]; 
    if ([self speculate:^{ [self multiplicativeOperator]; [self multiplicativeExpr]; }]) {
        [self multiplicativeOperator]; 
        [self multiplicativeExpr]; 
    }

    [self fireAssemblerSelector:@selector(parser:didMatchMultiplicativeExpr:)];
}

- (void)multiplicativeExpr {
    [self parseRule:@selector(__multiplicativeExpr) withMemo:_multiplicativeExpr_memo];
}

- (void)__unaryExpr {
    
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

    [self fireAssemblerSelector:@selector(parser:didMatchUnaryExpr:)];
}

- (void)unaryExpr {
    [self parseRule:@selector(__unaryExpr) withMemo:_unaryExpr_memo];
}

- (void)__unaryExpr1 {
    
    [self unaryOperator]; 
    [self unaryExpr]; 

    [self fireAssemblerSelector:@selector(parser:didMatchUnaryExpr1:)];
}

- (void)unaryExpr1 {
    [self parseRule:@selector(__unaryExpr1) withMemo:_unaryExpr1_memo];
}

- (void)__unaryExpr2 {
    
    [self minus]; 
    [self unaryExpr]; 

    [self fireAssemblerSelector:@selector(parser:didMatchUnaryExpr2:)];
}

- (void)unaryExpr2 {
    [self parseRule:@selector(__unaryExpr2) withMemo:_unaryExpr2_memo];
}

- (void)__unaryExpr3 {
    
    [self incrementOperator]; 
    [self memberExpr]; 

    [self fireAssemblerSelector:@selector(parser:didMatchUnaryExpr3:)];
}

- (void)unaryExpr3 {
    [self parseRule:@selector(__unaryExpr3) withMemo:_unaryExpr3_memo];
}

- (void)__unaryExpr4 {
    
    [self memberExpr]; 
    [self incrementOperator]; 

    [self fireAssemblerSelector:@selector(parser:didMatchUnaryExpr4:)];
}

- (void)unaryExpr4 {
    [self parseRule:@selector(__unaryExpr4) withMemo:_unaryExpr4_memo];
}

- (void)__callNewExpr {
    
    [self keywordNew]; 
    [self constructor]; 

    [self fireAssemblerSelector:@selector(parser:didMatchCallNewExpr:)];
}

- (void)callNewExpr {
    [self parseRule:@selector(__callNewExpr) withMemo:_callNewExpr_memo];
}

- (void)__unaryExpr6 {
    
    [self delete]; 
    [self memberExpr]; 

    [self fireAssemblerSelector:@selector(parser:didMatchUnaryExpr6:)];
}

- (void)unaryExpr6 {
    [self parseRule:@selector(__unaryExpr6) withMemo:_unaryExpr6_memo];
}

- (void)__constructor {
    
    if ([self speculate:^{ [self this]; [self dot]; }]) {
        [self this]; 
        [self dot]; 
    }
    [self constructorCall]; 

    [self fireAssemblerSelector:@selector(parser:didMatchConstructor:)];
}

- (void)constructor {
    [self parseRule:@selector(__constructor) withMemo:_constructor_memo];
}

- (void)__constructorCall {
    
    [self identifier]; 
    if ([self speculate:^{ if ([self predicts:TOKEN_KIND_OPENPAREN, 0]) {[self parenArgListParen]; } else if ([self predicts:TOKEN_KIND_DOT, 0]) {[self dot]; [self constructorCall]; } else {[self raise:@"no viable alternative found in constructorCall"];}}]) {
        if ([self predicts:TOKEN_KIND_OPENPAREN, 0]) {
            [self parenArgListParen]; 
        } else if ([self predicts:TOKEN_KIND_DOT, 0]) {
            [self dot]; 
            [self constructorCall]; 
        } else {
            [self raise:@"no viable alternative found in constructorCall"];
        }
    }

    [self fireAssemblerSelector:@selector(parser:didMatchConstructorCall:)];
}

- (void)constructorCall {
    [self parseRule:@selector(__constructorCall) withMemo:_constructorCall_memo];
}

- (void)__parenArgListParen {
    
    [self openParen]; 
    [self argListOpt]; 
    [self closeParen]; 

    [self fireAssemblerSelector:@selector(parser:didMatchParenArgListParen:)];
}

- (void)parenArgListParen {
    [self parseRule:@selector(__parenArgListParen) withMemo:_parenArgListParen_memo];
}

- (void)__memberExpr {
    
    [self primaryExpr]; 
    if ([self speculate:^{ [self dotBracketOrParenExpr]; }]) {
        [self dotBracketOrParenExpr]; 
    }

    [self fireAssemblerSelector:@selector(parser:didMatchMemberExpr:)];
}

- (void)memberExpr {
    [self parseRule:@selector(__memberExpr) withMemo:_memberExpr_memo];
}

- (void)__dotBracketOrParenExpr {
    
    if ([self predicts:TOKEN_KIND_DOT, 0]) {
        [self dotMemberExpr]; 
    } else if ([self predicts:TOKEN_KIND_OPENBRACKET, 0]) {
        [self bracketMemberExpr]; 
    } else if ([self predicts:TOKEN_KIND_OPENPAREN, 0]) {
        [self parenMemberExpr]; 
    } else {
        [self raise:@"no viable alternative found in dotBracketOrParenExpr"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchDotBracketOrParenExpr:)];
}

- (void)dotBracketOrParenExpr {
    [self parseRule:@selector(__dotBracketOrParenExpr) withMemo:_dotBracketOrParenExpr_memo];
}

- (void)__dotMemberExpr {
    
    [self dot]; 
    [self memberExpr]; 

    [self fireAssemblerSelector:@selector(parser:didMatchDotMemberExpr:)];
}

- (void)dotMemberExpr {
    [self parseRule:@selector(__dotMemberExpr) withMemo:_dotMemberExpr_memo];
}

- (void)__bracketMemberExpr {
    
    [self openBracket]; 
    [self expr]; 
    [self closeBracket]; 

    [self fireAssemblerSelector:@selector(parser:didMatchBracketMemberExpr:)];
}

- (void)bracketMemberExpr {
    [self parseRule:@selector(__bracketMemberExpr) withMemo:_bracketMemberExpr_memo];
}

- (void)__parenMemberExpr {
    
    [self openParen]; 
    [self argListOpt]; 
    [self closeParen]; 

    [self fireAssemblerSelector:@selector(parser:didMatchParenMemberExpr:)];
}

- (void)parenMemberExpr {
    [self parseRule:@selector(__parenMemberExpr) withMemo:_parenMemberExpr_memo];
}

- (void)__argListOpt {
    
    if ([self speculate:^{ [self argList]; }]) {
        [self argList]; 
    }

    [self fireAssemblerSelector:@selector(parser:didMatchArgListOpt:)];
}

- (void)argListOpt {
    [self parseRule:@selector(__argListOpt) withMemo:_argListOpt_memo];
}

- (void)__argList {
    
    [self assignmentExpr]; 
    while ([self predicts:TOKEN_KIND_COMMA, 0]) {
        if ([self speculate:^{ [self commaAssignmentExpr]; }]) {
            [self commaAssignmentExpr]; 
        } else {
            break;
        }
    }

    [self fireAssemblerSelector:@selector(parser:didMatchArgList:)];
}

- (void)argList {
    [self parseRule:@selector(__argList) withMemo:_argList_memo];
}

- (void)__commaAssignmentExpr {
    
    [self comma]; 
    [self assignmentExpr]; 

    [self fireAssemblerSelector:@selector(parser:didMatchCommaAssignmentExpr:)];
}

- (void)commaAssignmentExpr {
    [self parseRule:@selector(__commaAssignmentExpr) withMemo:_commaAssignmentExpr_memo];
}

- (void)__primaryExpr {
    
    if ([self predicts:TOKEN_KIND_KEYWORDNEW, 0]) {
        [self callNewExpr]; 
    } else if ([self predicts:TOKEN_KIND_OPENPAREN, 0]) {
        [self parenExprParen]; 
    } else if ([self predicts:TOKEN_KIND_BUILTIN_WORD, 0]) {
        [self identifier]; 
    } else if ([self predicts:TOKEN_KIND_BUILTIN_NUMBER, 0]) {
        [self Number]; 
    } else if ([self predicts:TOKEN_KIND_BUILTIN_QUOTEDSTRING, 0]) {
        [self QuotedString]; 
    } else if ([self predicts:TOKEN_KIND_FALSELITERAL, 0]) {
        [self falseLiteral]; 
    } else if ([self predicts:TOKEN_KIND_TRUELITERAL, 0]) {
        [self trueLiteral]; 
    } else if ([self predicts:TOKEN_KIND_NULL, 0]) {
        [self null]; 
    } else if ([self predicts:TOKEN_KIND_UNDEFINED, 0]) {
        [self undefined]; 
    } else if ([self predicts:TOKEN_KIND_THIS, 0]) {
        [self this]; 
    } else {
        [self raise:@"no viable alternative found in primaryExpr"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchPrimaryExpr:)];
}

- (void)primaryExpr {
    [self parseRule:@selector(__primaryExpr) withMemo:_primaryExpr_memo];
}

- (void)__parenExprParen {
    
    [self openParen]; 
    [self expr]; 
    [self closeParen]; 

    [self fireAssemblerSelector:@selector(parser:didMatchParenExprParen:)];
}

- (void)parenExprParen {
    [self parseRule:@selector(__parenExprParen) withMemo:_parenExprParen_memo];
}

- (void)__identifier {
    
    [self Word]; 

    [self fireAssemblerSelector:@selector(parser:didMatchIdentifier:)];
}

- (void)identifier {
    [self parseRule:@selector(__identifier) withMemo:_identifier_memo];
}

@end