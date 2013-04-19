#import <ParseKit/PKSParser.h>

enum {
    TOKEN_KIND_PROCINSTR = 14,
    TOKEN_KIND_EQ,
    TOKEN_KIND_FWDSLASH,
    TOKEN_KIND_GT,
    TOKEN_KIND_LT,
};

@interface HTMLParser : PKSParser

@end

