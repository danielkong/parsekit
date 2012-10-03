//
//  TDRegexMatcher.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/2/12.
//
//

#import "TDRegexMatcher.h"
#import "TDRegexAssembler.h"

@interface TDRegexMatcher ()
@property (nonatomic, retain) PKParser *parser;
@end

@implementation TDRegexMatcher

+ (PKParser *)regexParser {
    static PKParser *sRegexParser = nil;
    if (!sRegexParser) {
        static TDRegexAssembler *ass = nil;
        if (!ass) {
            ass = [[TDRegexAssembler alloc] init];
        }
        
        NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"regex" ofType:@"grammar"];
        NSString *g = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
        
        NSError *err = nil;
        sRegexParser = [[[PKParserFactory factory] parserFromGrammar:g assembler:ass error:&err] retain];
        if (err) {
            NSLog(@"%@", err);
        }
    }
 
    return sRegexParser;
}


+ (TDRegexMatcher *)matcherFromRegex:(NSString *)regex {
    
    PKAssembly *a = [PKCharacterAssembly assemblyWithString:regex];
    a = [[self regexParser] completeMatchFor:a];
    PKParser *p = [a pop];
    
    TDRegexMatcher *result = [[[TDRegexMatcher alloc] init] autorelease];
    result.parser = p;
    
    return result;
}


- (void)dealloc {
    self.parser = nil;
    [super dealloc];
}


- (PKAssembly *)bestMatchFor:(NSString *)inputStr {
    PKAssembly *a = [PKCharacterAssembly assemblyWithString:inputStr];
    a = [self.parser bestMatchFor:a];
    return a;
}

@synthesize parser;
@end
