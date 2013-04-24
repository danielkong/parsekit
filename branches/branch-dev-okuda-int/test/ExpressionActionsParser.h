#import <ParseKit/PKSParser.h>

enum {
    EXPRESSIONACTIONS_TOKEN_KIND_NO = 14,
    EXPRESSIONACTIONS_TOKEN_KIND_NO_UPPER,
    EXPRESSIONACTIONS_TOKEN_KIND_GE,
    EXPRESSIONACTIONS_TOKEN_KIND_COMMA,
    EXPRESSIONACTIONS_TOKEN_KIND_OR,
    EXPRESSIONACTIONS_TOKEN_KIND_LT,
    EXPRESSIONACTIONS_TOKEN_KIND_LE,
    EXPRESSIONACTIONS_TOKEN_KIND_EQUALS,
    EXPRESSIONACTIONS_TOKEN_KIND_DOT,
    EXPRESSIONACTIONS_TOKEN_KIND_GT,
    EXPRESSIONACTIONS_TOKEN_KIND_AND,
    EXPRESSIONACTIONS_TOKEN_KIND_OPEN_PAREN,
    EXPRESSIONACTIONS_TOKEN_KIND_YES,
    EXPRESSIONACTIONS_TOKEN_KIND_CLOSE_PAREN,
    EXPRESSIONACTIONS_TOKEN_KIND_NE,
    EXPRESSIONACTIONS_TOKEN_KIND_YES_UPPER,
};

@interface ExpressionActionsParser : PKSParser

@end

