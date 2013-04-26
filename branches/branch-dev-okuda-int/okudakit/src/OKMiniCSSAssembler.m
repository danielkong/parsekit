//
//  PKMiniCSSAssembler.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 12/23/08.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import "OKMiniCSSAssembler.h"
#import "NSString+ParseKitAdditions.h"
#import <ParseKit/ParseKit.h>

@interface OKMiniCSSAssembler ()
- (void)gatherPropertiesIn:(id)props;
@end

@implementation OKMiniCSSAssembler

- (id)init {
    if (self = [super init]) {
        self.attributes = [NSMutableDictionary dictionary];
        self.paren = [PKToken tokenWithTokenType:PKTokenTypeSymbol stringValue:@"(" floatValue:0.0];
        self.curly = [PKToken tokenWithTokenType:PKTokenTypeSymbol stringValue:@"{" floatValue:0.0];
    }
    return self;
}


- (void)dealloc {
    self.attributes = nil;
    self.paren = nil;
    self.curly = nil;
    [super dealloc];
}


#pragma mark -
#pragma mark Assembler Callbacks

//    @start        = ruleset*;
//    ruleset       = selectors '{' decls '}'!;
//    selectors     = selector commaSelector*;
//    selector      = Word;
//    commaSelector = ','! selector;
//    decls         = Empty | actualDecls;
//    actualDecls   = decl decl*;
//    decl          = property ':'! expr ';'!?;
//    property      = color | backgroundColor | fontFamily | fontSize;
//    expr          = pixelValue | rgb | string | constants;
//    pixelValue    = num px;
//    rgb           = rgb '(' Number ','! Number ','! Number ')'!;
//    constants     = bold | normal | italic;
//
//    num 		  = Number;
//    string        = QuotedString;
//
//    px = 'px'!;
//    rgb = 'rgb'!;
//    color = 'color';
//    backgroundColor = 'background-color';
//    fontFamily = 'font-family';
//    fontSize = 'font-size';
//    bold = 'bold';
//    normal = 'normal';
//    italic = 'italic';

- (void)parser:(PKSParser *)p didMatchProperty:(PKAssembly *)a {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, a);
    PKToken *tok = [a pop];
    [a push:tok.stringValue];
}


- (void)parser:(PKSParser *)p didMatchString:(PKAssembly *)a {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, a);
    PKToken *tok = [a pop];
    [a push:[tok.stringValue stringByTrimmingQuotes]];
}


- (void)parser:(PKSParser *)p didMatchConstant:(PKAssembly *)a {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, a);
    PKToken *tok = [a pop];
    [a push:tok.stringValue];
}


- (void)parser:(PKSParser *)p didMatchNum:(PKAssembly *)a {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, a);
    PKToken *tok = [a pop];
    [a push:[NSNumber numberWithFloat:tok.floatValue]];
}


- (void)parser:(PKSParser *)p didMatchPixelValue:(PKAssembly *)a {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, a);
    PKToken *tok = [a pop];
    [a push:[NSNumber numberWithFloat:tok.floatValue]];
}


- (void)parser:(PKSParser *)p didMatchRgbValue:(PKAssembly *)a {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, a);
    NSArray *objs = [a objectsAbove:paren];
    [a pop]; // discard '('
    CGFloat blue  = [(PKToken *)[objs objectAtIndex:0] floatValue]/255.0;
    CGFloat green = [(PKToken *)[objs objectAtIndex:1] floatValue]/255.0;
    CGFloat red   = [(PKToken *)[objs objectAtIndex:2] floatValue]/255.0;
    [a push:[NSColor colorWithDeviceRed:red green:green blue:blue alpha:1.0]];
}


- (void)parser:(PKSParser *)p didMatchActualDecls:(PKAssembly *)a {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, a);
    id d = [NSMutableDictionary dictionary];
    NSArray *objs = [a objectsAbove:curly];
    [a pop]; // discard curly

    NSInteger i = 0;
    NSInteger count = objs.count;
    for ( ; i < count - 1; i++) {
        id propVal = [objs objectAtIndex:i];
        id propName = [objs objectAtIndex:++i];
        [d setObject:propVal forKey:propName];
    }
    
    [a push:d];
}


- (void)parser:(PKSParser *)p didMatchRuleset:(PKAssembly *)a {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, a);
    id props = [a pop];
    [self gatherPropertiesIn:props];

    for (PKToken *selectorTok in [a objectsAbove:nil]) {
        NSString *selector = selectorTok.stringValue;
        [attributes setObject:props forKey:selector];
    }
}


- (void)gatherPropertiesIn:(id)props {
    NSColor *color = [props objectForKey:@"color"];
    if (!color) {
        color = [NSColor blackColor];
    }
    [props setObject:color forKey:NSForegroundColorAttributeName];
    [props removeObjectForKey:@"color"];

    color = [props objectForKey:@"background-color"];
    if (!color) {
        color = [NSColor whiteColor];
    }
    [props setObject:color forKey:NSBackgroundColorAttributeName];
    [props removeObjectForKey:@"background-color"];
    
    NSString *fontFamily = [props objectForKey:@"font-family"];
    if (!fontFamily.length) {
        fontFamily = @"Monaco";
    }
    
    CGFloat fontSize = [[props objectForKey:@"font-size"] doubleValue];
    if (fontSize < 9.0) {
        fontSize = 9.0;
    }
    
    NSFont *font = [NSFont fontWithName:fontFamily size:fontSize];
    [props setObject:font forKey:NSFontAttributeName];
    [props removeObjectForKey:@"font-family"];
    [props removeObjectForKey:@"font-size"];
}

@synthesize attributes;
@synthesize paren;
@synthesize curly;
@end
