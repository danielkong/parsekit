#import <ParseKitStatic/PKSParser.h>
enum {
    TOKEN_KIND_GE = 14,
    TOKEN_KIND_COMMA,
    TOKEN_KIND_OR,
    TOKEN_KIND_LT,
    TOKEN_KIND_LE,
    TOKEN_KIND_EQ,
    TOKEN_KIND_DOT,
    TOKEN_KIND_GT,
    TOKEN_KIND_OPENPAREN,
    TOKEN_KIND_YES,
    TOKEN_KIND_NO,
    TOKEN_KIND_CLOSEPAREN,
    TOKEN_KIND_NE,
    TOKEN_KIND_AND,
};

@interface ExpressionParser : PKSParser

@end

