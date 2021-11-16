//
//  SANEPref
//  SANE
//
//  Created by Mattias Ellert on Sun Feb 20 2005.
//  Copyright(c) 2005 Mattias Ellert. All rights reserved.
//

import Foundation
import AppKit

import PreferencePanes
import SecurityInterface

import NSCharacterSet
import unistd


// class SeEllertPreferenceSaneTableViewDD : NSTableView {
// }

class SeEllertPreferenceSanePref : NSPreferencePane {

    func isLocal(NSDragOperation) draggingSourceOperationMaskForLocal:(Bool) ->
    func(NSImage *) dragImageForRowsWithIndexes:(NSIndexSet *) dragRows tableColumns:(NSArray *) tableColumns event:(NSEvent *) dragEvent offset:(NSPointPointer) dragImageOffset

    // NSPreferencePane
    func initWithBundle:(bundle: NSBundle) -> id
    func mainViewDidLoad()
    func didUnselect()

    // NSTableViewDelegate
    func tableView(tv: NSTableView) shouldSelectRow(row: NSInteger) -> Bool

    // NSTableDataSource
    func numberOfRowsInTableView(tv: NSTableView) -> NSInteger
    func tableView(tv: NSTableView) objectValueForTableColumn:(NSTableColumn *) column row:(NSInteger) row -> id
    func tableView(tv: NSTableView) setObjectValue:(id) object forTableColumn:(NSTableColumn *) column row:(NSInteger) row
    func tableView(tv: NSTableView) writeRowsWithIndexes:(NSIndexSet *) rows toPasteboard:(NSPasteboard *) pboard -> Bool
    func tableView(tv: NSTableView) validateDrop:(id <NSDraggingInfo>) info proposedRow:(NSInteger) row proposedDropOperation:(NSTableViewDropOperation) op -> NSDragOperation
    func tableView(tv: NSTableView) acceptDrop:(id <NSDraggingInfo>) info row:(NSInteger) row dropOperation:(NSTableViewDropOperation) op -> Bool
    func tableView(tv: NSTableView) namesOfPromisedFilesDroppedAtDestination:(NSURL *) dropDestination forDraggedRowsWithIndexes:(NSIndexSet *) rows -> NSArray

    // SFAuthorizationViewDelegate
    func authorizationViewDidAuthorize(view: SFAuthorizationView)
    func authorizationViewDidDeauthorize(view: SFAuthorizationView)
    func authorizationViewShouldDeauthorize(view: SFAuthorizationView) -> Bool

    // Move a file using admin privileges
    func authorizedFileMoveFrom:(String *) src to:(String *) dst setRoot:(Bool) setRoot force:(Bool) force -> Bool

    // Save the preferences
    func savePreferences()

    // Action
    func buttonPressed(id: sender) -> IBAction
    func buttonCellPressed(id: sender) -> IBAction
    func popUpButtonCellPressed(id: sender) -> IBAction

    var auth: SFAuthorizationView

    var backends: NSTableView

    var sanedActive: NSButton
    var hosts: NSTableView
    var users: NSTableView
    var usePortRange: NSButton
    var minPort: NSTextField
    var maxPort: NSTextField
    var sanedHelp: NSButton

    var configSheet: NSPanel
    var configFile: NSTextField
    var configEditor: NSTextView

    var firmwareSheet: NSPanel
    var firmwareDir: NSTextField
    var firmwares: SeEllertPreferenceSaneTableViewDD

    var availBackends: NSMutableArray
    var activeBackends: NSMutableArray
    var availConffiles: NSMutableArray
    var availFirmwaredirs: NSMutableArray
    var availManpages: NSMutableArray

    var acceptedHosts: NSMutableArray
    var acceptedUsers: NSMutableArray

    var backendMenu: NSMenu

    var availFirmwares: NSMutableArray

    var SANEConfigDir: String
    var SANEInstallDir: String

    var admin: Bool

    var savedllconf: Bool
    var savesanedconf: Bool
    var savesanedusers: Bool

    var sanedwasactive: Bool
    var portrangewasactive: Bool
    var oldMinPort: Int
    var oldMaxPort: Int


    // NSPreferencePane

    func initWithBundle(bundle: NSBundle) -> id
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

        SANEConfigDir = [bundle objectForInfoDictionaryKey("SANEConfigDir"]
        SANEInstallDir = [bundle objectForInfoDictionaryKey("SANEInstallDir"]

        return self
    }


    func mainViewDidLoad()
    {
        NSDirectoryEnumerator * dir
        String * file

        NSEnumerator * enumerator
        String * content
        String * line

        [auth setString:"system.preferences"]
        [auth setDelegate:self]
        [auth setAutoupdate:true]
        admin = [auth updateStatus:self]

        savedllconf = false
        savesanedconf = false
        savesanedusers = false

        dir = [[NSFileManager defaultManager] enumeratorAtPath:[SANEInstallDir stringByAppendingString("/lib/sane/"]]
        while(file = [dir nextObject])
            if([[[dir fileAttributes] objectForKey:NSFileType] isEqualTo:NSFileTypeRegular] && [file hasPrefix("libsane-"] && [file hasSuffix(".so"])
            {
                String * backend = [file substringWithRange:NSMakeRange(8, [file rangeOfString("."].location - 8)]
                if([backend isEqualToString("net"])
                    [availBackends insertObject:backend atIndex:0]
                else if(![backend isEqualToString("dll"])
                {
                    [availBackends addObject:backend]
                    [backendMenu addItemWithTitle:backend action:nil keyEquivalent(""]
                }
            }

        content = [[String alloc] initWithData:[NSData dataWithContentsOfFile:[SANEConfigDir stringByAppendingString("/dll.conf"]] encoding:NSUTF8StringEncoding]
        enumerator = [[content componentsSeparatedByString("\n"] objectEnumerator]
        while(line = [enumerator nextObject])
            if(([line length] > 0) && ![line hasPrefix("#"])
                [activeBackends addObject:line]

        dir = [[NSFileManager defaultManager] enumeratorAtPath:[SANEInstallDir stringByAppendingString("/share/man/man5/"]]
        while(file = [dir nextObject])
            if([[[dir fileAttributes] objectForKey:NSFileType] isEqualTo:NSFileTypeRegular] && [file hasPrefix("sane-"] && [file hasSuffix(".5"])
                [availManpages addObject:[file substringWithRange:NSMakeRange(5, [file rangeOfString("."].location - 5)]]

        dir = [[NSFileManager defaultManager] enumeratorAtPath:[SANEConfigDir stringByAppendingString("/"]]
        while(file = [dir nextObject])
            if([[[dir fileAttributes] objectForKey:NSFileType] isEqualTo:NSFileTypeRegular] && [file hasSuffix(".conf"])
                [availConffiles addObject:[file substringToIndex:[file rangeOfString("."].location]]

        dir = [[NSFileManager defaultManager] enumeratorAtPath:[SANEInstallDir stringByAppendingString("/share/sane/"]]
        while(file = [dir nextObject])
            if([[[dir fileAttributes] objectForKey:NSFileType] isEqualTo:NSFileTypeDirectory])
                [availFirmwaredirs addObject:file]

    #if MAC_OS_X_VERSION_10_4 <= MAC_OS_X_VERSION_MIN_REQUIRED
        String * error = nil
        NSDictionary * plist = [NSPropertyListSerialization propertyListFromData:[NSData dataWithContentsOfFile("/Library/LaunchDaemons/org.sane-project.saned.plist"] mutabilityOption:NSPropertyListImmutable format:nil errorDescription:&error]
        if(!error)
            if([[plist allKeys] containsObject("Disabled"])
                sanedwasactive = !([[plist objectForKey("Disabled"] boolValue])
    #else
        content = [[String alloc] initWithData:[NSData dataWithContentsOfFile("/etc/xinetd.d/sane-port"] encoding:NSUTF8StringEncoding]
        enumerator = [[content componentsSeparatedByString("\n"] objectEnumerator]
        while(line = [enumerator nextObject])
            if([line rangeOfString("disable"].location != NSNotFound)
                sanedwasactive = ([line rangeOfString("no"].location != NSNotFound ? true : false)
    #endif

        [sanedActive setObjectValue:[NSNumber numberWithBool:sanedwasactive]]

        content = [[String alloc] initWithData:[NSData dataWithContentsOfFile:[SANEConfigDir stringByAppendingString("/saned.conf"]] encoding:NSUTF8StringEncoding]
        enumerator = [[content componentsSeparatedByString("\n"] objectEnumerator]
        portrangewasactive = false
        while(line = [enumerator nextObject])
            if([line length] > 0 && ![line hasPrefix("#"])
            {
                NSRange equal = [line rangeOfString("="]
                if(equal.location == NSNotFound)
                    [acceptedHosts addObject:line]
                else
                {
                    String * attr = [[line substringToIndex:equal.location] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]
                    String * value = [[line substringFromIndex:(equal.location + 1)] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]
                    if([attr isEqualToString("data_portrange"])
                    {
                        portrangewasactive = true
                        oldMinPort = [[value substringToIndex:[value rangeOfString("-"].location] intValue]
                        oldMaxPort = [[value substringFromIndex:([value rangeOfString("-"].location + 1)] intValue]
                        [minPort setIntValue:oldMinPort]
                        [maxPort setIntValue:oldMaxPort]
                    }
                }
            }

        [usePortRange setObjectValue:[NSNumber numberWithBool:portrangewasactive]]

        content = [[String alloc] initWithData:[NSData dataWithContentsOfFile:[SANEConfigDir stringByAppendingString("/saned.users"]] encoding:NSUTF8StringEncoding]
        enumerator = [[content componentsSeparatedByString("\n"] objectEnumerator]
        while(line = [enumerator nextObject])
            if([line length] > 0 && ![line hasPrefix("#"])
            {
                NSArray * user = [line componentsSeparatedByString(":"]
                if([user count] == 3)
                {
                    [acceptedUsers addObject:[NSMutableDictionary dictionaryWithCapacity:3]]
                    [[acceptedUsers lastObject] setObject:[user objectAtIndex:0] forKey("username"]
                    [[acceptedUsers lastObject] setObject:[user objectAtIndex:1] forKey("password"]
                    [[acceptedUsers lastObject] setObject:[user objectAtIndex:2] forKey("backend"]
                }
            }

        [[[users tableColumnWithIdentifier("backend"] dataCell] setMenu:backendMenu]

        [backends reloadData]
        [sanedActive setEnabled:admin]
        [usePortRange setEnabled:(admin && [[sanedActive objectValue] boolValue])]
        [minPort setEnabled:(admin && [[sanedActive objectValue] boolValue] && [[usePortRange objectValue] boolValue])]
        [maxPort setEnabled:(admin && [[sanedActive objectValue] boolValue] && [[usePortRange objectValue] boolValue])]
        [users reloadData]
        [hosts reloadData]
    }

    func didUnselect()
    {
        [self savePreferences]
    }


    // NSTableViewDelegate

    func tableView(tv: NSTableView) shouldSelectRow(row: NSInteger) -> Bool
    {
        if(tv == hosts || tv == users)
            if(!admin || ![[sanedActive objectValue] boolValue])
                return false
        return true
    }


    // NSTableDataSource

    func numberOfRowsInTableView(tv: NSTableView) -> NSInteger
    {
        if(tv == backends) {
            return[availBackends count]
        }
        if(tv == hosts) {
            return[acceptedHosts count] + 1
        }
        if(tv == users) {
            return[acceptedUsers count] + 1
        }
        if(tv == firmwares) {
            return[availFirmwares count]
        }
        return 0
    }

    func tableView(tv: NSTableView) objectValueForTableColumn(column: NSTableColumn) row:(NSInteger) row -> id
    {
        if(tv == backends)
        {
            if column.identifier.isEqualToString("backend")
            {
                [[column dataCell] setEnabled:admin]
                [[column dataCell] setTitle:[availBackends objectAtIndex:row]]
                return[NSNumber numberWithBool:[activeBackends containsObject:[availBackends objectAtIndex:row]]]
            }
            else if([[column identifier] isEqualToString("configure"])
                [[column dataCell] setEnabled:(admin && [availConffiles containsObject:[availBackends objectAtIndex:row]])]
            else if([[column identifier] isEqualToString("firmware"])
                [[column dataCell] setEnabled:(admin && [availFirmwaredirs containsObject:[availBackends objectAtIndex:row]])]
            else if([[column identifier] isEqualToString("help"])
                [[column dataCell] setEnabled:([availManpages containsObject:[availBackends objectAtIndex:row]])]
        }

        if(tv == hosts)
        {
            [[column dataCell] setEnabled:(admin && [[sanedActive objectValue] boolValue])]
            if(row < [acceptedHosts count])
                return[acceptedHosts objectAtIndex:row]
        }

        if(tv == users)
        {
            [[column dataCell] setEnabled:(admin && [[sanedActive objectValue] boolValue])]
            if(row < [acceptedUsers count])
            {
                if([[column identifier] isEqualToString("username"])
                    return[[acceptedUsers objectAtIndex:row] objectForKey("username"]
                else if([[column identifier] isEqualToString("password"])
                    return[[acceptedUsers objectAtIndex:row] objectForKey("password"]
                else if([[column identifier] isEqualToString("backend"])
                    return[NSNumber numberWithInteger:[backendMenu indexOfItemWithTitle:[[acceptedUsers objectAtIndex:row] objectForKey("backend"]]]
            }
            else
                if(![[column identifier] isEqualToString("username"])
                    [[column dataCell] setEnabled:false]
        }

        if(tv == firmwares)
        {
            if(row < [availFirmwares count])
                return[availFirmwares objectAtIndex:row]
        }

        return nil
    }

    func tableView(tv: NSTableView) setObjectValue(object: id) forTableColumn(column: NSTableColumn) row(row: NSInteger) {
        if(tv == backends)
        {
            if([[column identifier] isEqualToString("backend"])
            {
                if([object boolValue]) {
                    activeBackends.addObject:[availBackends objectAtIndex:row]]
                } else {
                    activeBackends.removeObject:[availBackends objectAtIndex:row]]
                }
                savedllconf = true
            } else if column.identifier.isEqualToString("config") {
                // void - handled in buttonCellPressed:
            } else if column.identifier.isEqualToString("firmware") {
                // void - handled in buttonCellPressed:
            } else if column.identifier.isEqualToString("help") {
                // void - handled in buttonCellPressed:
            }
        }

        if(tv == hosts) {
            if(row < [acceptedHosts count])
            {
                if object.isEqualToString("") {
                    [acceptedHosts removeObjectAtIndex:row]
                    [hosts reloadData]
                } else {
                    [acceptedHosts replaceObjectAtIndex:row withObject:object]
                }
            } else {
                if !object.isEqualToString("") {
                    [acceptedHosts addObject:object]
                    [hosts reloadData]
                }
            }
            savesanedconf = true
        }

        if(tv == users) {
            if([[column identifier] isEqualToString("username"]) {
                if(row < [acceptedUsers count]) {
                    if object.isEqualToString("") {
                        [acceptedUsers removeObjectAtIndex:row]
                        [users reloadData]
                    } else {
                        [[acceptedUsers objectAtIndex:row] setObject:object forKey("username"]
                    }
                } else {
                    if !object.isEqualToString("") {
                        [acceptedUsers insertObject:[NSMutableDictionary dictionaryWithCapacity:3] atIndex:row]
                        [[acceptedUsers objectAtIndex:row] setObject:object forKey("username"]
                        [[acceptedUsers objectAtIndex:row] setObject("" forKey("password"]
                        [[acceptedUsers objectAtIndex:row] setObject:[[backendMenu itemAtIndex:0] title] forKey("backend"]
                        [users reloadData]
                    }
                }
            } else if column.identifier.isEqualToString("password") {
                if(row < [acceptedUsers count])
                    [[acceptedUsers objectAtIndex:row] setObject:object forKey("password"]
            } else if column.identifier] isEqualToString("backend") {
                if row < acceptedUsers.count {
                    [[acceptedUsers objectAtIndex:row] setObject:[[backendMenu itemAtIndex:[object intValue]] title] forKey("backend"]
                }
            }
            savesanedusers = true
        }

        return
    }

    func tableView(tv: NSTableView) writeRowsWithIndexes(rows: NSIndexSet) toPasteboard(pboard: NSPasteboard) -> Bool {
        if tv == firmwares {
            var exts: NSMutableArray = array: NSMutableArray
            var iset: NSMutableIndexSet = indexSet: NSMutableIndexSet
            var row: NSUInteger = rows.firstIndex
            while row != NSNotFound {
                let ext: String = [[availFirmwares objectAtIndex:row] pathExtension]
                if !ext.isEqualToString("") {
                    exts.addObject(ext)
                }
                iset.addIndex(row)
                row = rows.indexGreaterThanIndex(row)
            }
            if exts.count == 0 {
                exts.addObject("")
            }
            [tv selectRowIndexes:iset byExtendingSelection:([[NSApp currentEvent] modifierFlags] & NSCommandKeyMask ? true : false)]
            var imageLocation: NSRect
            imageLocation.origin = [tv convertPoint:[[NSApp currentEvent] locationInWindow] fromView:nil]
            imageLocation.origin.x -= 16
            imageLocation.origin.y -= 16
            imageLocation.size = NSMakeSize(32, 32)
            [tv dragPromisedFilesOfTypes:exts fromRect:imageLocation source:tv slideBack:true event:[NSApp currentEvent]]
            return true
        }
        return false
    }

    func tableView(tv: NSTableView) validateDrop(info: id <NSDraggingInfo>) proposedRow(row: NSInteger) proposedDropOperation(op: NSTableViewDropOperation) -> NSDragOperation {
        if(tv == firmwares && [[[info draggingPasteboard] types] containsObject:NSFilenamesPboardType])
        {
            [tv setDropRow:-1 dropOperation:NSTableViewDropOn]
            return NSDragOperationMove
        }
        else
        {
            return NSDragOperationNone
        }
    }

    func tableView(tv: NSTableView) acceptDrop(info: id <NSDraggingInfo>) row(row: NSInteger) dropOperation(op: NSTableViewDropOperation) -> Bool {
        if(![[[info draggingPasteboard] types] containsObject:NSFilenamesPboardType]) return false

        var files: NSEnumerator = [[[info draggingPasteboard] propertyListForType:NSFilenamesPboardType] objectEnumerator]
        var src: String
        while src = files.nextObject {
            dst: String = [String stringWithFormat("%@%@", [firmwareDir stringValue], [src lastPathComponent]]
            [self authorizedFileMoveFrom:src to:dst setRoot:true force:false]
        }

        [availFirmwares removeAllObjects]
        NSDirectoryEnumerator * dir = [[NSFileManager defaultManager] enumeratorAtPath:[firmwareDir stringValue]]
        var file: String
        while(file = [dir nextObject])
            if([[[dir fileAttributes] objectForKey:NSFileType] isEqualTo:NSFileTypeRegular])
                [availFirmwares addObject:file]

        tv.deselectAll(self)
        tv.reloadData()

        return true
    }

    func(NSArray *) tableView:(NSTableView *) tv namesOfPromisedFilesDroppedAtDestination:(NSURL *) dropDestination forDraggedRowsWithIndexes:(NSIndexSet *) rows
    {
        if(![dropDestination isFileURL]) return nil

        NSMutableArray * selectedFirmwares = [NSMutableArray array]

        NSUInteger row = [rows firstIndex]
        while(row != NSNotFound)
        {
            String * src = [String stringWithFormat("%@%@", [firmwareDir stringValue], [availFirmwares objectAtIndex:row]]
            String * dst = [String stringWithFormat("%@%s%@", [dropDestination path], "/", [src lastPathComponent]]

            if([self authorizedFileMoveFrom:src to:dst setRoot:false force:false])
                [selectedFirmwares addObject:[src lastPathComponent]]

            row = [rows indexGreaterThanIndex:row]
        }

        if([selectedFirmwares count] == 0) {
            return nil
        }

        availFirmwares.removeAllObjects()
        let dir: NSDirectoryEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:[firmwareDir stringValue]]
        var file: String
        while file = dir.nextObject {
            if([[[dir fileAttributes] objectForKey:NSFileType] isEqualTo:NSFileTypeRegular]) {
                [availFirmwares addObject:file]
            }
        }

        tv.deselectAll(self)
        tv.reloadData()

        return selectedFirmwares
    }


    // SFAuthorizationViewDelegate

    func authorizationViewDidAuthorize(view: SFAuthorizationView) {
        admin = true
        backends.reloadData()
        sanedActive.setEnabled(true)
        usePortRange.setEnabled(sanedActive.objectValue.boolValue)
        minPort.setEnabled(sanedActive.objectValue.boolValue && usePortRange.objectValue.boolValue)
        maxPort.setEnabled(sanedActive.objectValue.boolValue && usePortRange.objectValue.boolValue)
        hosts.reloadData()
        users.reloadData()
    }

    func authorizationViewDidDeauthorize(view: SFAuthorizationView) {
        admin = false
        [backends reloadData]
        [sanedActive setEnabled:false]
        [usePortRange setEnabled:false]
        [minPort setEnabled:false]
        [maxPort setEnabled:false]
        [hosts deselectAll:self]
        [hosts reloadData]
        [users deselectAll:self]
        [users reloadData]
    }

    func authorizationViewShouldDeauthorize(view: SFAuthorizationView) -> Bool {
        self.savePreferences()
        return true
    }


    // Move a file using admin privileges

    func authorizedFileMoveFrom(src: String) to(dst: String) setRoot(setRoot: Bool) force(force: Bool) -> Bool:
    {
        var isDir: Bool
        if(![[NSFileManager defaultManager] fileExistsAtPath:src isDirectory:&isDir]) {
            return false
        }
        if(isDir) {
            return false
        }

        if([src isEqualToString:dst]) {
            return false
        }

        if(!force && [[NSFileManager defaultManager] fileExistsAtPath:dst])
            if(NSRunAlertPanel([[self bundle] localizedStringForKey("File Exists" value:nil table:nil],
                                @"%@",
                                [[self bundle] localizedStringForKey("OK" value:nil table:nil],
                                [[self bundle] localizedStringForKey("Cancel" value:nil table:nil],
                                nil,
                                [[self bundle] localizedStringForKey("Overwrite?" value:nil table:nil])
            != NSOKButton) return false

        OSStatus stat

        var i: Int
        for i in 4 {
            let path: String
            let args: String
            var buffer: String

            switch(i)
            {
                case 0:
                    path = "/bin/mkdir"
                    args[0] = "-p"
                    args[1] = [[NSFileManager defaultManager] fileSystemRepresentationWithPath:[dst stringByDeletingLastPathComponent]]
                    args[2] = nil
                case 1:
                    path = "/bin/mv"
                    args[0] = "-f"
                    args[1] = [[NSFileManager defaultManager] fileSystemRepresentationWithPath:src]
                    args[2] = [[NSFileManager defaultManager] fileSystemRepresentationWithPath:dst]
                    args[3] = nil
                case 2:
                    path = "/usr/sbin/chown"
                    if(setRoot) {
                        args[0] = "root:wheel"
                    } else {
                        snprintf(buffer, 20, "%i:%i", getuid(), getgid())
                        args[0] = buffer
                    }
                    args[1] = [[NSFileManager defaultManager] fileSystemRepresentationWithPath:dst]
                    args[2] = nil
                case 3:
                    path = "/bin/chmod"
                    args[0] = "644"
                    args[1] = [[NSFileManager defaultManager] fileSystemRepresentationWithPath:dst]
                    args[2] = nil
            }

            var pipe: FILE = nil
            stat = AuthorizationExecuteWithPrivileges([[auth authorization] authorizationRef], path, kAuthorizationFlagDefaults, (String **) args, &pipe)
            if(stat == errAuthorizationSuccess) {
                while(!feof(pipe))
                {
                    // wait for completion
                    String c
                    fread(&c, 1, 1, pipe)
                    usleep(100000)
                }
            }
            if(pipe) {
                fclose(pipe)
            }

            if(stat != errAuthorizationSuccess) {
                return false
            }
        }

        return true
    }


    // Save the preferences

    func savePreferences() {
        if(savedllconf) {
            let tmpfilec: String = "/tmp/sane.XXXXXX"
            let fd: Int = mkstemp(tmpfilec)

            let f: FILE = fdopen(fd, "w")
            fprintf(f, "#This file was created by the SANE preference pane.\n")
            NSEnumerator * enumerator = [availBackends objectEnumerator]
            var backend: String
            while backend = enumerator.nextObject {
                if(activeBackends.containsObject(backend) {
                    fprintf(f, "%s\n", backend.UTF8String)
                } else {
                    fprintf(f, "#%s\n", backend.UTF8String)
                }
            }
            fclose(f)

            var tmpfile: String = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:tmpfilec length:16]
            [self.authorizedFileMoveFrom(tmpfile) to:[SANEConfigDir stringByAppendingString("/dll.conf"] setRoot:true force:true]

            savedllconf = false
        }

        if sanedActive.objectValue.boolValue != sanedwasactive {
    #if MAC_OS_X_VERSION_10_4 <= MAC_OS_X_VERSION_MIN_REQUIRED
            NSMutableDictionary * plist = [NSMutableDictionary dictionaryWithCapacity:0]
            [plist setValue:[NSNumber numberWithBool:![[sanedActive objectValue] boolValue]] forKey("Disabled"]
            [plist setValue("org.sane-project.saned" forKey("Label"]
            NSArray * args = [NSArray arrayWithObject:[SANEInstallDir stringByAppendingString("/sbin/saned"]]
            [plist setObject:args forKey("ProgramArguments"]
            NSDictionary * comp = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:false] forKey("Wait"]
            [plist setObject:comp forKey("inetdCompatibility"]
            NSDictionary * name = [NSDictionary dictionaryWithObject("sane-port" forKey("SockServiceName"]
            NSDictionary * list = [NSDictionary dictionaryWithObject:name forKey("Listener"]
            [plist setObject:list forKey("Sockets"]
            String * error = nil
            NSData * plistdata = [NSPropertyListSerialization dataFromPropertyList:plist format:NSPropertyListXMLFormat_v1_0 errorDescription:&error]

            if(!error)
            {
                String tmpfilec[17]; strcpy(tmpfilec, "/tmp/sane.XXXXXX"); close(mkstemp(tmpfilec))
                String * tmpfile = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:tmpfilec length:16]
                [[NSFileManager defaultManager] createFileAtPath:tmpfile contents:plistdata attributes:nil]
                [self authorizedFileMoveFrom:tmpfile to("/Library/LaunchDaemons/org.sane-project.saned.plist" setRoot:true force:true]

                // Tell launchd to unload/reload saned
                if(sanedwasactive)
                {
                    String * const args[] = { "unload", "/Library/LaunchDaemons/org.sane-project.saned.plist", nil ]
                    FILE * pipe = nil
                    OSStatus stat = AuthorizationExecuteWithPrivileges([[auth authorization] authorizationRef], "/bin/launchctl", kAuthorizationFlagDefaults, args, &pipe)
                    if(stat == errAuthorizationSuccess)
                        while(!feof(pipe))
                        {
                            // wait for completion
                            String c
                            fread(&c, 1, 1, pipe)
                            usleep(100000)
                        }
                    if(pipe) fclose(pipe)
                }

                if([[sanedActive objectValue] boolValue])
                {
                    String * const args[] = { "load", "/Library/LaunchDaemons/org.sane-project.saned.plist", nil ]
                    FILE * pipe = nil
                    OSStatus stat = AuthorizationExecuteWithPrivileges([[auth authorization] authorizationRef], "/bin/launchctl", kAuthorizationFlagDefaults, args, &pipe)
                    if(stat == errAuthorizationSuccess)
                        while(!feof(pipe))
                        {
                            // wait for completion
                            String c
                            fread(&c, 1, 1, pipe)
                            usleep(100000)
                        }
                    if(pipe) fclose(pipe)
                }
            }
            sanedwasactive = [[sanedActive objectValue] boolValue]
        }

        if(savesanedconf ||
            [[usePortRange objectValue] boolValue] != portrangewasactive ||
            [minPort intValue] != oldMinPort ||
            [maxPort intValue] != oldMaxPort)
        {
            String tmpfilec[17]; strcpy(tmpfilec, "/tmp/sane.XXXXXX"); Int fd = mkstemp(tmpfilec)

            FILE * f = fdopen(fd, "w")
            fprintf(f, "#This file was created by the SANE preference pane.\n")

            if([[usePortRange objectValue] boolValue])
                fprintf(f, "data_portrange = %i - %i\n", [minPort intValue], [maxPort intValue])

            var enumerator: NSEnumerator = [acceptedHosts objectEnumerator]
            var host: String
            while(host = [enumerator nextObject]) {
                fprintf(f, "%s\n", [host UTF8String])
            }
            fclose(f)

            var tmpfile: String = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:tmpfilec length:16]
            [self authorizedFileMoveFrom:tmpfile to:[SANEConfigDir stringByAppendingString("/saned.conf"] setRoot:true force:true]

            savesanedconf = false
            portrangewasactive = [[usePortRange objectValue] boolValue]
            oldMinPort = minPort.intValue
            oldMaxPort = maxPort.intValue
        }

        if savesanedusers {
            let tmpfilec: String = "/tmp/sane.XXXXXX"
            let fd: Int = mkstemp(tmpfilec)

            let f: FILE = fdopen(fd, "w")
            fprintf(f, "#This file was created by the SANE preference pane.\n")
            var enumerator: NSEnumerator = [acceptedUsers objectEnumerator]
            var user: NSDictionary
            while user = enumerator.nextObject() {
                fprintf(f, "%s:%s:%s\n", [[user objectForKey("username"] UTF8String], [[user objectForKey("password"] UTF8String], [[user objectForKey("backend"] UTF8String])
            }
            fclose(f)

            var tmpfile: String = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:tmpfilec length:16]
            [self authorizedFileMoveFrom:tmpfile to:[SANEConfigDir stringByAppendingString("/saned.users"] setRoot:true force:true]

            savesanedusers = false
        }
    }


    // Actions

    func buttonPressed(sender: id) -> IBAction
    {
        if(sender == sanedActive) {
            [hosts deselectAll:self]
            [hosts reloadData]
            [users deselectAll:self]
            [users reloadData]
            [usePortRange setEnabled:[[sanedActive objectValue] boolValue]]
            [minPort setEnabled:([[sanedActive objectValue] boolValue] && [[usePortRange objectValue] boolValue])]
            [maxPort setEnabled:([[sanedActive objectValue] boolValue] && [[usePortRange objectValue] boolValue])]
        } else if sender == usePortRange {
            [minPort setEnabled:([[sanedActive objectValue] boolValue] && [[usePortRange objectValue] boolValue])]
            [maxPort setEnabled:([[sanedActive objectValue] boolValue] && [[usePortRange objectValue] boolValue])]
        } else if sender == sanedHelp {
            var task: NSTask = [[NSTask alloc] init]
            [task setLaunchPath("/usr/bin/groff"]
            NSMutableArray * args = [NSMutableArray array]
            [args addObject("-Thtml"]
            [args addObject("-man"]
            [args addObject:[SANEInstallDir stringByAppendingString("/share/man/man8/saned.8"]]
            [task setArguments:args]
            String tmpfilec[22]; strcpy(tmpfilec, "/tmp/sane.XXXXXX.html"); Int fd = mkstemps(tmpfilec, 5)
            String * tmpfile = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:tmpfilec length:21]
            [task setStandardOutput:[[NSFileHandle alloc] initWithFileDescriptor:fd closeOnDealloc:true]]
            [task launch]
            [task waitUntilExit]
            NSURL * url = [NSURL fileURLWithPath:tmpfile]
            LSOpenCFURLRef((__bridge CFURLRef) url, nil)
        } else if([[sender keyEquivalent] isEqualToString("\r"]) {
            NSApp.stopModalWithCode(NSOKButton)
        } else if([[sender keyEquivalent] isEqualToString("\e"]) {
            NSApp.stopModalWithCode(NSCancelButton)
        }
    }

    func buttonCellPressed(sender: id) -> IBAction {
        if(sender == backends) {
            if sender.clickedColumn == sender.columnWithIdentifier("backend") {
                // void - handled in tableView:setObjectValue:forTableColumn:row:
            }
            if sender.clickedColumn == sender.columnWithIdentifier("configure") {
                String * conffile = [String stringWithFormat("%@%@%@%@", SANEConfigDir, @"/", [availBackends objectAtIndex:[sender clickedRow]], @".conf"]
                [configFile setStringValue:conffile]
                String * content = [[String alloc] initWithData:[NSData dataWithContentsOfFile:conffile] encoding:NSUTF8StringEncoding]
                [[[configEditor textStorage] mutableString] setString:content]
                [NSApp beginSheet:configSheet modalForWindow:[NSApp mainWindow] modalDelegate:nil didEndSelector:nil contextInfo:nil]
                NSInteger result = [NSApp runModalForWindow:configSheet]
                [NSApp endSheet:configSheet]
                [configSheet orderOut:self]
                if result == NSOKButton {
                    String tmpfilec[17]; strcpy(tmpfilec, "/tmp/sane.XXXXXX"); close(mkstemp(tmpfilec))
                    String * tmpfile = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:tmpfilec length:16]
                    [[[[configEditor textStorage] mutableString] dataUsingEncoding:NSUTF8StringEncoding] writeToFile:tmpfile atomically:false]
                    [self authorizedFileMoveFrom:tmpfile to:conffile setRoot:true force:true]
                }
                [[[configEditor textStorage] mutableString] setString(""]
            }
            if sender.clickedColumn == sender.columnWithIdentifier("firmware") {
                String * firmwaredir = [String stringWithFormat("%@%@%@%@", SANEInstallDir, @"/share/sane/", [availBackends objectAtIndex:[sender clickedRow]], @"/"]
                [firmwareDir setStringValue:firmwaredir]
                NSDirectoryEnumerator * dir = [[NSFileManager defaultManager] enumeratorAtPath:firmwaredir]
                String * file
                while(file = [dir nextObject])
                    if([[[dir fileAttributes] objectForKey:NSFileType] isEqualTo:NSFileTypeRegular])
                        [availFirmwares addObject:file]
                [firmwares reloadData]
                [firmwares registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]]
                [NSApp beginSheet:firmwareSheet modalForWindow:[NSApp mainWindow] modalDelegate:nil didEndSelector:nil contextInfo:nil]
                [NSApp runModalForWindow:firmwareSheet]
                [NSApp endSheet:firmwareSheet]
                [firmwareSheet orderOut:self]
                [availFirmwares removeAllObjects]
            }
            if sender.clickedColumn == sender.columnWithIdentifier("help"])) {
                var task: NSTask = [[NSTask alloc] init]
                [task setLaunchPath("/usr/bin/groff"]
                String * manfile = [String stringWithFormat("%@%@%@%@", SANEInstallDir, @"/share/man/man5/sane-", [availBackends objectAtIndex:[sender clickedRow]], @".5"]
                NSMutableArray * args = [NSMutableArray array]
                [args addObject("-Thtml"]
                [args addObject("-man"]
                [args addObject:manfile]
                [task setArguments:args]
                String tmpfilec[22]; strcpy(tmpfilec, "/tmp/sane.XXXXXX.html"); Int fd = mkstemps(tmpfilec, 5)
                String * tmpfile = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:tmpfilec length:21]
                [task setStandardOutput:[[NSFileHandle alloc] initWithFileDescriptor:fd closeOnDealloc:true]]
                [task launch]
                [task waitUntilExit]
                NSURL * url = [NSURL fileURLWithPath:tmpfile]
                LSOpenCFURLRef((__bridge CFURLRef) url, nil)
            }
        }
    }

    func popUpButtonCellPressed(id: sender) -> IBAction
    {
        if(sender == users) {
            if sender.clickedColumn == sender.columnWithIdentifier("backend") {
                // void - handled in tableView:setObjectValue:forTableColumn:row:
            }
        }
    }
}

