//
//  PKDefinitionPhaseVisitor.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/4/12.
//
//

#import "PKDefinitionPhaseVisitor.h"
#import <ParseKit/PKCompositeParser.h>
#import "NSString+ParseKitAdditions.h"
#import "PKSTokenKindDescriptor.h"

@interface PKDefinitionPhaseVisitor ()
@end

@implementation PKDefinitionPhaseVisitor

- (void)dealloc {
    self.assembler = nil;
    self.preassembler = nil;
    self.tokenKinds = nil;
    self.currentDefName = nil;
    [super dealloc];
}


- (void)visitRoot:(PKRootNode *)node {
    NSParameterAssert(node);
    NSAssert(self.symbolTable, @"");
    
    if (_collectTokenKinds) {
        self.tokenKinds = [NSMutableArray array];
    }
    
    [self recurse:node];

    if (_collectTokenKinds) {
        node.tokenKinds = _tokenKinds;
        self.tokenKinds = nil;
    }

    self.symbolTable = nil;
}


- (void)visitDefinition:(PKDefinitionNode *)node {
    //NSLog(@"%s %@", __PRETTY_FUNCTION__, node);

    // find only child node (which represents this parser's type)
    NSAssert(1 == [node.children count], @"");
    PKBaseNode *child = node.children[0];
    
    // create parser
    Class parserCls = [child parserClass];
    PKCompositeParser *cp = [[[parserCls alloc] init] autorelease];

    // set name
    NSString *name = node.token.stringValue;
    cp.name = name;
    if (_collectTokenKinds) {
        self.currentDefName = name;
    }
    
    // set assembler callback
    if (_assembler || _preassembler) {
        NSString *cbname = node.callbackName;
        [self setAssemblerForParser:cp callbackName:cbname];
    }

    // define in symbol table
    self.symbolTable[name] = cp;
        
    [self recurse:node];
}


- (void)visitReference:(PKReferenceNode *)node {
    //NSLog(@"%s %@", __PRETTY_FUNCTION__, node);

}


- (void)visitComposite:(PKCompositeNode *)node {
    //NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
    [self recurse:node];
}


- (void)visitCollection:(PKCollectionNode *)node {
    //NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
    [self recurse:node];
}


- (void)visitAlternation:(PKAlternationNode *)node {
    //NSLog(@"%s %@", __PRETTY_FUNCTION__, node);

    NSAssert(2 == [node.children count], @"");
    
    BOOL simplify = NO;
    
    do {
        PKBaseNode *lhs = node.children[0];
        simplify = PKNodeTypeAlternation == lhs.type;
        
        // nested Alts should always be on the lhs. never on rhs.
        NSAssert(PKNodeTypeAlternation != [(PKBaseNode *)node.children[1] type], @"");
        
        if (simplify) {
            [node replaceChild:lhs withChildren:lhs.children];
        }
    } while (simplify);

    [self recurse:node];
}


- (void)visitOptional:(PKOptionalNode *)node {
    //NSLog(@"%s %@", __PRETTY_FUNCTION__, node);

    [self recurse:node];
}


- (void)visitMultiple:(PKMultipleNode *)node {
    //NSLog(@"%s %@", __PRETTY_FUNCTION__, node);

    [self recurse:node];
}


- (void)visitConstant:(PKConstantNode *)node {
    //NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
}


- (void)visitLiteral:(PKLiteralNode *)node {
    //NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
 
    if (_collectTokenKinds) {
        NSAssert(_tokenKinds, @"");
        //NSAssert(!_collectTokenKinds || _currentDefName, @"");
        
        NSString *s = [node.token.stringValue stringByTrimmingQuotes];
        NSString *name = [NSString stringWithFormat:@"TOKEN_KIND_%@", [_currentDefName uppercaseString]];
        PKSTokenKindDescriptor *kind = [PKSTokenKindDescriptor descriptorWithStringValue:s name:name];
        
        [_tokenKinds addObject:kind];
        node.tokenKind = kind;

        self.currentDefName = nil;
    }
}


- (void)visitDelimited:(PKDelimitedNode *)node {
    //NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
}


- (void)visitPattern:(PKPatternNode *)node {
    //NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
}


- (void)visitAction:(PKActionNode *)node {
    //NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
}


#pragma mark -
#pragma mark Assemblers

- (void)setAssemblerForParser:(PKCompositeParser *)p callbackName:(NSString *)callbackName {
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
    return [NSString stringWithFormat:@"%@%C%@:", prefix, (unichar)toupper([parserName characterAtIndex:0]), [parserName substringFromIndex:1]];
}

@end
