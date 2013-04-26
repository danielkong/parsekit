//
//  PKMiniCSSAssemblerTest.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 12/25/08.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import "OKMiniCSSAssemblerTest.h"

@implementation OKMiniCSSAssemblerTest

- (void)setUp {
    cssParser = [[OKMiniCSSParser alloc] init];
    cssAssembler = [[OKMiniCSSAssembler alloc] init];
}


- (void)tearDown {
    [cssParser release];
    [cssAssembler release];
}


- (void)testColor {
    TDNotNil(cssParser);
    
    s = @"bar { color:rgb(10, 200, 30); }";
    a = [cssParser parseString:s assembler:cssAssembler error:nil];
    TDEqualObjects(@"[]bar/{/color/:/rgb/(/10/,/200/,/30/)/;/}^", [a description]);
    TDNotNil(cssAssembler.attributes);
    id props = [cssAssembler.attributes objectForKey:@"bar"];
    TDNotNil(props);
    
    NSColor *color = [props objectForKey:NSForegroundColorAttributeName];
    TDNotNil(color);
    STAssertEqualsWithAccuracy([color redComponent], (CGFloat)(10.0/255.0), 0.001, @"");
    STAssertEqualsWithAccuracy([color greenComponent], (CGFloat)(200.0/255.0), 0.001, @"");
    STAssertEqualsWithAccuracy([color blueComponent], (CGFloat)(30.0/255.0), 0.001, @"");
}


- (void)testMultiSelectorColor {
    TDNotNil(cssParser);
    
    s = @"foo, bar { color:rgb(10, 200, 30); }";
    a = [cssParser parseString:s assembler:cssAssembler error:nil];
    TDEqualObjects(@"[]foo/,/bar/{/color/:/rgb/(/10/,/200/,/30/)/;/}^", [a description]);
    TDNotNil(cssAssembler.attributes);

    id props = [cssAssembler.attributes objectForKey:@"bar"];
    TDNotNil(props);
    
    NSColor *color = [props objectForKey:NSForegroundColorAttributeName];
    TDNotNil(color);
    STAssertEqualsWithAccuracy([color redComponent], (CGFloat)(10.0/255.0), 0.001, @"");
    STAssertEqualsWithAccuracy([color greenComponent], (CGFloat)(200.0/255.0), 0.001, @"");
    STAssertEqualsWithAccuracy([color blueComponent], (CGFloat)(30.0/255.0), 0.001, @"");

    props = [cssAssembler.attributes objectForKey:@"foo"];
    TDNotNil(props);
    
    color = [props objectForKey:NSForegroundColorAttributeName];
    TDNotNil(color);
    STAssertEqualsWithAccuracy([color redComponent], (CGFloat)(10.0/255.0), 0.001, @"");
    STAssertEqualsWithAccuracy([color greenComponent], (CGFloat)(200.0/255.0), 0.001, @"");
    STAssertEqualsWithAccuracy([color blueComponent], (CGFloat)(30.0/255.0), 0.001, @"");
}


- (void)testBackgroundColor {
    TDNotNil(cssParser);
    
    s = @"foo { background-color:rgb(255.0, 0.0, 255.0) }";
    a = [cssParser parseString:s assembler:cssAssembler error:nil];
    TDEqualObjects(@"[]foo/{/background-color/:/rgb/(/255.0/,/0.0/,/255.0/)/}^", [a description]);
    TDNotNil(cssAssembler.attributes);
    
    id props = [cssAssembler.attributes objectForKey:@"foo"];
    TDNotNil(props);
    
    NSColor *color = [props objectForKey:NSBackgroundColorAttributeName];
    TDNotNil(color);
    STAssertEqualsWithAccuracy([color redComponent], (CGFloat)(255.0/255.0), 0.001, @"");
    STAssertEqualsWithAccuracy([color greenComponent], (CGFloat)(0.0/255.0), 0.001, @"");
    STAssertEqualsWithAccuracy([color blueComponent], (CGFloat)(255.0/255.0), 0.001, @"");
}


- (void)testFontSize {
    TDNotNil(cssParser);
    
    s = @"decl { font-size:12px }";
    a = [cssParser parseString:s assembler:cssAssembler error:nil];
    TDEqualObjects(@"[]decl/{/font-size/:/12/px/}^", [a description]);
    TDNotNil(cssAssembler.attributes);
    
    id props = [cssAssembler.attributes objectForKey:@"decl"];
    TDNotNil(props);
    
    NSFont *font = [props objectForKey:NSFontAttributeName];
    TDNotNil(font);
    TDEquals((CGFloat)[font pointSize], (CGFloat)12.0);
    TDEqualObjects([font familyName], @"Monaco");
}


- (void)testSmallFontSize {
    TDNotNil(cssParser);
    
    s = @"decl { font-size:8px }";
    a = [cssParser parseString:s assembler:cssAssembler error:nil];
    TDEqualObjects(@"[]decl/{/font-size/:/8/px/}^", [a description]);
    TDNotNil(cssAssembler.attributes);
    
    id props = [cssAssembler.attributes objectForKey:@"decl"];
    TDNotNil(props);
    
    NSFont *font = [props objectForKey:NSFontAttributeName];
    TDNotNil(font);
    TDEquals((CGFloat)[font pointSize], (CGFloat)9.0);
    TDEqualObjects([font familyName], @"Monaco");
}


- (void)testFont {
    TDNotNil(cssParser);
    
    s = @"expr { font-size:16px; font-family:'Helvetica' }";
    a = [cssParser parseString:s assembler:cssAssembler error:nil];
    TDEqualObjects(@"[]expr/{/font-size/:/16/px/;/font-family/:/'Helvetica'/}^", [a description]);
    TDNotNil(cssAssembler.attributes);
    
    id props = [cssAssembler.attributes objectForKey:@"expr"];
    TDNotNil(props);
        
    NSFont *font = [props objectForKey:NSFontAttributeName];
    TDNotNil(font);
    TDEqualObjects([font familyName], @"Helvetica");
    TDEquals((CGFloat)[font pointSize], (CGFloat)16.0);
}


- (void)testAll {
    TDNotNil(cssParser);
    
    s = @"expr { font-size:9.0px; font-family:'Courier'; background-color:rgb(255.0, 0.0, 255.0) ;  color:rgb(10, 200, 30);}";
    a = [cssParser parseString:s assembler:cssAssembler error:nil];
    TDEqualObjects(@"[]expr/{/font-size/:/9.0/px/;/font-family/:/'Courier'/;/background-color/:/rgb/(/255.0/,/0.0/,/255.0/)/;/color/:/rgb/(/10/,/200/,/30/)/;/}^", [a description]);
    TDNotNil(cssAssembler.attributes);
    
    id props = [cssAssembler.attributes objectForKey:@"expr"];
    TDNotNil(props);
    
    NSFont *font = [props objectForKey:NSFontAttributeName];
    TDNotNil(font);
    TDEqualObjects([font familyName], @"Courier");
    TDEquals((CGFloat)[font pointSize], (CGFloat)9.0);

    NSColor *bgColor = [props objectForKey:NSBackgroundColorAttributeName];
    TDNotNil(bgColor);
    STAssertEqualsWithAccuracy([bgColor redComponent], (CGFloat)(255.0/255.0), 0.001, @"");
    STAssertEqualsWithAccuracy([bgColor greenComponent], (CGFloat)(0.0/255.0), 0.001, @"");
    STAssertEqualsWithAccuracy([bgColor blueComponent], (CGFloat)(255.0/255.0), 0.001, @"");

    NSColor *color = [props objectForKey:NSForegroundColorAttributeName];
    TDNotNil(color);
    STAssertEqualsWithAccuracy([color redComponent], (CGFloat)(10.0/255.0), 0.001, @"");
    STAssertEqualsWithAccuracy([color greenComponent], (CGFloat)(200.0/255.0), 0.001, @"");
    STAssertEqualsWithAccuracy([color blueComponent], (CGFloat)(30.0/255.0), 0.001, @"");
}


- (void)testMultiAll {
    TDNotNil(cssParser);
    
    s = @"expr, decl { font-size:9.0px; font-family:'Courier'; background-color:rgb(255.0, 0.0, 255.0) ;  color:rgb(10, 200, 30);}";
    a = [cssParser parseString:s assembler:cssAssembler error:nil];
    TDEqualObjects(@"[]expr/,/decl/{/font-size/:/9.0/px/;/font-family/:/'Courier'/;/background-color/:/rgb/(/255.0/,/0.0/,/255.0/)/;/color/:/rgb/(/10/,/200/,/30/)/;/}^", [a description]);
    TDNotNil(cssAssembler.attributes);
    
    id props = [cssAssembler.attributes objectForKey:@"expr"];
    TDNotNil(props);
    
    NSFont *font = [props objectForKey:NSFontAttributeName];
    TDNotNil(font);
    TDEqualObjects([font familyName], @"Courier");
    TDEquals((CGFloat)[font pointSize], (CGFloat)9.0);
    
    NSColor *bgColor = [props objectForKey:NSBackgroundColorAttributeName];
    TDNotNil(bgColor);
    STAssertEqualsWithAccuracy([bgColor redComponent], (CGFloat)(255.0/255.0), 0.001, @"");
    STAssertEqualsWithAccuracy([bgColor greenComponent], (CGFloat)(0.0/255.0), 0.001, @"");
    STAssertEqualsWithAccuracy([bgColor blueComponent], (CGFloat)(255.0/255.0), 0.001, @"");
    
    NSColor *color = [props objectForKey:NSForegroundColorAttributeName];
    TDNotNil(color);
    STAssertEqualsWithAccuracy([color redComponent], (CGFloat)(10.0/255.0), 0.001, @"");
    STAssertEqualsWithAccuracy([color greenComponent], (CGFloat)(200.0/255.0), 0.001, @"");
    STAssertEqualsWithAccuracy([color blueComponent], (CGFloat)(30.0/255.0), 0.001, @"");

    props = [cssAssembler.attributes objectForKey:@"decl"];
    TDNotNil(props);
    
    font = [props objectForKey:NSFontAttributeName];
    TDNotNil(font);
    TDEqualObjects([font familyName], @"Courier");
    TDEquals((CGFloat)[font pointSize], (CGFloat)9.0);
    
    bgColor = [props objectForKey:NSBackgroundColorAttributeName];
    TDNotNil(bgColor);
    STAssertEqualsWithAccuracy([bgColor redComponent], (CGFloat)(255.0/255.0), 0.001, @"");
    STAssertEqualsWithAccuracy([bgColor greenComponent], (CGFloat)(0.0/255.0), 0.001, @"");
    STAssertEqualsWithAccuracy([bgColor blueComponent], (CGFloat)(255.0/255.0), 0.001, @"");
    
    color = [props objectForKey:NSForegroundColorAttributeName];
    TDNotNil(color);
    STAssertEqualsWithAccuracy([color redComponent], (CGFloat)(10.0/255.0), 0.001, @"");
    STAssertEqualsWithAccuracy([color greenComponent], (CGFloat)(200.0/255.0), 0.001, @"");
    STAssertEqualsWithAccuracy([color blueComponent], (CGFloat)(30.0/255.0), 0.001, @"");
}

@end
