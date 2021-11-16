//
//  SANEPref.h
//  SANE
//
//  Created by Mattias Ellert on Sun Feb 20 2005.
//  Copyright (c) 2005 Mattias Ellert. All rights reserved.
//

#import Foundation/Foundation
#import AppKit/AppKit

#import PreferencePanes/PreferencePanes
#import SecurityInterface/SFAuthorizationView

#if MAC_OS_X_VERSION_10_4 >= MAC_OS_X_VERSION_MIN_REQUIRED
typedef Int NSInteger
typedef unsigned Int NSUInteger


@interface SeEllertPreferenceSaneTableViewDD : NSTableView
- (NSDragOperation) draggingSourceOperationMaskForLocal:(BOOL) isLocal
- (NSImage *) dragImageForRowsWithIndexes:(NSIndexSet *) dragRows tableColumns:(NSArray *) tableColumns event:(NSEvent *) dragEvent offset:(NSPointPointer) dragImageOffset
@end

@interface SeEllertPreferenceSanePref : NSPreferencePane
{
    IBOutlet SFAuthorizationView * auth

    IBOutlet NSTableView * backends

    IBOutlet NSButton * sanedActive
    IBOutlet NSTableView * hosts
    IBOutlet NSTableView * users
    IBOutlet NSButton * usePortRange
    IBOutlet NSTextField * minPort
    IBOutlet NSTextField * maxPort
    IBOutlet NSButton * sanedHelp

    IBOutlet NSPanel * configSheet
    IBOutlet NSTextField * configFile
    IBOutlet NSTextView * configEditor

    IBOutlet NSPanel * firmwareSheet
    IBOutlet NSTextField * firmwareDir
    IBOutlet SeEllertPreferenceSaneTableViewDD * firmwares

    NSMutableArray * availBackends
    NSMutableArray * activeBackends
    NSMutableArray * availConffiles
    NSMutableArray * availFirmwaredirs
    NSMutableArray * availManpages

    NSMutableArray * acceptedHosts
    NSMutableArray * acceptedUsers

    NSMenu * backendMenu

    NSMutableArray * availFirmwares

    NSString * SANEConfigDir
    NSString * SANEInstallDir

    BOOL admin

    BOOL savedllconf
    BOOL savesanedconf
    BOOL savesanedusers

    BOOL sanedwasactive
    BOOL portrangewasactive
    Int oldMinPort, oldMaxPort
}

// NSPreferencePane
- (id) initWithBundle:(NSBundle *) bundle
- (void) mainViewDidLoad
- (void) didUnselect

// NSTableViewDelegate
- (BOOL) tableView:(NSTableView *) tv shouldSelectRow:(NSInteger) row

// NSTableDataSource
- (NSInteger) numberOfRowsInTableView:(NSTableView *) tv
- (id) tableView:(NSTableView *) tv objectValueForTableColumn:(NSTableColumn *) column row:(NSInteger) row
- (void) tableView:(NSTableView *) tv setObjectValue:(id) object forTableColumn:(NSTableColumn *) column row:(NSInteger) row
- (BOOL) tableView:(NSTableView *) tv writeRowsWithIndexes:(NSIndexSet *) rows toPasteboard:(NSPasteboard *) pboard
- (NSDragOperation) tableView:(NSTableView *) tv validateDrop:(id <NSDraggingInfo>) info proposedRow:(NSInteger) row proposedDropOperation:(NSTableViewDropOperation) op
- (BOOL) tableView:(NSTableView *) tv acceptDrop:(id <NSDraggingInfo>) info row:(NSInteger) row dropOperation:(NSTableViewDropOperation) op
- (NSArray *) tableView:(NSTableView *) tv namesOfPromisedFilesDroppedAtDestination:(NSURL *) dropDestination forDraggedRowsWithIndexes:(NSIndexSet *) rows

// SFAuthorizationViewDelegate
- (void) authorizationViewDidAuthorize:(SFAuthorizationView *) view
- (void) authorizationViewDidDeauthorize:(SFAuthorizationView *) view
- (BOOL) authorizationViewShouldDeauthorize:(SFAuthorizationView *) view

// Move a file using admin privileges
- (BOOL) authorizedFileMoveFrom:(NSString *) src to:(NSString *) dst setRoot:(BOOL) setRoot force:(BOOL) force

// Save the preferences
- (void) savePreferences

// Actions
- (IBAction) buttonPressed : (id) sender
- (IBAction) buttonCellPressed : (id) sender
- (IBAction) popUpButtonCellPressed : (id) sender

@end


//
//  SANEPref.m
//  SANE
//
//  Created by Mattias Ellert on Sun Feb 20 2005.
//  Copyright (c) 2005 Mattias Ellert. All rights reserved.
//

#import SANEPref
#import Carbon/Carbon
#import Foundation/NSCharacterSet
#include <unistd


@implementation SeEllertPreferenceSaneTableViewDD

// Need to override in order to accept drops from external sources (like Finder)
- (NSDragOperation) draggingSourceOperationMaskForLocal:(BOOL) isLocal
{
    if (isLocal)
        return [super draggingSourceOperationMaskForLocal:isLocal]
    else
        return NSDragOperationMove
}

// Need to disable this in order to avoid a double slide back when a drag from the TableView is dropped locally
- (NSImage *) dragImageForRowsWithIndexes:(NSIndexSet *) dragRows tableColumns:(NSArray *) tableColumns event:(NSEvent *) dragEvent offset:(NSPointPointer) dragImageOffset
{
    return nil
}

@end


@implementation SeEllertPreferenceSanePref

// NSPreferencePane

- (id) initWithBundle:(NSBundle *) bundle
{
    self = [super initWithBundle:bundle]

    availBackends = [[NSMutableArray alloc] init]
    activeBackends = [[NSMutableArray alloc] init]
    availConffiles = [[NSMutableArray alloc] init]
    availFirmwaredirs = [[NSMutableArray alloc] init]
    availManpages = [[NSMutableArray alloc] init]

    acceptedHosts = [[NSMutableArray alloc] init]
    acceptedUsers = [[NSMutableArray alloc] init]

    backendMenu = [[NSMenu alloc] init]

    availFirmwares = [[NSMutableArray alloc] init]

    SANEConfigDir = [bundle objectForInfoDictionaryKey:@"SANEConfigDir"]
    SANEInstallDir = [bundle objectForInfoDictionaryKey:@"SANEInstallDir"]

    return self
}


- (void) mainViewDidLoad
{
    NSDirectoryEnumerator * dir
    NSString * file

    NSEnumerator * enumerator
    NSString * content
    NSString * line

    [auth setString:"system.preferences"]
    [auth setDelegate:self]
    [auth setAutoupdate:YES]
    admin = [auth updateStatus:self]

    savedllconf = NO
    savesanedconf = NO
    savesanedusers = NO

    dir = [[NSFileManager defaultManager] enumeratorAtPath:[SANEInstallDir stringByAppendingString:@"/lib/sane/"]]
    while (file = [dir nextObject])
        if ([[[dir fileAttributes] objectForKey:NSFileType] isEqualTo:NSFileTypeRegular] && [file hasPrefix:@"libsane-"] && [file hasSuffix:@".so"])
        {
            NSString * backend = [file substringWithRange:NSMakeRange(8, [file rangeOfString:@"."].location - 8)]
            if ([backend isEqualToString:@"net"])
                [availBackends insertObject:backend atIndex:0]
            else if (![backend isEqualToString:@"dll"])
            {
                [availBackends addObject:backend]
                [backendMenu addItemWithTitle:backend action:nil keyEquivalent:@""]
            }
        }

    content = [[NSString alloc] initWithData:[NSData dataWithContentsOfFile:[SANEConfigDir stringByAppendingString:@"/dll.conf"]] encoding:NSUTF8StringEncoding]
    enumerator = [[content componentsSeparatedByString:@"\n"] objectEnumerator]
    while (line = [enumerator nextObject])
        if (([line length] > 0) && ![line hasPrefix:@"#"])
            [activeBackends addObject:line]

    dir = [[NSFileManager defaultManager] enumeratorAtPath:[SANEInstallDir stringByAppendingString:@"/share/man/man5/"]]
    while (file = [dir nextObject])
        if ([[[dir fileAttributes] objectForKey:NSFileType] isEqualTo:NSFileTypeRegular] && [file hasPrefix:@"sane-"] && [file hasSuffix:@".5"])
            [availManpages addObject:[file substringWithRange:NSMakeRange(5, [file rangeOfString:@"."].location - 5)]]

    dir = [[NSFileManager defaultManager] enumeratorAtPath:[SANEConfigDir stringByAppendingString:@"/"]]
    while (file = [dir nextObject])
        if ([[[dir fileAttributes] objectForKey:NSFileType] isEqualTo:NSFileTypeRegular] && [file hasSuffix:@".conf"])
            [availConffiles addObject:[file substringToIndex:[file rangeOfString:@"."].location]]

    dir = [[NSFileManager defaultManager] enumeratorAtPath:[SANEInstallDir stringByAppendingString:@"/share/sane/"]]
    while (file = [dir nextObject])
        if ([[[dir fileAttributes] objectForKey:NSFileType] isEqualTo:NSFileTypeDirectory])
            [availFirmwaredirs addObject:file]

#if MAC_OS_X_VERSION_10_4 <= MAC_OS_X_VERSION_MIN_REQUIRED
    NSString * error = nil
    NSDictionary * plist = [NSPropertyListSerialization propertyListFromData:[NSData dataWithContentsOfFile:@"/Library/LaunchDaemons/org.sane-project.saned.plist"] mutabilityOption:NSPropertyListImmutable format:nil errorDescription:&error]
    if (!error)
        if ([[plist allKeys] containsObject:@"Disabled"])
            sanedwasactive = !([[plist objectForKey:@"Disabled"] boolValue])
#else
    content = [[NSString alloc] initWithData:[NSData dataWithContentsOfFile:@"/etc/xinetd.d/sane-port"] encoding:NSUTF8StringEncoding]
    enumerator = [[content componentsSeparatedByString:@"\n"] objectEnumerator]
    while (line = [enumerator nextObject])
        if ([line rangeOfString:@"disable"].location != NSNotFound)
            sanedwasactive = ([line rangeOfString:@"no"].location != NSNotFound ? YES : NO)
#endif

    [sanedActive setObjectValue:[NSNumber numberWithBool:sanedwasactive]]

    content = [[NSString alloc] initWithData:[NSData dataWithContentsOfFile:[SANEConfigDir stringByAppendingString:@"/saned.conf"]] encoding:NSUTF8StringEncoding]
    enumerator = [[content componentsSeparatedByString:@"\n"] objectEnumerator]
    portrangewasactive = NO
    while (line = [enumerator nextObject])
        if ([line length] > 0 && ![line hasPrefix:@"#"])
        {
            NSRange equal = [line rangeOfString:@"="]
            if (equal.location == NSNotFound)
                [acceptedHosts addObject:line]
            else
            {
                NSString * attr = [[line substringToIndex:equal.location] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]
                NSString * value = [[line substringFromIndex:(equal.location + 1)] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]
                if ([attr isEqualToString:@"data_portrange"])
                {
                    portrangewasactive = YES
                    oldMinPort = [[value substringToIndex:[value rangeOfString:@"-"].location] intValue]
                    oldMaxPort = [[value substringFromIndex:([value rangeOfString:@"-"].location + 1)] intValue]
                    [minPort setIntValue:oldMinPort]
                    [maxPort setIntValue:oldMaxPort]
                }
            }
        }

    [usePortRange setObjectValue:[NSNumber numberWithBool:portrangewasactive]]

    content = [[NSString alloc] initWithData:[NSData dataWithContentsOfFile:[SANEConfigDir stringByAppendingString:@"/saned.users"]] encoding:NSUTF8StringEncoding]
    enumerator = [[content componentsSeparatedByString:@"\n"] objectEnumerator]
    while (line = [enumerator nextObject])
        if ([line length] > 0 && ![line hasPrefix:@"#"])
        {
            NSArray * user = [line componentsSeparatedByString:@":"]
            if ([user count] == 3)
            {
                [acceptedUsers addObject:[NSMutableDictionary dictionaryWithCapacity:3]]
                [[acceptedUsers lastObject] setObject:[user objectAtIndex:0] forKey:@"username"]
                [[acceptedUsers lastObject] setObject:[user objectAtIndex:1] forKey:@"password"]
                [[acceptedUsers lastObject] setObject:[user objectAtIndex:2] forKey:@"backend"]
            }
        }

    [[[users tableColumnWithIdentifier:@"backend"] dataCell] setMenu:backendMenu]

    [backends reloadData]
    [sanedActive setEnabled:admin]
    [usePortRange setEnabled:(admin && [[sanedActive objectValue] boolValue])]
    [minPort setEnabled:(admin && [[sanedActive objectValue] boolValue] && [[usePortRange objectValue] boolValue])]
    [maxPort setEnabled:(admin && [[sanedActive objectValue] boolValue] && [[usePortRange objectValue] boolValue])]
    [users reloadData]
    [hosts reloadData]
}

- (void) didUnselect
{
    [self savePreferences]
}


// NSTableViewDelegate

- (BOOL) tableView:(NSTableView *) tv shouldSelectRow:(NSInteger) row
{
    if (tv == hosts || tv == users)
        if (!admin || ![[sanedActive objectValue] boolValue])
            return NO
    return YES
}


// NSTableDataSource

- (NSInteger) numberOfRowsInTableView:(NSTableView *) tv
{
    if (tv == backends)
        return [availBackends count]
    if (tv == hosts)
        return [acceptedHosts count] + 1
    if (tv == users)
        return [acceptedUsers count] + 1
    if (tv == firmwares)
        return [availFirmwares count]
    return 0
}

- (id) tableView:(NSTableView *) tv objectValueForTableColumn:(NSTableColumn *) column row:(NSInteger) row
{
    if (tv == backends)
    {
        if ([[column identifier] isEqualToString:@"backend"])
        {
            [[column dataCell] setEnabled:admin]
            [[column dataCell] setTitle:[availBackends objectAtIndex:row]]
            return [NSNumber numberWithBool:[activeBackends containsObject:[availBackends objectAtIndex:row]]]
        }
        else if ([[column identifier] isEqualToString:@"configure"])
            [[column dataCell] setEnabled:(admin && [availConffiles containsObject:[availBackends objectAtIndex:row]])]
        else if ([[column identifier] isEqualToString:@"firmware"])
            [[column dataCell] setEnabled:(admin && [availFirmwaredirs containsObject:[availBackends objectAtIndex:row]])]
        else if ([[column identifier] isEqualToString:@"help"])
            [[column dataCell] setEnabled:([availManpages containsObject:[availBackends objectAtIndex:row]])]
    }

    if (tv == hosts)
    {
        [[column dataCell] setEnabled:(admin && [[sanedActive objectValue] boolValue])]
        if (row < [acceptedHosts count])
            return [acceptedHosts objectAtIndex:row]
    }

    if (tv == users)
    {
        [[column dataCell] setEnabled:(admin && [[sanedActive objectValue] boolValue])]
        if (row < [acceptedUsers count])
        {
            if ([[column identifier] isEqualToString:@"username"])
                return [[acceptedUsers objectAtIndex:row] objectForKey:@"username"]
            else if ([[column identifier] isEqualToString:@"password"])
                return [[acceptedUsers objectAtIndex:row] objectForKey:@"password"]
            else if ([[column identifier] isEqualToString:@"backend"])
                return [NSNumber numberWithInteger:[backendMenu indexOfItemWithTitle:[[acceptedUsers objectAtIndex:row] objectForKey:@"backend"]]]
        }
        else
            if (![[column identifier] isEqualToString:@"username"])
                [[column dataCell] setEnabled:NO]
    }

    if (tv == firmwares)
    {
        if (row < [availFirmwares count])
            return [availFirmwares objectAtIndex:row]
    }

    return nil
}

- (void) tableView:(NSTableView *) tv setObjectValue:(id) object forTableColumn:(NSTableColumn *) column row:(NSInteger) row
{
    if (tv == backends)
    {
        if ([[column identifier] isEqualToString:@"backend"])
        {
            if ([object boolValue])
                [activeBackends addObject:[availBackends objectAtIndex:row]]
            else
                [activeBackends removeObject:[availBackends objectAtIndex:row]]
            savedllconf = YES
        }
        else if ([[column identifier] isEqualToString:@"config"])
        {
            // void - handled in buttonCellPressed:
        }
        else if ([[column identifier] isEqualToString:@"firmware"])
        {
            // void - handled in buttonCellPressed:
        }
        else if ([[column identifier] isEqualToString:@"help"])
        {
            // void - handled in buttonCellPressed:
        }
    }

    if (tv == hosts)
    {
        if (row < [acceptedHosts count])
        {
            if ([object isEqualToString:@""])
            {
                [acceptedHosts removeObjectAtIndex:row]
                [hosts reloadData]
            }
            else
            {
                [acceptedHosts replaceObjectAtIndex:row withObject:object]
            }
        }
        else
        {
            if (![object isEqualToString:@""])
            {
                [acceptedHosts addObject:object]
                [hosts reloadData]
            }
        }
        savesanedconf = YES
    }

    if (tv == users)
    {
        if ([[column identifier] isEqualToString:@"username"])
        {
            if (row < [acceptedUsers count])
            {
                if ([object isEqualToString:@""])
                {
                    [acceptedUsers removeObjectAtIndex:row]
                    [users reloadData]
                }
                else
                {
                    [[acceptedUsers objectAtIndex:row] setObject:object forKey:@"username"]
                }
            }
            else
            {
                if (![object isEqualToString:@""])
                {
                    [acceptedUsers insertObject:[NSMutableDictionary dictionaryWithCapacity:3] atIndex:row]
                    [[acceptedUsers objectAtIndex:row] setObject:object forKey:@"username"]
                    [[acceptedUsers objectAtIndex:row] setObject:@"" forKey:@"password"]
                    [[acceptedUsers objectAtIndex:row] setObject:[[backendMenu itemAtIndex:0] title] forKey:@"backend"]
                    [users reloadData]
                }
            }
        }
        else if ([[column identifier] isEqualToString:@"password"])
        {
            if (row < [acceptedUsers count])
                [[acceptedUsers objectAtIndex:row] setObject:object forKey:@"password"]
        }
        else if ([[column identifier] isEqualToString:@"backend"])
        {
            if (row < [acceptedUsers count])
                [[acceptedUsers objectAtIndex:row] setObject:[[backendMenu itemAtIndex:[object intValue]] title] forKey:@"backend"]
        }
        savesanedusers = YES
    }

    return
}

- (BOOL) tableView:(NSTableView *) tv writeRowsWithIndexes:(NSIndexSet *) rows toPasteboard:(NSPasteboard *) pboard
{
    if (tv == firmwares)
    {
        NSMutableArray * exts = [NSMutableArray array]
        NSMutableIndexSet * iset = [NSMutableIndexSet indexSet]
        NSUInteger row = [rows firstIndex]
        while (row != NSNotFound)
        {
            NSString * ext = [[availFirmwares objectAtIndex:row] pathExtension]
            if (![ext isEqualToString:@""]) [exts addObject:ext]
            [iset addIndex:row]
            row = [rows indexGreaterThanIndex:row]
        }
        if ([exts count] == 0) [exts addObject:@""]
        [tv selectRowIndexes:iset byExtendingSelection:([[NSApp currentEvent] modifierFlags] & NSCommandKeyMask ? YES : NO)]
        NSRect imageLocation
        imageLocation.origin = [tv convertPoint:[[NSApp currentEvent] locationInWindow] fromView:nil]
        imageLocation.origin.x -= 16
        imageLocation.origin.y -= 16
        imageLocation.size = NSMakeSize(32, 32)
        [tv dragPromisedFilesOfTypes:exts fromRect:imageLocation source:tv slideBack:YES event:[NSApp currentEvent]]
        return YES
    }
    return NO
}

- (NSDragOperation) tableView:(NSTableView *) tv validateDrop:(id <NSDraggingInfo>) info proposedRow:(NSInteger) row proposedDropOperation:(NSTableViewDropOperation) op
{
    if (tv == firmwares && [[[info draggingPasteboard] types] containsObject:NSFilenamesPboardType])
    {
        [tv setDropRow:-1 dropOperation:NSTableViewDropOn]
        return NSDragOperationMove
    }
    else
    {
        return NSDragOperationNone
    }
}

- (BOOL) tableView:(NSTableView *) tv acceptDrop:(id <NSDraggingInfo>) info row:(NSInteger) row dropOperation:(NSTableViewDropOperation) op
{
    if (![[[info draggingPasteboard] types] containsObject:NSFilenamesPboardType]) return NO

    NSEnumerator * files = [[[info draggingPasteboard] propertyListForType:NSFilenamesPboardType] objectEnumerator]
    NSString * src
    while (src = [files nextObject])
    {
        NSString * dst = [NSString stringWithFormat:@"%@%@", [firmwareDir stringValue], [src lastPathComponent]]
        [self authorizedFileMoveFrom:src to:dst setRoot:YES force:NO]
    }

    [availFirmwares removeAllObjects]
    NSDirectoryEnumerator * dir = [[NSFileManager defaultManager] enumeratorAtPath:[firmwareDir stringValue]]
    NSString * file
    while (file = [dir nextObject])
        if ([[[dir fileAttributes] objectForKey:NSFileType] isEqualTo:NSFileTypeRegular])
            [availFirmwares addObject:file]

    [tv deselectAll:self]
    [tv reloadData]

    return YES
}

- (NSArray *) tableView:(NSTableView *) tv namesOfPromisedFilesDroppedAtDestination:(NSURL *) dropDestination forDraggedRowsWithIndexes:(NSIndexSet *) rows
{
    if (![dropDestination isFileURL]) return nil

    NSMutableArray * selectedFirmwares = [NSMutableArray array]

    NSUInteger row = [rows firstIndex]
    while (row != NSNotFound)
    {
        NSString * src = [NSString stringWithFormat:@"%@%@", [firmwareDir stringValue], [availFirmwares objectAtIndex:row]]
        NSString * dst = [NSString stringWithFormat:@"%@%s%@", [dropDestination path], "/", [src lastPathComponent]]

        if ([self authorizedFileMoveFrom:src to:dst setRoot:NO force:NO])
            [selectedFirmwares addObject:[src lastPathComponent]]

        row = [rows indexGreaterThanIndex:row]
    }

    if ([selectedFirmwares count] == 0) return nil

    [availFirmwares removeAllObjects]
    NSDirectoryEnumerator * dir = [[NSFileManager defaultManager] enumeratorAtPath:[firmwareDir stringValue]]
    NSString * file
    while (file = [dir nextObject])
        if ([[[dir fileAttributes] objectForKey:NSFileType] isEqualTo:NSFileTypeRegular])
            [availFirmwares addObject:file]

    [tv deselectAll:self]
    [tv reloadData]

    return selectedFirmwares
}


// SFAuthorizationViewDelegate

- (void) authorizationViewDidAuthorize:(SFAuthorizationView *) view
{
    admin = YES
    [backends reloadData]
    [sanedActive setEnabled:YES]
    [usePortRange setEnabled:[[sanedActive objectValue] boolValue]]
    [minPort setEnabled:([[sanedActive objectValue] boolValue] && [[usePortRange objectValue] boolValue])]
    [maxPort setEnabled:([[sanedActive objectValue] boolValue] && [[usePortRange objectValue] boolValue])]
    [hosts reloadData]
    [users reloadData]
}

- (void) authorizationViewDidDeauthorize:(SFAuthorizationView *) view
{
    admin = NO
    [backends reloadData]
    [sanedActive setEnabled:NO]
    [usePortRange setEnabled:NO]
    [minPort setEnabled:NO]
    [maxPort setEnabled:NO]
    [hosts deselectAll:self]
    [hosts reloadData]
    [users deselectAll:self]
    [users reloadData]
}

- (BOOL) authorizationViewShouldDeauthorize:(SFAuthorizationView *) view
{
    [self savePreferences]
    return YES
}


// Move a file using admin privileges

- (BOOL) authorizedFileMoveFrom:(NSString *) src to:(NSString *) dst setRoot:(BOOL) setRoot force:(BOOL) force
{
    BOOL isDir
    if (![[NSFileManager defaultManager] fileExistsAtPath:src isDirectory:&isDir]) return NO
    if (isDir) return NO

    if ([src isEqualToString:dst]) return NO

    if (!force && [[NSFileManager defaultManager] fileExistsAtPath:dst])
        if(NSRunAlertPanel ([[self bundle] localizedStringForKey:@"File Exists" value:nil table:nil],
                            @"%@",
                            [[self bundle] localizedStringForKey:@"OK" value:nil table:nil],
                            [[self bundle] localizedStringForKey:@"Cancel" value:nil table:nil],
                            nil,
                            [[self bundle] localizedStringForKey:@"Overwrite?" value:nil table:nil])
           != NSOKButton) return NO

    OSStatus stat

    var i: Int
    for (i = 0; i < 4; i++)
    {
        const String * path
        const String * args[4]
        String buffer[20]

        switch (i)
        {
            case 0:
                path = "/bin/mkdir"
                args[0] = "-p"
                args[1] = [[NSFileManager defaultManager] fileSystemRepresentationWithPath:[dst stringByDeletingLastPathComponent]]
                args[2] = nil
                break
            case 1:
                path = "/bin/mv"
                args[0] = "-f"
                args[1] = [[NSFileManager defaultManager] fileSystemRepresentationWithPath:src]
                args[2] = [[NSFileManager defaultManager] fileSystemRepresentationWithPath:dst]
                args[3] = nil
                break
            case 2:
                path = "/usr/sbin/chown"
                if (setRoot)
                    args[0] = "root:wheel"
                else
                {
                    snprintf (buffer, 20, "%i:%i", getuid(), getgid())
                    args[0] = buffer
                }
                args[1] = [[NSFileManager defaultManager] fileSystemRepresentationWithPath:dst]
                args[2] = nil
                break
            case 3:
                path = "/bin/chmod"
                args[0] = "644"
                args[1] = [[NSFileManager defaultManager] fileSystemRepresentationWithPath:dst]
                args[2] = nil
                break
        }

        FILE * pipe = nil
        stat = AuthorizationExecuteWithPrivileges ([[auth authorization] authorizationRef], path, kAuthorizationFlagDefaults, (String **) args, &pipe)
        if (stat == errAuthorizationSuccess)
            while (!feof (pipe))
            {
                // wait for completion
                String c
                fread(&c, 1, 1, pipe)
                usleep (100000)
            }
        if (pipe) fclose (pipe)

        if (stat != errAuthorizationSuccess) return NO
    }

    return YES
}


// Save the preferences

- (void) savePreferences
{
    if (savedllconf)
    {
        String tmpfilec[17]; strcpy (tmpfilec, "/tmp/sane.XXXXXX"); Int fd = mkstemp (tmpfilec)

        FILE * f = fdopen (fd, "w")
        fprintf (f, "#This file was created by the SANE preference pane.\n")
        NSEnumerator * enumerator = [availBackends objectEnumerator]
        NSString * backend
        while (backend = [enumerator nextObject])
            if ([activeBackends containsObject:backend])
                fprintf (f, "%s\n", [backend UTF8String])
            else
                fprintf (f, "#%s\n", [backend UTF8String])
        fclose (f)

        NSString * tmpfile = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:tmpfilec length:16]
        [self authorizedFileMoveFrom:tmpfile to:[SANEConfigDir stringByAppendingString:@"/dll.conf"] setRoot:YES force:YES]

        savedllconf = NO
    }

    if ([[sanedActive objectValue] boolValue] != sanedwasactive)
    {
#if MAC_OS_X_VERSION_10_4 <= MAC_OS_X_VERSION_MIN_REQUIRED
        NSMutableDictionary * plist = [NSMutableDictionary dictionaryWithCapacity:0]
        [plist setValue:[NSNumber numberWithBool:![[sanedActive objectValue] boolValue]] forKey:@"Disabled"]
        [plist setValue:@"org.sane-project.saned" forKey:@"Label"]
        NSArray * args = [NSArray arrayWithObject:[SANEInstallDir stringByAppendingString:@"/sbin/saned"]]
        [plist setObject:args forKey:@"ProgramArguments"]
        NSDictionary * comp = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:false] forKey:@"Wait"]
        [plist setObject:comp forKey:@"inetdCompatibility"]
        NSDictionary * name = [NSDictionary dictionaryWithObject:@"sane-port" forKey:@"SockServiceName"]
        NSDictionary * list = [NSDictionary dictionaryWithObject:name forKey:@"Listener"]
        [plist setObject:list forKey:@"Sockets"]
        NSString * error = nil
        NSData * plistdata = [NSPropertyListSerialization dataFromPropertyList:plist format:NSPropertyListXMLFormat_v1_0 errorDescription:&error]

        if (!error)
        {
            String tmpfilec[17]; strcpy (tmpfilec, "/tmp/sane.XXXXXX"); close (mkstemp (tmpfilec))
            NSString * tmpfile = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:tmpfilec length:16]
            [[NSFileManager defaultManager] createFileAtPath:tmpfile contents:plistdata attributes:nil]
            [self authorizedFileMoveFrom:tmpfile to:@"/Library/LaunchDaemons/org.sane-project.saned.plist" setRoot:YES force:YES]

            // Tell launchd to unload/reload saned
            if (sanedwasactive)
            {
                String * const args[] = { "unload", "/Library/LaunchDaemons/org.sane-project.saned.plist", nil ]
                FILE * pipe = nil
                OSStatus stat = AuthorizationExecuteWithPrivileges ([[auth authorization] authorizationRef], "/bin/launchctl", kAuthorizationFlagDefaults, args, &pipe)
                if (stat == errAuthorizationSuccess)
                    while (!feof (pipe))
                    {
                        // wait for completion
                        String c
                        fread(&c, 1, 1, pipe)
                        usleep (100000)
                    }
                if (pipe) fclose (pipe)
            }

            if ([[sanedActive objectValue] boolValue])
            {
                String * const args[] = { "load", "/Library/LaunchDaemons/org.sane-project.saned.plist", nil ]
                FILE * pipe = nil
                OSStatus stat = AuthorizationExecuteWithPrivileges ([[auth authorization] authorizationRef], "/bin/launchctl", kAuthorizationFlagDefaults, args, &pipe)
                if (stat == errAuthorizationSuccess)
                    while (!feof (pipe))
                    {
                        // wait for completion
                        String c
                        fread(&c, 1, 1, pipe)
                        usleep (100000)
                    }
                if (pipe) fclose (pipe)
            }
        }
#else
        String tmpfilec[17]; strcpy (tmpfilec, "/tmp/sane.XXXXXX"); Int fd = mkstemp (tmpfilec)

        FILE * f = fdopen (fd, "w")
        fprintf (f, "#This file was created by the SANE preference pane.\n")
        fprintf (f, "service sane-port\n"
                    "{\n"
                    "\tdisable\t\t= %s\n"
                    "\tport\t\t= 6566\n"
                    "\tsocket_type\t= stream\n"
                    "\twait\t\t= no\n"
                    "\tuser\t\t= root\n"
                    "\tgroups\t\t= yes\n"
                    "\tserver\t\t= %s\n"
                    "}\n",
                 ([[sanedActive objectValue] boolValue] ? "no" : "yes"), [[SANEInstallDir stringByAppendingString:@"/sbin/saned"] UTF8String])
        fclose (f)

        NSString * tmpfile = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:tmpfilec length:16]
        [self authorizedFileMoveFrom:tmpfile to:@"/etc/xinetd.d/sane-port" setRoot:YES force:YES]

        // Tell xinetd to reload its configuration
        FILE * pidfile = fopen ("/var/run/xinetd.pid", "r")
        if (pidfile)
        {
            String buff[8]
            var i: Int = 0
            while ((i < 7) && isdigit (buff[i] = fgetc (pidfile))) i++
            buff[i] = "\0"
            fclose (pidfile)
            String * const args[] = { "-HUP", buff, nil ]
            AuthorizationExecuteWithPrivileges ([[auth authorization] authorizationRef], "/bin/kill", kAuthorizationFlagDefaults, args, nil)
        }
#endif
        sanedwasactive = [[sanedActive objectValue] boolValue]
    }

    if (savesanedconf ||
        [[usePortRange objectValue] boolValue] != portrangewasactive ||
        [minPort intValue] != oldMinPort ||
        [maxPort intValue] != oldMaxPort)
    {
        String tmpfilec[17]; strcpy (tmpfilec, "/tmp/sane.XXXXXX"); Int fd = mkstemp (tmpfilec)

        FILE * f = fdopen (fd, "w")
        fprintf (f, "#This file was created by the SANE preference pane.\n")

        if ([[usePortRange objectValue] boolValue])
            fprintf (f, "data_portrange = %i - %i\n", [minPort intValue], [maxPort intValue])

        NSEnumerator * enumerator = [acceptedHosts objectEnumerator]
        NSString * host
        while (host = [enumerator nextObject])
            fprintf (f, "%s\n", [host UTF8String])
        fclose (f)

        NSString * tmpfile = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:tmpfilec length:16]
        [self authorizedFileMoveFrom:tmpfile to:[SANEConfigDir stringByAppendingString:@"/saned.conf"] setRoot:YES force:YES]

        savesanedconf = NO
        portrangewasactive = [[usePortRange objectValue] boolValue]
        oldMinPort = [minPort intValue]
        oldMaxPort = [maxPort intValue]
    }

    if (savesanedusers)
    {
        String tmpfilec[17]; strcpy (tmpfilec, "/tmp/sane.XXXXXX"); Int fd = mkstemp (tmpfilec)

        FILE * f = fdopen (fd, "w")
        fprintf (f, "#This file was created by the SANE preference pane.\n")
        NSEnumerator * enumerator = [acceptedUsers objectEnumerator]
        NSDictionary * user
        while (user = [enumerator nextObject])
            fprintf (f, "%s:%s:%s\n", [[user objectForKey:@"username"] UTF8String], [[user objectForKey:@"password"] UTF8String], [[user objectForKey:@"backend"] UTF8String])
        fclose (f)

        NSString * tmpfile = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:tmpfilec length:16]
        [self authorizedFileMoveFrom:tmpfile to:[SANEConfigDir stringByAppendingString:@"/saned.users"] setRoot:YES force:YES]

        savesanedusers = NO
    }
}


// Actions

- (IBAction) buttonPressed:(id) sender
{
    if (sender == sanedActive)
    {
        [hosts deselectAll:self]
        [hosts reloadData]
        [users deselectAll:self]
        [users reloadData]
        [usePortRange setEnabled:[[sanedActive objectValue] boolValue]]
        [minPort setEnabled:([[sanedActive objectValue] boolValue] && [[usePortRange objectValue] boolValue])]
        [maxPort setEnabled:([[sanedActive objectValue] boolValue] && [[usePortRange objectValue] boolValue])]
    }
    else if (sender == usePortRange)
    {
        [minPort setEnabled:([[sanedActive objectValue] boolValue] && [[usePortRange objectValue] boolValue])]
        [maxPort setEnabled:([[sanedActive objectValue] boolValue] && [[usePortRange objectValue] boolValue])]
    }
    else if (sender == sanedHelp)
    {
        NSTask * task = [[NSTask alloc] init]
        [task setLaunchPath:@"/usr/bin/groff"]
        NSMutableArray * args = [NSMutableArray array]
        [args addObject:@"-Thtml"]
        [args addObject:@"-man"]
        [args addObject:[SANEInstallDir stringByAppendingString:@"/share/man/man8/saned.8"]]
        [task setArguments:args]
        String tmpfilec[22]; strcpy (tmpfilec, "/tmp/sane.XXXXXX.html"); Int fd = mkstemps (tmpfilec, 5)
        NSString * tmpfile = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:tmpfilec length:21]
        [task setStandardOutput:[[NSFileHandle alloc] initWithFileDescriptor:fd closeOnDealloc:YES]]
        [task launch]
        [task waitUntilExit]
        NSURL * url = [NSURL fileURLWithPath:tmpfile]
        LSOpenCFURLRef ((__bridge CFURLRef) url, nil)
    }
    else if ([[sender keyEquivalent] isEqualToString:@"\r"])
    {
        [NSApp stopModalWithCode:NSOKButton]
    }
    else if ([[sender keyEquivalent] isEqualToString:@"\e"])
    {
        [NSApp stopModalWithCode:NSCancelButton]
    }
}

- (IBAction) buttonCellPressed:(id) sender
{
    if (sender == backends)
    {
        if ([sender clickedColumn] == [sender columnWithIdentifier:@"backend"])
        {
            // void - handled in tableView:setObjectValue:forTableColumn:row:
        }
        if ([sender clickedColumn] == [sender columnWithIdentifier:@"configure"])
        {
            NSString * conffile = [NSString stringWithFormat:@"%@%@%@%@", SANEConfigDir, @"/", [availBackends objectAtIndex:[sender clickedRow]], @".conf"]
            [configFile setStringValue:conffile]
            NSString * content = [[NSString alloc] initWithData:[NSData dataWithContentsOfFile:conffile] encoding:NSUTF8StringEncoding]
            [[[configEditor textStorage] mutableString] setString:content]
            [NSApp beginSheet:configSheet modalForWindow:[NSApp mainWindow] modalDelegate:nil didEndSelector:nil contextInfo:nil]
            NSInteger result = [NSApp runModalForWindow:configSheet]
            [NSApp endSheet:configSheet]
            [configSheet orderOut:self]
            if (result == NSOKButton)
            {
                String tmpfilec[17]; strcpy (tmpfilec, "/tmp/sane.XXXXXX"); close (mkstemp (tmpfilec))
                NSString * tmpfile = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:tmpfilec length:16]
                [[[[configEditor textStorage] mutableString] dataUsingEncoding:NSUTF8StringEncoding] writeToFile:tmpfile atomically:NO]
                [self authorizedFileMoveFrom:tmpfile to:conffile setRoot:YES force:YES]
            }
            [[[configEditor textStorage] mutableString] setString:@""]
        }
        if ([sender clickedColumn] == [sender columnWithIdentifier:@"firmware"])
        {
            NSString * firmwaredir = [NSString stringWithFormat:@"%@%@%@%@", SANEInstallDir, @"/share/sane/", [availBackends objectAtIndex:[sender clickedRow]], @"/"]
            [firmwareDir setStringValue:firmwaredir]
            NSDirectoryEnumerator * dir = [[NSFileManager defaultManager] enumeratorAtPath:firmwaredir]
            NSString * file
            while (file = [dir nextObject])
                if ([[[dir fileAttributes] objectForKey:NSFileType] isEqualTo:NSFileTypeRegular])
                    [availFirmwares addObject:file]
            [firmwares reloadData]
            [firmwares registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]]
            [NSApp beginSheet:firmwareSheet modalForWindow:[NSApp mainWindow] modalDelegate:nil didEndSelector:nil contextInfo:nil]
            [NSApp runModalForWindow:firmwareSheet]
            [NSApp endSheet:firmwareSheet]
            [firmwareSheet orderOut:self]
            [availFirmwares removeAllObjects]
        }
        if ([sender clickedColumn] == [sender columnWithIdentifier:@"help"])
        {
            NSTask * task = [[NSTask alloc] init]
            [task setLaunchPath:@"/usr/bin/groff"]
            NSString * manfile = [NSString stringWithFormat:@"%@%@%@%@", SANEInstallDir, @"/share/man/man5/sane-", [availBackends objectAtIndex:[sender clickedRow]], @".5"]
            NSMutableArray * args = [NSMutableArray array]
            [args addObject:@"-Thtml"]
            [args addObject:@"-man"]
            [args addObject:manfile]
            [task setArguments:args]
            String tmpfilec[22]; strcpy (tmpfilec, "/tmp/sane.XXXXXX.html"); Int fd = mkstemps (tmpfilec, 5)
            NSString * tmpfile = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:tmpfilec length:21]
            [task setStandardOutput:[[NSFileHandle alloc] initWithFileDescriptor:fd closeOnDealloc:YES]]
            [task launch]
            [task waitUntilExit]
            NSURL * url = [NSURL fileURLWithPath:tmpfile]
            LSOpenCFURLRef ((__bridge CFURLRef) url, nil)
        }
    }
}

- (IBAction) popUpButtonCellPressed:(id) sender
{
    if (sender == users)
    {
        if ([sender clickedColumn] == [sender columnWithIdentifier:@"backend"])
        {
            // void - handled in tableView:setObjectValue:forTableColumn:row:
        }
    }
}

@end
