//
//  PKNodeTypes.h
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/4/12.
//
//

#ifndef ParseKit_PKASTNodeType_h
#define ParseKit_PKASTNodeType_h

#import <Foundation/Foundation.h>
#import "PKNodeBase.h"

typedef enum {
    PKNodeTypeDefinition = 0,
    PKNodeTypeReference,
    PKNodeTypeConstant,
    PKNodeTypeLiteral,
    PKNodeTypeDelimited,
    PKNodeTypePattern,
    PKNodeTypeWhitespace,
    PKNodeTypeComposite,
    PKNodeTypeCollection,
    PKNodeTypeCardinal,
    PKNodeTypeOptional,
    PKNodeTypeMultiple,
//    PKNodeTypeRepetition,
//    PKNodeTypeDifference,
//    PKNodeTypeNegation,
} PKNodeType;

#endif
