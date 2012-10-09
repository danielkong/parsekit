//
//  PKParserFactory.h
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/3/12.
//
//

#import <Foundation/Foundation.h>

@class PKParser;
@class PKAST;

void PKReleaseSubparserTree(PKParser *p);

typedef enum {
    PKParserFactoryAssemblerSettingBehaviorOnAll        = 1 << 1, // Default
    PKParserFactoryAssemblerSettingBehaviorOnTerminals  = 1 << 2,
    PKParserFactoryAssemblerSettingBehaviorOnExplicit   = 1 << 3,
    PKParserFactoryAssemblerSettingBehaviorOnNone       = 1 << 4
} PKParserFactoryAssemblerSettingBehavior;

@interface PKParserFactory : NSObject

+ (PKParserFactory *)factory;

- (PKParser *)parserFromGrammar:(NSString *)g assembler:(id)a error:(NSError **)outError;
- (PKParser *)parserFromGrammar:(NSString *)g assembler:(id)a preassembler:(id)pa error:(NSError **)outError;

- (PKAST *)ASTFromGrammar:(NSString *)g error:(NSError **)outError;
- (PKAST *)ASTFromGrammar:(NSString *)g simplify:(BOOL)simplify error:(NSError **)outError;

@property (nonatomic, assign) PKParserFactoryAssemblerSettingBehavior assemblerSettingBehavior;
@end

@interface PKParserFactory (Testing)
- (PKParser *)exprParser;
@end
