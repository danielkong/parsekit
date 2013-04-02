//
//  TDNSPredicateParserTest.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 3/27/13.
//
//

#import "TDNSPredicateParserTest.h"
#import "PKParserFactory.h"
#import "PKSParserGenVisitor.h"
#import "PKRootNode.h"
#import "TDNSPredicateParser.h"

#import "NSString+ParseKitAdditions.h"
#import "NSArray+ParseKitAdditions.h"

@interface TDNSPredicateParserTest ()
@property (nonatomic, retain) PKParserFactory *factory;
@property (nonatomic, retain) PKRootNode *root;
@property (nonatomic, retain) PKSParserGenVisitor *visitor;
@property (nonatomic, retain) TDNSPredicateParser *parser;
@property (nonatomic, retain) PKAssembly *res;
@property (nonatomic, retain) NSMutableDictionary *tab;
@property (nonatomic, retain) PKToken *openCurly;
@end

@implementation TDNSPredicateParserTest

- (id)resolvedValueForKeyPath:(NSString *)kp {
    id result = [_tab objectForKey:kp];
    if (!result) {
        result = [NSNumber numberWithBool:NO];
    }
    return result;
}


- (void)setUp {
    self.tab = [NSMutableDictionary dictionary];
    self.openCurly = [PKToken tokenWithTokenType:PKTokenTypeSymbol stringValue:@"{" floatValue:0];

    self.factory = [PKParserFactory factory];
    _factory.collectTokenKinds = YES;

    NSError *err = nil;
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"nspredicate2" ofType:@"grammar"];
    NSString *g = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&err];
    
    err = nil;
    self.root = (id)[_factory ASTFromGrammar:g error:&err];
    _root.grammarName = @"TDNSPredicate";
    
    self.visitor = [[[PKSParserGenVisitor alloc] init] autorelease];
    [_root visit:_visitor];
    
    self.parser = [[[TDNSPredicateParser alloc] init] autorelease];

#if TD_EMIT
    path = [@"~/work/parsekit/trunk/test/TDNSPredicateParser.h" stringByExpandingTildeInPath];
    err = nil;
    if (![_visitor.interfaceOutputString writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&err]) {
        NSLog(@"%@", err);
    }

    path = [@"~/work/parsekit/trunk/test/TDNSPredicateParser.m" stringByExpandingTildeInPath];
    err = nil;
    if (![_visitor.implementationOutputString writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&err]) {
        NSLog(@"%@", err);
    }
#endif
}


- (void)tearDown {
    self.factory = nil;
}


//- (void)testYes {
//    NSError *err = nil;
//    PKAssembly *res = [_parser parseString:@"yes" assembler:nil error:&err];
//    NSLog(@"%@", err);
//    TDEqualObjects(@"[1]yes^", [res description]);
//}


- (void)testNegatedPredicate {
    NSError *err = nil;
    _res = [_parser parseString:@"NOT 0 < 2" assembler:self error:&err];
    TDEqualObjects(@"[0]NOT/0/</2^", [_res description]);
    
    _res = [_parser parseString:@"! 0 < 2" assembler:self error:&err];
    TDEqualObjects(@"[0]!/0/</2^", [_res description]);
}


- (void)parser:(PKParser *)p didMatchNegatedPredicate:(PKAssembly *)a {
    BOOL b = [[a pop] boolValue];
    [a push:[NSNumber numberWithBool:!b]];
}


- (void)parser:(PKParser *)p didMatchNumComparisonPredicate:(PKAssembly *)a {
    PKFloat n2 = [(PKToken *)[a pop] floatValue];
    NSString *op = [[a pop] stringValue];
    PKFloat n1 = [(PKToken *)[a pop] floatValue];
    
    BOOL result = NO;
    if ([op isEqualToString:@"<"]) {
        result = n1 < n2;
    } else if ([op isEqualToString:@">"]) {
        result = n1 > n2;
    } else if ([op isEqualToString:@"="] || [op isEqualToString:@"=="]) {
        result = n1 == n2;
    } else if ([op isEqualToString:@"<="] || [op isEqualToString:@"=<"]) {
        result = n1 <= n2;
    } else if ([op isEqualToString:@">="] || [op isEqualToString:@"=>"]) {
        result = n1 >= n2;
    } else if ([op isEqualToString:@"!="] || [op isEqualToString:@"<>"]) {
        result = n1 != n2;
    }
    
    [a push:[NSNumber numberWithBool:result]];
}


- (void)parser:(PKParser *)p didMatchCollectionLtPredicate:(PKAssembly *)a {
    [self parser:p didMatchCollectionPredicateAssembly:a ordered:NSOrderedAscending];
}


- (void)parser:(PKParser *)p didMatchCollectionGtPredicate:(PKAssembly *)a {
    [self parser:p didMatchCollectionPredicateAssembly:a ordered:NSOrderedDescending];
}


- (void)parser:(PKParser *)p didMatchCollectionEqPredicate:(PKAssembly *)a {
    [self parser:p didMatchCollectionPredicateAssembly:a ordered:NSOrderedSame];
}


- (void)parser:(PKParser *)p didMatchCollectionPredicateAssembly:(PKAssembly *)a ordered:(NSComparisonResult)ordered {
    id value = [a pop];
    [a pop]; // discard op
    NSArray *array = [a pop];
    NSString *aggOp = [[a pop] stringValue];
    
    BOOL isAny = NSOrderedSame == [aggOp caseInsensitiveCompare:@"ANY"];
    BOOL isSome = NSOrderedSame == [aggOp caseInsensitiveCompare:@"SOME"];
    BOOL isNone = NSOrderedSame == [aggOp caseInsensitiveCompare:@"NONE"];
    BOOL isAll = NSOrderedSame == [aggOp caseInsensitiveCompare:@"ALL"];
    
    BOOL result = NO;
    if (isAny || isSome || isNone) {
        for (id obj in array) {
            if (ordered == [obj compare:value]) {
                result = YES;
                break;
            }
        }
    } else if (isAll) {
        NSInteger c = 0;
        for (id obj in array) {
            if (ordered != [obj compare:value]) {
                break;
            }
            c++;
        }
        result = c == [array count];
    }
    
    if (isNone) {
        result = !result;
    }
    
    [a push:[NSNumber numberWithBool:result]];
}


- (void)parser:(PKParser *)p didMatchString:(PKAssembly *)a {
    NSString *s = [[[a pop] stringValue] stringByTrimmingQuotes];
    [a push:s];
}


- (void)parser:(PKParser *)p didMatchStringTestPredicate:(PKAssembly *)a {
    NSString *s2 = [a pop];
    NSString *op = [[a pop] stringValue];
    NSString *s1 = [a pop];
    
    BOOL result = NO;
    if (NSOrderedSame == [op caseInsensitiveCompare:@"BEGINSWITH"]) {
        result = [s1 hasPrefix:s2];
    } else if (NSOrderedSame == [op caseInsensitiveCompare:@"CONTAINS"]) {
        result = (NSNotFound != [s1 rangeOfString:s2].location);
    } else if (NSOrderedSame == [op caseInsensitiveCompare:@"ENDSWITH"]) {
        result = [s1 hasSuffix:s2];
    } else if (NSOrderedSame == [op caseInsensitiveCompare:@"LIKE"]) {
        result = NSOrderedSame == [s1 caseInsensitiveCompare:s2]; // TODO
    } else if (NSOrderedSame == [op caseInsensitiveCompare:@"MATCHES"]) {
        result = NSOrderedSame == [s1 caseInsensitiveCompare:s2]; // TODO
    }
    
    [a push:[NSNumber numberWithBool:result]];
}


- (void)parser:(PKParser *)p didMatchAndAndTerm:(PKAssembly *)a {
    BOOL b2 = [[a pop] boolValue];
    BOOL b1 = [[a pop] boolValue];
    [a push:[NSNumber numberWithBool:b1 && b2]];
}


- (void)parser:(PKParser *)p didMatchOrOrTerm:(PKAssembly *)a {
    BOOL b2 = [[a pop] boolValue];
    BOOL b1 = [[a pop] boolValue];
    [a push:[NSNumber numberWithBool:b1 || b2]];
}


- (void)parser:(PKParser *)p didMatchArray:(PKAssembly *)a {
    NSArray *objs = [a objectsAbove:_openCurly];
    [a pop]; // discard '{'
    [a push:[objs reversedArray]];
}


- (void)parser:(PKParser *)p didMatchCollectionTestPredicate:(PKAssembly *)a {
    NSArray *array = [a pop];
    NSAssert([array isKindOfClass:[NSArray class]], @"");
    id value = [a pop];
    [a push:[NSNumber numberWithBool:[array containsObject:value]]];
}


- (void)parser:(PKParser *)p didMatchKeyPath:(PKAssembly *)a {
    NSString *keyPath = [[a pop] stringValue];
    [a push:[self resolvedValueForKeyPath:keyPath]];
}


- (void)parser:(PKParser *)p didMatchNum:(PKAssembly *)a {
    [a push:[NSNumber numberWithFloat:[(PKToken *)[a pop] floatValue]]];
}


- (void)parser:(PKParser *)p didMatchTrue:(PKAssembly *)a {
    [a push:[NSNumber numberWithBool:YES]];
}


- (void)parser:(PKParser *)p didMatchFalse:(PKAssembly *)a {
    [a push:[NSNumber numberWithBool:NO]];
}


- (void)parser:(PKParser *)p didMatchTruePredicate:(PKAssembly *)a {
    [a push:[NSNumber numberWithBool:YES]];
}


- (void)parser:(PKParser *)p didMatchFalsePredicate:(PKAssembly *)a {
    [a push:[NSNumber numberWithBool:NO]];
}


@end
