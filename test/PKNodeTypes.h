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
#import "PKNodeParser.h"

typedef enum {
    PKNodeTypeVariable = 0,
    PKNodeTypeConstant,
    PKNodeTypeCollection,
    PKNodeTypeRepetition,
    PKNodeTypeDifference,
    PKNodeTypeNegation,
    PKNodeTypePattern,
} PKNodeType;

#endif
