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
#import "PKAST.h"

typedef enum {
    PKNodeTypeTerminal = 0,
    PKNodeTypeCollection,
    PKNodeTypeRepetition,
    PKNodeTypeDifference,
    PKNodeTypeNegation,
    PKNodeTypePattern,
} PKNodeType;

#endif
