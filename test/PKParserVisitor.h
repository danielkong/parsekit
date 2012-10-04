//
//  TDParserVisitor.h
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/4/12.
//
//

#import <ParseKit/ParseKit.h>

//@class PKParser;
//@class PKCollectionParser;

@class PKNodeParser;
@class PKNodeTerminal;
@class PKNodeCollection;
@class PKNodeRepetition;
@class PKNodeDifference;
@class PKNodePattern;
@class PKNodeNegation;

@interface PKParserVisitor : NSObject

- (void)visitTerminal:(PKNodeTerminal *)node;
- (void)visitCollection:(PKNodeCollection *)node;
- (void)visitRepetition:(PKNodeRepetition *)node;
- (void)visitDifference:(PKNodeDifference *)node;
- (void)visitPattern:(PKNodePattern *)node;
- (void)visitNegation:(PKNodeNegation *)node;

@property (nonatomic, retain) PKParser *rootParser;
@property (nonatomic, retain) PKCollectionParser *currentParser;
@end
