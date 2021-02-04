//
//  SANEPref.h
//  SANE
//
//  Created by Mattias Ellert on Sun Feb 20 2005.
//  Copyright (c) 2005 Mattias Ellert. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>
#import <SecurityInterface/SFAuthorizationView.h>

#if MAC_OS_X_VERSION_10_4 >= MAC_OS_X_VERSION_MIN_REQUIRED
typedef int NSInteger;
typedef unsigned int NSUInteger;
#endif

@interface SeEllertPreferenceSaneTableViewDD : NSTableView
- (NSDragOperation) draggingSourceOperationMaskForLocal:(BOOL) isLocal;
- (NSImage *) dragImageForRowsWithIndexes:(NSIndexSet *) dragRows tableColumns:(NSArray *) tableColumns event:(NSEvent *) dragEvent offset:(NSPointPointer) dragImageOffset;
@end

@interface SeEllertPreferenceSanePref : NSPreferencePane
{
    IBOutlet SFAuthorizationView * auth;

    IBOutlet NSTableView * backends;

    IBOutlet NSButton * sanedActive;
    IBOutlet NSTableView * hosts;
    IBOutlet NSTableView * users;
    IBOutlet NSButton * usePortRange;
    IBOutlet NSTextField * minPort;
    IBOutlet NSTextField * maxPort;
    IBOutlet NSButton * sanedHelp;

    IBOutlet NSPanel * configSheet;
    IBOutlet NSTextField * configFile;
    IBOutlet NSTextView * configEditor;

    IBOutlet NSPanel * firmwareSheet;
    IBOutlet NSTextField * firmwareDir;
    IBOutlet SeEllertPreferenceSaneTableViewDD * firmwares;

    NSMutableArray * availBackends;
    NSMutableArray * activeBackends;
    NSMutableArray * availConffiles;
    NSMutableArray * availFirmwaredirs;
    NSMutableArray * availManpages;

    NSMutableArray * acceptedHosts;
    NSMutableArray * acceptedUsers;

    NSMenu * backendMenu;

    NSMutableArray * availFirmwares;

    NSString * SANEConfigDir;
    NSString * SANEInstallDir;

    BOOL admin;

    BOOL savedllconf;
    BOOL savesanedconf;
    BOOL savesanedusers;

    BOOL sanedwasactive;
    BOOL portrangewasactive;
    int oldMinPort, oldMaxPort;
}

// NSPreferencePane
- (id) initWithBundle:(NSBundle *) bundle;
- (void) mainViewDidLoad;
- (void) didUnselect;

// NSTableViewDelegate
- (BOOL) tableView:(NSTableView *) tv shouldSelectRow:(NSInteger) row;

// NSTableDataSource
- (NSInteger) numberOfRowsInTableView:(NSTableView *) tv;
- (id) tableView:(NSTableView *) tv objectValueForTableColumn:(NSTableColumn *) column row:(NSInteger) row;
- (void) tableView:(NSTableView *) tv setObjectValue:(id) object forTableColumn:(NSTableColumn *) column row:(NSInteger) row;
- (BOOL) tableView:(NSTableView *) tv writeRowsWithIndexes:(NSIndexSet *) rows toPasteboard:(NSPasteboard *) pboard;
- (NSDragOperation) tableView:(NSTableView *) tv validateDrop:(id <NSDraggingInfo>) info proposedRow:(NSInteger) row proposedDropOperation:(NSTableViewDropOperation) op;
- (BOOL) tableView:(NSTableView *) tv acceptDrop:(id <NSDraggingInfo>) info row:(NSInteger) row dropOperation:(NSTableViewDropOperation) op;
- (NSArray *) tableView:(NSTableView *) tv namesOfPromisedFilesDroppedAtDestination:(NSURL *) dropDestination forDraggedRowsWithIndexes:(NSIndexSet *) rows;

// SFAuthorizationViewDelegate
- (void) authorizationViewDidAuthorize:(SFAuthorizationView *) view;
- (void) authorizationViewDidDeauthorize:(SFAuthorizationView *) view;
- (BOOL) authorizationViewShouldDeauthorize:(SFAuthorizationView *) view;

// Move a file using admin privileges
- (BOOL) authorizedFileMoveFrom:(NSString *) src to:(NSString *) dst setRoot:(BOOL) setRoot force:(BOOL) force;

// Save the preferences
- (void) savePreferences;

// Actions
- (IBAction) buttonPressed : (id) sender;
- (IBAction) buttonCellPressed : (id) sender;
- (IBAction) popUpButtonCellPressed : (id) sender;

@end
