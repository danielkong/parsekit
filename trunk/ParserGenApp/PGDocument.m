//
//  PGDocument.m
//  ParserGenApp
//
//  Created by Todd Ditchendorf on 4/15/13.
//
//

#import "PGDocument.h"
#import <ParseKit/ParseKit.h>
#import "PKSParserGenVisitor.h"

@interface PGDocument ()
@property (nonatomic, retain) PKParserFactory *factory;
@property (nonatomic, retain) PKRootNode *root;
@property (nonatomic, retain) PKSParserGenVisitor *visitor;
@end

@implementation PGDocument

- (id)init {
    self = [super init];
    if (self) {
        self.factory = [PKParserFactory factory];
        _factory.collectTokenKinds = YES;
        
        self.enableHybridDFA = YES;
        
        self.destinationPath = [@"~/Desktop" stringByExpandingTildeInPath];
        self.parserName = @"ExpressionParser";
        
        NSString *path = [[NSBundle mainBundle] pathForResource:@"expression" ofType:@"grammar"];
        self.grammar = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    }
    return self;
}


- (void)dealloc {
    self.destinationPath = nil;
    self.parserName = nil;
    self.grammar = nil;
    
    self.textView = nil;
    
    self.factory = nil;
    self.root = nil;
    self.visitor = nil;
    [super dealloc];
}


#pragma mark -
#pragma mark NSDocument

- (NSString *)windowNibName {
    return @"PGDocument";
}


- (void)windowControllerDidLoadNib:(NSWindowController *)wc {
    [super windowControllerDidLoadNib:wc];
    
    [_textView setFont:[NSFont fontWithName:@"Monaco" size:12.0]];
}


+ (BOOL)autosavesInPlace {
    return YES;
}


- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
    NSMutableDictionary *tab = [NSMutableDictionary dictionaryWithCapacity:7];

    if (_destinationPath) tab[@"destinationPath"] = _destinationPath;
    if (_grammar) tab[@"grammar"] = _grammar;
    if (_parserName) tab[@"parserName"] = _parserName;
    tab[@"enableHybridDFA"] = @(_enableHybridDFA);
    tab[@"enableMemoization"] = @(_enableMemoization);
    tab[@"enableAutomaticErrorRecovery"] = @(_enableAutomaticErrorRecovery);
    tab[@"assemblerSettingBehavior"] = @(_assemblerSettingBehavior);
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:tab];
    return data;
}


- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
    NSDictionary *tab = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    self.destinationPath = tab[@"destinationPath"];
    self.grammar = tab[@"grammar"];
    self.parserName = tab[@"parserName"];
    self.enableHybridDFA = [tab[@"enableHybridDFA"] boolValue];
    self.enableMemoization = [tab[@"enableMemoization"] boolValue];
    self.enableAutomaticErrorRecovery = [tab[@"enableAutomaticErrorRecovery"] boolValue];
    self.assemblerSettingBehavior = [tab[@"assemblerSettingBehavior"] integerValue];

    return YES;
}


#pragma mark -
#pragma mark Actions

- (IBAction)generate:(id)sender {
    NSString *destPath = [[_destinationPath copy] autorelease];
    NSString *parserName = [[_parserName copy] autorelease];
    NSString *grammar = [[_grammar copy] autorelease];
    
    if (![destPath length] || ![parserName length] || ![grammar length]) {
        NSBeep();
        return;
    }
    
    self.busy = YES;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self generateWithDestinationPath:destPath parserName:parserName grammar:grammar];
    });
}


- (IBAction)browse:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    NSWindow *win = [[[self windowControllers] lastObject] window];
    
    NSString *path = nil;
    
    if (_destinationPath) {
        path = _destinationPath;
        
        BOOL isDir;
        if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] || !isDir) {
            path = nil;
        }
    }
    
    if (path) {
        NSURL *pathURL = [NSURL fileURLWithPath:path];
        [panel setDirectoryURL:pathURL];
    }

    [panel setAllowsMultipleSelection:NO];
    [panel setCanChooseDirectories:YES];
    [panel setCanCreateDirectories:YES];
    [panel setCanChooseFiles:NO];
    
    [panel beginSheetModalForWindow:win completionHandler:^(NSInteger result) {
        if (NSOKButton == result) {
            NSString *path = [[panel URL] relativePath];
            self.destinationPath = path;
            
            [self updateChangeCount:NSChangeDone];
        }
    }];
}


- (IBAction)reveal:(id)sender {
    NSString *path = _destinationPath;
    
    BOOL isDir;
    NSFileManager *mgr = [NSFileManager defaultManager];
    while ([path length] && ![mgr fileExistsAtPath:path isDirectory:&isDir]) {
        path = [path stringByDeletingLastPathComponent];
    }
    
    if ([path length]) {
        [[NSWorkspace sharedWorkspace] selectFile:path inFileViewerRootedAtPath:nil];
    }
}

#pragma mark -
#pragma mark Private


- (void)generateWithDestinationPath:(NSString *)destPath parserName:(NSString *)parserName grammar:(NSString *)grammar {
    NSError *err = nil;
    self.root = (id)[_factory ASTFromGrammar:_grammar error:&err];
    _root.grammarName = self.parserName;
    
    self.visitor = [[[PKSParserGenVisitor alloc] init] autorelease];
    _visitor.enableHybridDFA = _enableHybridDFA;
    _visitor.enableMemoization = _enableMemoization;
    _visitor.enableAutomaticErrorRecovery = _enableAutomaticErrorRecovery;
    _visitor.assemblerSettingBehavior = _assemblerSettingBehavior;
    
    [_root visit:_visitor];
    
    NSString *path = [[NSString stringWithFormat:@"%@/%@Parser.h", destPath, _parserName] stringByExpandingTildeInPath];
    err = nil;
    if (![_visitor.interfaceOutputString writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&err]) {
        NSLog(@"%@", err);
    }
    
    path = [[NSString stringWithFormat:@"%@/%@Parser.m", destPath, _parserName] stringByExpandingTildeInPath];
    err = nil;
    if (![_visitor.implementationOutputString writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&err]) {
        NSLog(@"%@", err);
    }
    
    dispatch_async(dispatch_get_main_queue(), ^(void){
        [self done];
    });
}


- (void)done {
    [[NSSound soundNamed:@"Hero"] play];
    
    self.busy = NO;
}

@end
