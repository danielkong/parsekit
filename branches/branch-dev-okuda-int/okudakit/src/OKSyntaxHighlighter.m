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
@property (nonatomic, retain) PKParserFactory *parserFactory;
@property (nonatomic, retain) PKSParser *miniCSSParser;
@property (nonatomic, retain) OKMiniCSSAssembler *miniCSSAssembler;
@property (nonatomic, retain) OKGenericAssembler *genericAssembler;
@property (nonatomic, retain) NSMutableDictionary *parserCache;
@property (nonatomic, retain) NSMutableDictionary *tokenizerCache;
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
    self.parserFactory = nil;
    self.miniCSSParser = nil;
    self.miniCSSAssembler = nil;
    self.genericAssembler = nil;
    self.parserCache = nil;
    self.tokenizerCache = nil;
    self.parserClassTab = nil;
    [super dealloc];
}


- (PKParserFactory *)parserFactory {
    if (!parserFactory) {
        self.parserFactory = [PKParserFactory factory];
    }
    return parserFactory;
}


- (OKMiniCSSAssembler *)miniCSSAssembler {
    if (!miniCSSAssembler) {
        self.miniCSSAssembler = [[[OKMiniCSSAssembler alloc] init] autorelease];
    }
    return miniCSSAssembler;
}


- (PKSParser *)miniCSSParser {
    if (!miniCSSParser) {
        // create mini-css parser
//        NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"OKMini_css" ofType:@"grammar"];
//        NSString *grammarString = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
//        self.miniCSSParser = [self.parserFactory parserFromGrammar:grammarString assembler:self.miniCSSAssembler error:nil];
        self.miniCSSParser = [[[OKMiniCSSParser alloc] init] autorelease];
        
    }
    return miniCSSParser;
}


- (OKGenericAssembler *)genericAssembler {
    if (!genericAssembler) {
        self.genericAssembler = [[[OKGenericAssembler alloc] init] autorelease];
    }
    return genericAssembler;
}


- (NSMutableDictionary *)parserCache {
    if (!parserCache) {
        self.parserCache = [NSMutableDictionary dictionary];
    }
    return parserCache;
}


- (NSMutableDictionary *)attributesForGrammarNamed:(NSString *)grammarName {
    // parse CSS
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:grammarName ofType:@"css"];
    NSString *s = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];

//    PKAssembly *a = [PKTokenAssembly assemblyWithString:s];
//    [self.miniCSSParser bestMatchFor:a]; // produce dict of attributes from the CSS
    
    NSError *err = nil;
    id result = [self.miniCSSParser parseString:s assembler:self.miniCSSAssembler error:&err];
    if (err) NSLog(@"%@", err);
    
    NSLog(@"%@", result);

    NSMutableDictionary *attrs = self.miniCSSAssembler.attributes;
    return attrs;
}


- (PKSParser *)parserForGrammarNamed:(NSString *)grammarName {
    // create parser or the grammar requested or fetch parser from cache
    PKSParser *parser = nil;
    if (cacheParsers) {
        parser = [self.parserCache objectForKey:grammarName];
    }
    
    if (!parser) {
        Class cls = self.parserClassTab[[grammarName lowercaseString]];
        parser = [[[cls alloc] init] autorelease];
        parser.silentlyConsumesWhitespace = YES;
        
        if (cacheParsers) {
            [self.parserCache setObject:parser forKey:grammarName];
            [self.tokenizerCache setObject:parser.tokenizer forKey:grammarName];
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

@synthesize parserFactory;
@synthesize miniCSSParser;
@synthesize miniCSSAssembler;
@synthesize genericAssembler;
@synthesize cacheParsers;
@synthesize parserCache;
@synthesize tokenizerCache;
@synthesize parserClassTab;
@end
