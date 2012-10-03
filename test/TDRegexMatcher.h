//
//  TDRegexMatcher.h
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/2/12.
//
//

#import <ParseKit/ParseKit.h>

@interface TDRegexMatcher : NSObject {
    PKParser *parser;
}

+ (TDRegexMatcher *)matcherFromRegex:(NSString *)regex;

- (BOOL)matches:(NSString *)inputStr;
@end

@interface TDRegexMatcher (Debug)
- (PKAssembly *)bestMatchFor:(NSString *)inputStr;
@end
