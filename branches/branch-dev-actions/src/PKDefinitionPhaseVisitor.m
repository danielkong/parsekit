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
    self.defaultDefNameTab = nil;
    [super dealloc];
}


- (void)visitRoot:(PKRootNode *)node {
    NSParameterAssert(node);
    NSAssert(self.symbolTable, @"");
    
    if (_collectTokenKinds) {
        self.tokenKinds = [NSMutableDictionary dictionary];
        self.defaultDefNameTab = @{
            @"~": @"TILDE",
            @"`": @"BACKTICK",
            @"!": @"BANG",
            @"@": @"AT",
            @"#": @"POUND",
            @"$": @"DOLLAR",
            @"%": @"PERCENT",
            @"^": @"CARET",
            @"^=": @"XOR_EQUALS",
            @"&": @"AMPERSAND",
            @"&=": @"AND_EQUALS",
            @"&&": @"DOUBLE_AMPERSAND",
            @"*": @"STAR",
            @"*=": @"TIMES_EQUALS",
            @"(": @"OPEN_PAREN",
            @")": @"CLOSE_PAREN",
            @"-": @"MINUS",
            @"--": @"MINUS_MINUS",
            @"-=": @"MINUS_EQUALS",
            @"_": @"UNDERSCORE",
            @"+": @"PLUS",
            @"++": @"PLUS_PLUS",
            @"+=": @"PLUS_EQUALS",
            @"=": @"EQUALS",
            @"==": @"DOUBLE_EQUALS",
            @"===": @"TRIPLE_EQUALS",
            @":=": @"ASSIGN",
            @"{": @"OPEN_CURLY",
            @"}": @"CLOSE_CURLY",
            @"[": @"OPEN_BRACKET",
            @"]": @"CLOSE_BRACKET",
            @"|": @"PIPE",
            @"|=": @"OR_EQUALS",
            @"||": @"DOUBLE_PIPE",
            @"\\": @"BACK_SLASH",
            @"\\=": @"DIV_EQUALS",
            @"/": @"FORWARD_SLASH",
            @"//": @"DOUBLE_SLASH",
            @":": @"COLON",
            @"::": @"DOUBLE_COLON",
            @";": @"SEMI_COLON",
            @"\"": @"QUOTE",
            @"'": @"APOSTROPHE",
            @"<": @"LT",
            @">": @"GT",
            @"<=": @"LE",
            @">=": @"GE",
            @"=>": @"HASH_ROCKET",
            @"->": @"RIGHT_ARROW",
            @"<-": @"LEFT_ARROW",
            @"!=": @"NE",
            @",": @"COMMA",
            @".": @"DOT",
            @"?": @"QUESTION",
            @"true": @"TRUE_LOWER",
            @"false": @"FALSE_LOWER",
            @"TRUE": @"TRUE_UPPER",
            @"FALSE": @"FALSE_UPPER",
            @"yes": @"YES_LOWER",
            @"no": @"NO_LOWER",
            @"YES": @"YES_UPPER",
            @"NO": @"NO_UPPER",
            @"or": @"OR_LOWER",
            @"and": @"AND_LOWER",
            @"OR": @"OR_UPPER",
            @"AND": @"AND_UPPER",
            @"NULL": @"NULL_UPPER",
            @"null": @"NULL_LOWER",
            @"Nil": @"NIL_TITLE",
            @"nil": @"NIL_LOWER",
            @"id": @"ID_LOWER",
            @"undefined": @"UNDEFINED_LOWER",
            @"var": @"VAR_LOWER",
            @"function": @"FUNCTION_LOWER",
            @"instanceof": @"INSTANCEOF_LOWER",
            @"def": @"DEF_LOWER",
            @"if": @"IF_LOWER",
            @"else": @"ELSE_LOWER",
            @"elif": @"ELIF_LOWER",
            @"elseif": @"ELSEIF_LOWER",
            @"return": @"RETURN_LOWER",
            @"switch": @"SWITCH_LOWER",
            @"while": @"WHILE_LOWER",
            @"do": @"DO_LOWER",
            @"for": @"FOR_LOWER",
            @"in": @"IN_LOWER",
            @"static": @"STATIC_LOWER",
            @"extern": @"EXTERN_LOWER",
            @"auto": @"AUTO_LOWER",
            @"struct": @"STRUCT_LOWER",
            @"class": @"CLASS_LOWER",
            @"extends": @"EXTENDS_LOWER",
            @"self": @"SELF_LOWER",
            @"this": @"THIS_LOWER",
            @"void": @"VOID_LOWER",
        };
    }
    
    [self recurse:node];

    if (_collectTokenKinds) {
        node.tokenKinds = [[[_tokenKinds allValues] mutableCopy] autorelease];
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
    
    // set assembler callback
    if (_assembler || _preassembler) {
        NSString *cbname = node.callbackName;
        [self setAssemblerForParser:cp callbackName:cbname];
    }

    // define in symbol table
    self.symbolTable[name] = cp;
        
    for (PKBaseNode *child in node.children) {
        if (_collectTokenKinds) {
            child.defName = name;
        }
        [child visit:self];
    }
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
        
        NSString *strVal = [node.token.stringValue stringByTrimmingQuotes];

        NSString *name = nil;
        
        PKSTokenKindDescriptor *desc = _tokenKinds[strVal];
        if (desc) {
            name = desc.name;
        }
        if (!name) {
            NSString *defName = node.defName;
            if (!defName) {
                if (!defName) {
                    defName = _defaultDefNameTab[strVal];
                }
            }
            name = [NSString stringWithFormat:@"TOKEN_KIND_%@", [defName uppercaseString]];
        }
        
        NSAssert([name length], @"");
        PKSTokenKindDescriptor *kind = [PKSTokenKindDescriptor descriptorWithStringValue:strVal name:name];
        
        _tokenKinds[strVal] = kind;
        node.tokenKind = kind;
    }
}


- (void)visitDelimited:(PKDelimitedNode *)node {
    //NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
}


- (void)visitPattern:(PKPatternNode *)node {
    //NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
}


- (void)visitAction:(PKActionNode *)node {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
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
