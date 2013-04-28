//
//  PKSyntaxHighlighter.m
//  HTTPClient
//
//  Created by Todd Ditchendorf on 12/26/08.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import "OKSyntaxHighlighter.h"
#import <ParseKit/ParseKit.h>

#import "OKMiniCSSParser.h"
#import "OKMiniCSSAssembler.h"
#import "OKGenericAssembler.h"

#import "OKCSSParser.h"
#import "OKJavaScriptParser.h"
#import "OKHTMLParser.h"
#import "OKJSONParser.h"

@interface OKSyntaxHighlighter ()
- (NSMutableDictionary *)attributesForGrammarNamed:(NSString *)grammarName;
- (PKSParser *)parserForGrammarNamed:(NSString *)grammarName;

// all of the ivars for these properties are lazy loaded in the getters.
// thats so that if an application has syntax highlighting turned off, this class will
// consume much less memory/fewer resources.
@property (nonatomic, retain) PKSParser *miniCSSParser;
@property (nonatomic, retain) OKMiniCSSAssembler *miniCSSAssembler;
@property (nonatomic, retain) OKGenericAssembler *genericAssembler;
@property (nonatomic, retain) NSMutableDictionary *parserCache;
@property (nonatomic, retain) NSDictionary *parserClassTab;
@end

@implementation OKSyntaxHighlighter

+ (id)syntaxHighlighter {
    return [[[OKSyntaxHighlighter alloc] init] autorelease];
}


- (id)init {
    self = [super init];
    if (self) {
        self.parserClassTab = @{
            @"css": [OKCSSParser class],
            @"javascript": [OKJavaScriptParser class],
            @"html": [OKHTMLParser class],
            @"json": [OKJSONParser class],
        };
    }
    return self;
}


- (void)dealloc {
    self.miniCSSParser = nil;
    self.miniCSSAssembler = nil;
    self.genericAssembler = nil;
    self.parserCache = nil;
    self.parserClassTab = nil;
    [super dealloc];
}


- (OKMiniCSSAssembler *)miniCSSAssembler {
    if (!_miniCSSAssembler) {
        self.miniCSSAssembler = [[[OKMiniCSSAssembler alloc] init] autorelease];
    }
    return _miniCSSAssembler;
}


- (PKSParser *)miniCSSParser {
    if (!_miniCSSParser) {
        // create mini-css parser
        self.miniCSSParser = [[[OKMiniCSSParser alloc] init] autorelease];
        
    }
    return _miniCSSParser;
}


- (OKGenericAssembler *)genericAssembler {
    if (!_genericAssembler) {
        self.genericAssembler = [[[OKGenericAssembler alloc] init] autorelease];
    }
    return _genericAssembler;
}


- (NSMutableDictionary *)parserCache {
    if (!_parserCache) {
        self.parserCache = [NSMutableDictionary dictionary];
    }
    return _parserCache;
}


- (NSMutableDictionary *)attributesForGrammarNamed:(NSString *)grammarName {
    // parse CSS
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:grammarName ofType:@"css"];
    NSString *s = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];

    NSError *err = nil;
    id result = [self.miniCSSParser parseString:s assembler:self.miniCSSAssembler error:&err];
    if (!result) {
        if (err) NSLog(@"%@", err);
    }
    
    //NSLog(@"%@", result);

    NSMutableDictionary *attrs = self.miniCSSAssembler.attributes;
    return attrs;
}


- (PKSParser *)parserForGrammarNamed:(NSString *)grammarName {
    // create parser or the grammar requested or fetch parser from cache
    PKSParser *parser = nil;
    if (_cacheParsers) {
        parser = [self.parserCache objectForKey:grammarName];
    }
    
    if (!parser) {
        Class cls = self.parserClassTab[[grammarName lowercaseString]];
        parser = [[[cls alloc] init] autorelease];
        parser.silentlyConsumesWhitespace = YES;
        
        if (_cacheParsers) {
            [self.parserCache setObject:parser forKey:grammarName];
        }
    }

    return parser;
}


- (NSAttributedString *)highlightedStringForString:(NSString *)s ofGrammar:(NSString *)grammarName {    
    // create or fetch the parser & tokenizer for this grammar
    PKSParser *parser = [self parserForGrammarNamed:grammarName];
    parser.enableAutomaticErrorRecovery = YES;
    
    // get attributes from css && give to the generic assembler
    self.genericAssembler.attributes = [self attributesForGrammarNamed:grammarName];

    NSError *err = nil;
    id result = [parser parseString:s assembler:self.genericAssembler error:&err];
    if (!result) {
        if (err) NSLog(@"%@", err);
    }
    
    return result;
}

@end
