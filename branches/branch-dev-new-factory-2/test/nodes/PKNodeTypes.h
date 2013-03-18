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
#import "PKBaseNode.h"

typedef enum {
    PKNodeTypeRoot = 0,
    PKNodeTypeDefinition,
    PKNodeTypeReference,
    PKNodeTypeConstant,
    PKNodeTypeLiteral,
    PKNodeTypeDelimited,
    PKNodeTypePattern,
    PKNodeTypeWhitespace,
    PKNodeTypeComposite,
    PKNodeTypeCollection,
    PKNodeTypeAlternation,
    PKNodeTypeCardinal,
    PKNodeTypeOptional,
    PKNodeTypeMultiple,
} PKNodeType;

#endif
