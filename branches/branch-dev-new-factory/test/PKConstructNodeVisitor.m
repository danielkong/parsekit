//
//  PKNodeVisitor.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/4/12.
//
//

#import "PKConstructNodeVisitor.h"
#import "PKNodeBase.h"
#import "PKNodeDefinition.h"
#import "PKNodeReference.h"
#import "PKNodeConstant.h"
#import "PKNodeDelimited.h"
#import "PKNodeLiteral.h"
#import "PKNodePattern.h"
#import "PKNodeWhitespace.h"
#import "PKNodeComposite.h"
#import "PKNodeCollection.h"
#import "PKNodeCardinal.h"
#import "PKNodeOptional.h"
#import "PKNodeMultiple.h"
#import "NSString+ParseKitAdditions.h"
//#import "PKNodeRepetition.h"
//#import "PKNodeDifference.h"
//#import "PKNodeNegation.h"

@implementation PKConstructNodeVisitor

- (void)dealloc {
    self.rootNode = nil;
    self.parserTable = nil;
    self.productionTable = nil;
    self.rootParser = nil;
    self.currentParser = nil;
    self.assembler = nil;
    self.preassembler = nil;
    [super dealloc];
}


- (Class)collectionParserClassForToken:(PKToken *)tok {
    NSString *tokStr = tok.stringValue;
    NSAssert([tokStr length], @"");
    unichar c = [tokStr characterAtIndex:0];
    
    Class parserClass = Nil;
    
    switch (c) {
        case 'S':
            parserClass = [PKSequence class];
            break;
        case 'T':
            parserClass = [PKTrack class];
            break;
        case '&':
            parserClass = [PKIntersection class];
            break;
        case '|':
            parserClass = [PKAlternation class];
            break;
        default:
            NSAssert1(0, @"unknown collection node type '%@'", tokStr);
            break;
    }

    return parserClass;
}


- (PKCollectionParser *)collectionParserForProductionName:(NSString *)name {
    PKCollectionParser *p = _parserTable[name];

    if (!p) {
        PKNodeBase *node = _productionTable[name];
        NSAssert(node, @"");
        
        PKToken *tok = node.token;
        Class parserClass = [self collectionParserClassForToken:tok];
        
        p = [[[parserClass alloc] init] autorelease];
        p.name = name;
        
        _parserTable[name] = p;
    }
    
    return p;
}


- (void)visitDefinition:(PKNodeDefinition *)node {
    //NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    NSAssert(node.token.isSymbol, @"");
    
    NSString *name = node.parserName;
    NSAssert([name length], @"");
    
    PKCollectionParser *p = [self collectionParserForProductionName:name];
    
//    [_currentParser add:p];
    self.currentParser = p;
    
    PKCompositeParser *oldParent = _currentParser;
    
    for (PKNodeBase *child in node.children) {
        [child visit:self];
        self.currentParser = p;
    }
    
    self.currentParser = oldParent;
}


- (void)visitReference:(PKNodeReference *)node {
    //NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
    NSAssert(node.token.isSymbol, @"");
    
    NSString *name = node.parserName;
    NSAssert([name length], @"");
    
    PKCollectionParser *p = [self collectionParserForProductionName:name];
    
    [_currentParser add:p];
    
    [self setAssemblerForParser:p callbackName:node.callbackName];
}


- (void)visitConstant:(PKNodeConstant *)node {
    PKTerminal *p = nil;
    
    PKToken *tok = node.token;
    NSAssert(tok.isWord, @"");
    
    NSString *parserClassName = tok.stringValue;
    
    Class parserClass = NSClassFromString([NSString stringWithFormat:@"PK%@", parserClassName]);
    NSAssert(parserClass, @"");
    
    p = [[[parserClass alloc] init] autorelease];
    
    if (node.discard) {
        [p discard];
    }
    
    [_currentParser add:p];
}


- (void)visitLiteral:(PKNodeLiteral *)node {
    PKTerminal *p = nil;
    
    PKToken *tok = node.token;
    NSAssert(tok.isQuotedString, @"");
    
    NSString *str = [tok.stringValue stringByTrimmingQuotes];
    
    p = [PKLiteral literalWithString:str];
    
    if (node.discard) {
        [p discard];
    }
    
    [_currentParser add:p];
}


- (void)visitDelimited:(PKNodeDelimited *)node {
    NSString *startMarker = nil;
    NSString *endMarker = nil;
    PKDelimitedString *p = [PKDelimitedString delimitedStringWithStartMarker:startMarker endMarker:endMarker];
    
    if (node.discard) {
        [p discard];
    }
    
    [_currentParser add:p];
}


- (void)visitPattern:(PKNodePattern *)node {
    PKToken *tok = node.token;
    NSAssert(tok.isDelimitedString, @"");
    
    PKPatternOptions opts = node.options;
    NSString *regex = [tok.stringValue stringByTrimmingQuotes];
    PKPattern *p = [PKPattern patternWithString:regex options:opts];
    
    if (node.discard) {
        [p discard];
    }
    
    [_currentParser add:p];
}


- (void)visitWhitespace:(PKNodeWhitespace *)node {
    PKTerminal *p = [PKWhitespace whitespace];
    
    PKToken *tok = node.token;
    NSAssert(tok.isWord, @"");
    
    if (node.discard) {
        [p discard];
    }
    
    [_currentParser add:p];
}


- (void)visitComposite:(PKNodeComposite *)node {
    PKCompositeParser *p = nil;
    
    PKToken *tok = node.token;
    NSAssert(tok.isSymbol, @"");
    
    NSString *tokStr = tok.stringValue;
    NSAssert([tokStr length], @"");
    unichar c = [tokStr characterAtIndex:0];
    
    Class parserClass = Nil;
    
    switch (c) {
        case '*':
            parserClass = [PKRepetition class];
            break;
        case '~':
            parserClass = [PKNegation class];
            break;
        case '-':
            parserClass = [PKDifference class];
            break;
        default:
            NSAssert1(0, @"unknown composite node type '%@'", tokStr);
            break;
    }
    
    p = [[[parserClass alloc] init] autorelease];
    
    [_currentParser add:p];
    PKCompositeParser *oldParent = _currentParser;
    
    for (PKNodeBase *child in node.children) {
        self.currentParser = p;
        [child visit:self];
    }

    self.currentParser = oldParent;
}


- (void)visitCollection:(PKNodeCollection *)node {
    //NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    PKCollectionParser *p = nil;
    
    PKToken *tok = node.token;
    NSAssert(tok.isSymbol, @"");
    
    Class parserClass = [self collectionParserClassForToken:tok];

    NSString *name = node.parserName;    
    if (name) {
        p = _parserTable[name];
    }

    if (!p) {
        p = [[[parserClass alloc] init] autorelease];
        
        if (name) {
            p.name = name;
            _parserTable[name] = p;
        }
    }
    

    [_currentParser add:p];
    self.currentParser = p;

    PKCompositeParser *oldParent = _currentParser;

    for (PKNodeBase *child in node.children) {
        [child visit:self];
        self.currentParser = p;
    }

    self.currentParser = oldParent;
}


- (void)visitCardinal:(PKNodeCardinal *)node {
    PKCollectionParser *seq = [PKSequence sequence];
    
    NSAssert(node.token.isSymbol, @"");
    NSAssert([node.token.stringValue isEqualToString:@"{"], @"");
    
    NSInteger start = node.rangeStart;
    NSInteger end = node.rangeEnd;
    
    [_currentParser add:seq];
    self.currentParser = seq;
    
    NSAssert(1 == [node.children count], @"");
    PKNodeBase *childNode = [node.children objectAtIndex:0];
    
    for (NSInteger i = 0; i < start; i++) {
        [childNode visit:self];
    }
    
    for (NSInteger i = start; i < end; i++) {
        PKAlternation *opt = [PKAlternation alternation];
        [opt add:[PKEmpty empty]];
        self.currentParser = opt;
        [childNode visit:self];
        [seq add:opt];
    }
    
    self.currentParser = seq;
}


- (void)visitOptional:(PKNodeOptional *)node {
    PKCollectionParser *alt = [PKAlternation alternation];
    [alt add:[PKEmpty empty]];
    
    PKToken *tok = node.token;
    NSAssert(tok.isSymbol, @"");
    NSAssert([tok.stringValue isEqualToString:@"?"], @"");
    
    [_currentParser add:alt];
    self.currentParser = alt;
    
    for (PKNodeBase *child in node.children) {
        [child visit:self];
        self.currentParser = alt;
    }
}


- (void)visitMultiple:(PKNodeMultiple *)node {
    PKCollectionParser *seq = [PKSequence sequence];
    
    PKToken *tok = node.token;
    NSAssert(tok.isSymbol, @"");
    NSAssert([tok.stringValue isEqualToString:@"+"], @"");
    
    [_currentParser add:seq];
    self.currentParser = seq;
    
    NSAssert(1 == [node.children count], @"");
    for (PKNodeBase *childNode in node.children) {
        [childNode visit:self];
    }
    
    NSAssert(1 == [seq.subparsers count], @"");
    for (PKParser *childParser in seq.subparsers) {
        [seq add:[PKRepetition repetitionWithSubparser:childParser]];
        self.currentParser = seq;
    }
}


//- (void)visitRepetition:(PKNodeRepetition *)node {
//    PKRepetition *p = [[[PKRepetition alloc] init] autorelease];
//    
//    [_currentParser add:p];
//    self.currentParser = p;
//
//    for (PKNodeParser *child in node.children) {
//        [child visit:self];
//    }
//}
//
//
//- (void)visitDifference:(PKNodeDifference *)node {
//    PKDifference *p = [[[PKDifference alloc] init] autorelease];
//    
//    [_currentParser add:p];
//    self.currentParser = p;
//    
//    for (PKNodeParser *child in node.children) {
//        [child visit:self];
//    }
//}
//
//
//- (void)visitNegation:(PKNodeNegation *)node {
//    PKNegation *p = [[[PKNegation alloc] init] autorelease];
//    
//    [_currentParser add:p];
//    self.currentParser = p;
//    
//    for (PKNodeParser *child in node.children) {
//        [child visit:self];
//    }
//}

#pragma mark -
#pragma mark Assemblers

- (void)setAssemblerForParser:(PKParser *)p callbackName:(NSString *)callbackName {
    NSString *parserName = p.name;
    NSString *selName = callbackName;

    BOOL setOnAll = (_assemblerSettingBehavior & PKParserFactoryAssemblerSettingBehaviorOnAll);
    
    if (setOnAll) {
        // continue
    } else {
        BOOL setOnExplicit = (_assemblerSettingBehavior & PKParserFactoryAssemblerSettingBehaviorOnExplicit);
        if (setOnExplicit && selName) {
            // continue
        } else {
            BOOL isTerminal = [p isKindOfClass:[PKTerminal class]];
            if (!isTerminal && !setOnExplicit) return;
            
            BOOL setOnTerminals = (_assemblerSettingBehavior & PKParserFactoryAssemblerSettingBehaviorOnTerminals);
            if (setOnTerminals && isTerminal) {
                // continue
            } else {
                return;
            }
        }
    }
    
    if (!selName) {
        selName = [self defaultAssemblerSelectorNameForParserName:parserName];
    }
    
    if (selName) {
        SEL sel = NSSelectorFromString(selName);
        if (_assembler && [_assembler respondsToSelector:sel]) {
            [p setAssembler:_assembler selector:sel];
        }
        if (_preassembler && [_preassembler respondsToSelector:sel]) {
            NSString *selName = [self defaultPreassemblerSelectorNameForParserName:parserName];
            [p setPreassembler:_preassembler selector:NSSelectorFromString(selName)];
        }
    }
}


- (NSString *)defaultAssemblerSelectorNameForParserName:(NSString *)parserName {
    return [self defaultAssemblerSelectorNameForParserName:parserName pre:NO];
}


- (NSString *)defaultPreassemblerSelectorNameForParserName:(NSString *)parserName {
    return [self defaultAssemblerSelectorNameForParserName:parserName pre:YES];
}


- (NSString *)defaultAssemblerSelectorNameForParserName:(NSString *)parserName pre:(BOOL)isPre {
    NSString *prefix = nil;
    if ([parserName hasPrefix:@"@"]) {
        return nil;
    } else {
        prefix = isPre ? @"parser:willMatch" :  @"parser:didMatch";
    }
    return [NSString stringWithFormat:@"%@%@:", prefix, [parserName capitalizedString]];
}


#pragma mark -
#pragma mark Properties

- (void)setCurrentParser:(PKCompositeParser *)p {
    if (p != _currentParser) {
        [_currentParser release];
        _currentParser = [p retain];
        
        if (!_rootParser) {
            self.rootParser = _currentParser;
        }
    }
}

@end
