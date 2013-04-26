#import <ParseKit/PKSParser.h>

enum {
    OKJAVASCRIPT_TOKEN_KIND_PIPE = 14,
    OKJAVASCRIPT_TOKEN_KIND_NE,
    OKJAVASCRIPT_TOKEN_KIND_OPENPAREN,
    OKJAVASCRIPT_TOKEN_KIND_CLOSECURLY,
    OKJAVASCRIPT_TOKEN_KIND_RETURNSYM,
    OKJAVASCRIPT_TOKEN_KIND_TILDE,
    OKJAVASCRIPT_TOKEN_KIND_CLOSEPAREN,
    OKJAVASCRIPT_TOKEN_KIND_TIMES,
    OKJAVASCRIPT_TOKEN_KIND_DELETE,
    OKJAVASCRIPT_TOKEN_KIND_ISNOT,
    OKJAVASCRIPT_TOKEN_KIND_PLUS,
    OKJAVASCRIPT_TOKEN_KIND_TIMESEQ,
    OKJAVASCRIPT_TOKEN_KIND_INSTANCEOF,
    OKJAVASCRIPT_TOKEN_KIND_COMMA,
    OKJAVASCRIPT_TOKEN_KIND_SHIFTLEFTEQ,
    OKJAVASCRIPT_TOKEN_KIND_IFSYM,
    OKJAVASCRIPT_TOKEN_KIND_MINUS,
    OKJAVASCRIPT_TOKEN_KIND_NULL,
    OKJAVASCRIPT_TOKEN_KIND_FALSELITERAL,
    OKJAVASCRIPT_TOKEN_KIND_DOT,
    OKJAVASCRIPT_TOKEN_KIND_SHIFTLEFT,
    OKJAVASCRIPT_TOKEN_KIND_DIV,
    OKJAVASCRIPT_TOKEN_KIND_PLUSEQ,
    OKJAVASCRIPT_TOKEN_KIND_LE,
    OKJAVASCRIPT_TOKEN_KIND_XOREQ,
    OKJAVASCRIPT_TOKEN_KIND_OPENBRACKET,
    OKJAVASCRIPT_TOKEN_KIND_UNDEFINED,
    OKJAVASCRIPT_TOKEN_KIND_TYPEOF,
    OKJAVASCRIPT_TOKEN_KIND_OR,
    OKJAVASCRIPT_TOKEN_KIND_FUNCTION,
    OKJAVASCRIPT_TOKEN_KIND_CLOSEBRACKET,
    OKJAVASCRIPT_TOKEN_KIND_CARET,
    OKJAVASCRIPT_TOKEN_KIND_EQ,
    OKJAVASCRIPT_TOKEN_KIND_CONTINUESYM,
    OKJAVASCRIPT_TOKEN_KIND_BREAKSYM,
    OKJAVASCRIPT_TOKEN_KIND_MINUSEQ,
    OKJAVASCRIPT_TOKEN_KIND_GE,
    OKJAVASCRIPT_TOKEN_KIND_COLON,
    OKJAVASCRIPT_TOKEN_KIND_INSYM,
    OKJAVASCRIPT_TOKEN_KIND_SEMI,
    OKJAVASCRIPT_TOKEN_KIND_FORSYM,
    OKJAVASCRIPT_TOKEN_KIND_PLUSPLUS,
    OKJAVASCRIPT_TOKEN_KIND_LT,
    OKJAVASCRIPT_TOKEN_KIND_MODEQ,
    OKJAVASCRIPT_TOKEN_KIND_SHIFTRIGHT,
    OKJAVASCRIPT_TOKEN_KIND_EQUALS,
    OKJAVASCRIPT_TOKEN_KIND_GT,
    OKJAVASCRIPT_TOKEN_KIND_VOID,
    OKJAVASCRIPT_TOKEN_KIND_QUESTION,
    OKJAVASCRIPT_TOKEN_KIND_WHILESYM,
    OKJAVASCRIPT_TOKEN_KIND_ANDEQ,
    OKJAVASCRIPT_TOKEN_KIND_SHIFTRIGHTEXTEQ,
    OKJAVASCRIPT_TOKEN_KIND_ELSESYM,
    OKJAVASCRIPT_TOKEN_KIND_DIVEQ,
    OKJAVASCRIPT_TOKEN_KIND_AND,
    OKJAVASCRIPT_TOKEN_KIND_VAR,
    OKJAVASCRIPT_TOKEN_KIND_OREQ,
    OKJAVASCRIPT_TOKEN_KIND_SHIFTRIGHTEQ,
    OKJAVASCRIPT_TOKEN_KIND_MINUSMINUS,
    OKJAVASCRIPT_TOKEN_KIND_KEYWORDNEW,
    OKJAVASCRIPT_TOKEN_KIND_NOT,
    OKJAVASCRIPT_TOKEN_KIND_SHIFTRIGHTEXT,
    OKJAVASCRIPT_TOKEN_KIND_TRUELITERAL,
    OKJAVASCRIPT_TOKEN_KIND_THIS,
    OKJAVASCRIPT_TOKEN_KIND_WITH,
    OKJAVASCRIPT_TOKEN_KIND_IS,
    OKJAVASCRIPT_TOKEN_KIND_MOD,
    OKJAVASCRIPT_TOKEN_KIND_AMP,
    OKJAVASCRIPT_TOKEN_KIND_OPENCURLY,
};

@interface OKJavaScriptParser : PKSParser

@end

