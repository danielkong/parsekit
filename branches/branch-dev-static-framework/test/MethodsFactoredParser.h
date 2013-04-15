#import "PKSParser.h"
enum {
    TOKEN_KIND_INT = 14,
    TOKEN_KIND_CLOSE_CURLY,
    TOKEN_KIND_COMMA,
    TOKEN_KIND_VOID,
    TOKEN_KIND_OPEN_PAREN,
    TOKEN_KIND_OPEN_CURLY,
    TOKEN_KIND_CLOSE_PAREN,
    TOKEN_KIND_SEMI_COLON,
};

@interface MethodsFactoredParser : PKSParser

@end

