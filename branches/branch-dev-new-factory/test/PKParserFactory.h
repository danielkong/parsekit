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
    PKParserFactoryAssemblerSettingBehaviorOnAll        = 0, // Default
    PKParserFactoryAssemblerSettingBehaviorOnTerminals  = 1,
    PKParserFactoryAssemblerSettingBehaviorOnExplicit   = 2,
    PKParserFactoryAssemblerSettingBehaviorOnNone       = 4,
} PKParserFactoryAssemblerSettingBehavior;

@interface PKParserFactory : NSObject

+ (PKParserFactory *)factory;

- (PKParser *)parserFromGrammar:(NSString *)g assembler:(id)a error:(NSError **)outError;
- (PKParser *)parserFromGrammar:(NSString *)g assembler:(id)a preassembler:(id)pa error:(NSError **)outError;

- (NSDictionary *)symbolTableFromGrammar:(NSString *)g error:(NSError **)outError;
- (NSDictionary *)symbolTableFromGrammar:(NSString *)g simplify:(BOOL)simplify error:(NSError **)outError;

@property (nonatomic, assign) PKParserFactoryAssemblerSettingBehavior assemblerSettingBehavior;
@end

@interface PKParserFactory (Testing)
- (PKParser *)exprParser;
@end
