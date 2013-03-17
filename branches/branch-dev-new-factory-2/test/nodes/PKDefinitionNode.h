//
//  PKNodeDefinition.h
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/4/12.
//
//

#import "PKNodeTypes.h"

@class PKBaseSymbol;

@interface PKDefinitionNode : PKBaseNode

@property (nonatomic, retain) NSString *callbackName;
@property (nonatomic, retain) PKBaseSymbol *symbol;
@end
