#import <ParseKit/PKSParser.h>

enum {
    GREEDYFAILURE_TOKEN_KIND_OPEN_CURLY = 14,
    GREEDYFAILURE_TOKEN_KIND_COLON,
    GREEDYFAILURE_TOKEN_KIND_CLOSE_CURLY,
};

@interface GreedyFailureParser : PKSParser

@end

