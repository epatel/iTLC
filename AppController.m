//
//  AppController.m
//  iTLC
//
//  Created by Edward Patel on 2007-11-15.
//  Copyright 2007 Memention AB. All rights reserved.
//

#import "AppController.h"
#import "BRByteFormatter.h"


@implementation AppController

- (id)init
{
	if (self = [super init]) {
		extraFiles = [[NSMutableArray alloc] init];
		extraFilesSizes = [[NSMutableArray alloc] init];
		missingFiles = [[NSMutableArray alloc] init];
		hasExtraFiles = NO;
	}
	return self;
}

- (void)dealloc
{
	[extraFiles release];
	[extraFilesSizes release];
	[missingFiles release];
	[timer release];
	[super dealloc];
}

- (IBAction)startProcessing:(id)sender
{
	if (!isProcessing && !timer) {
		[label setHidden:NO];
		[progressBar setHidden:NO];
		[progressBar setDoubleValue:0.0];
		[NSThread detachNewThreadSelector:@selector(processingThread:) toTarget:self withObject:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(finishedProcessing:) 
													 name:NSThreadWillExitNotification 
												   object:nil];
	}
}

- (void)finishedProcessing:(id)sender
{
	[label setHidden:YES];
	[progressBar setHidden:YES];	
}

- (BOOL)tabView:(NSTabView*)tabView 
shouldSelectTabViewItem:(NSTabViewItem*)tabViewItem
{
	if (isProcessing &&
		([[tabViewItem identifier] isEqual:@"2"] ||
		 [[tabViewItem identifier] isEqual:@"3"])) 
		 return NO;
	return YES;
}

- (int)numberOfRowsInTableView:(NSTableView*)aTableView
{
	if (extrasTable == aTableView)
		return [extraFiles count];
	if (missingsTable == aTableView)
		return [missingFiles count];
	return 0;
}

- (id)tableView:(NSTableView *)aTableView
objectValueForTableColumn:(NSTableColumn *)aTableColumn
			row:(int)rowIndex
{
	if (extrasTable == aTableView) {
		if ([[aTableColumn identifier] isEqualToString:@"2"])
			return [extraFilesSizes objectAtIndex:rowIndex];
		return [extraFiles objectAtIndex:rowIndex];
	}
	if (missingsTable == aTableView) {
		return [missingFiles objectAtIndex:rowIndex];
	}
	return @"";
}

-(void)processingThread:(id)anObject
{
	isProcessing = true;

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	NSLog(@"iTLC processing...");

	[extraFiles removeAllObjects];
	[extraFilesSizes removeAllObjects];
	[missingFiles removeAllObjects];
	
	NSString *lpath = [@"~/Music/iTunes/iTunes Music/" stringByExpandingTildeInPath];
	
	NSMutableArray *files = [NSMutableArray array];
	NSMutableArray *xmllines = [NSMutableArray array];
	
	NSString *tmp;
    NSArray *lines;
	NSError *error = nil;
	int numFilesInXML = 0;
	
	// Get iTunes XML file content	
	
    lines = [[NSString stringWithContentsOfFile:[NSString stringWithFormat:@"%@/../%@", lpath, @"iTunes Music Library.xml"] encoding:NSUTF8StringEncoding error:&error] 
			 componentsSeparatedByString:@"\n"];
	
	if (error) {
		[label setHidden:YES];
		[progressBar setHidden:YES];
		[pool release];		
		isProcessing = false;
		hasExtraFiles = NO;
		return;
	}
	
	// Extract all lines with files
	
	NSEnumerator *nse = [lines objectEnumerator];
	while (tmp = [nse nextObject]) {
		NSRange range1 = [tmp rangeOfString:@"file://"];
		if (range1.location != NSNotFound) {
			if ([tmp rangeOfString:@"<key>Music Folder</key>"].location == NSNotFound) {
				[xmllines addObject:tmp];
				numFilesInXML++;
			} else {
				NSRange range2 = [tmp rangeOfString:@"</string>"];
				if (range1.location != NSNotFound && range2.location != NSNotFound) {
					NSString *part = [tmp substringWithRange:NSMakeRange(range1.location, range2.location-range1.location)];
					NSMutableString *_tmp = [NSMutableString stringWithString:part];
					[_tmp replaceOccurrencesOfString:@"&#38;" withString:@"&" options:0 range:NSMakeRange(0, [_tmp length])];
					NSURL *url = [NSURL URLWithString:_tmp];
					NSString *lpath = [url path];
					NSLog(@"Music Folder \"%@\"", lpath);
				}
			}
		}
	}
	
	// Traverse iTunes Music Library for files
		
	NSDirectoryEnumerator *direnum = [[NSFileManager defaultManager] enumeratorAtPath:lpath];
	NSString *pname;
	while (pname = [direnum nextObject]) {
		if (![pname hasPrefix:@"Ringtones"]) {
			NSMutableString *tmp = [NSMutableString stringWithString:[[NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@", lpath, pname]] absoluteString]];
			
			[tmp replaceOccurrencesOfString:@"&" withString:@"&#38;" options:0 range:NSMakeRange(0, [tmp length])];
			if (![[pname lastPathComponent] isEqualToString:@".DS_Store"] && ![tmp hasSuffix:@"/"])
				[files addObject:tmp];
		}
	}
	
	// Cross check lists
	
	NSEnumerator *fe = [files objectEnumerator];
	double num = [files count];
	double i = 0.0;
	double j = (double)[files count]/200.0;
	double k = 0;
	double totalLen = 0.0;
	while (tmp = [fe nextObject]) {
		i += 1.0;
		bool found = false;
		NSEnumerator *xe = [xmllines objectEnumerator];
		NSString *tmp2;
		while (tmp2 = [xe nextObject]) {
			if ([tmp2 rangeOfString:tmp options:NSCaseInsensitiveSearch].location != NSNotFound) {
				found = true;
				[xe nextObject];
				[xmllines removeObject:tmp2];
				break;
			}
		}
		if (!found) {
			NSMutableString *_tmp = [NSMutableString stringWithString:tmp];
			[_tmp replaceOccurrencesOfString:@"&#38;" withString:@"&" options:0 range:NSMakeRange(0, [_tmp length])];
			NSURL *url = [NSURL URLWithString:_tmp];
			NSString *lpath = [url path];
			if (!lpath) {
				NSLog(@"lpath = nil from %@", tmp);
			} else {
				
				[extraFiles addObject:lpath];

				NSDictionary *attr = [[NSFileManager defaultManager] fileAttributesAtPath:lpath traverseLink:YES];
				if (!attr && error) {
					[extraFilesSizes addObject:@"#Error#"];
				} else {
					double value = [[attr objectForKey:NSFileSize] doubleValue];
					totalLen += value;
					[extraFilesSizes addObject:[NSNumber numberWithDouble:value]];
				}
			}
		}
		if (i > k) {
			[progressBar setDoubleValue:100.0*i/num];
			k += j;
		}
	}

	if (![extraFiles count]) {
		[extraFiles addObject:@"No extra files found"];
		[extraFilesSizes addObject:@""];
	} else {
		hasExtraFiles = YES;
	}
	
	[progressBar setDoubleValue:100.0];
	BRByteFormatter *formatter = [[[BRByteFormatter alloc] init] autorelease];
	[labelForTotalSize setStringValue:[NSString stringWithFormat:@"Total size: %@ in %d files", [formatter stringFromNumber:[NSNumber numberWithDouble:totalLen]], [extraFiles count]]];
	
	if ([xmllines count] > 0) {
		NSEnumerator *xle = [xmllines objectEnumerator];
		while (tmp = [xle nextObject]) {
			NSRange range1 = [tmp rangeOfString:@"file://"];
			NSRange range2 = [tmp rangeOfString:@"</string>"];
			if (range1.location != NSNotFound && range2.location != NSNotFound) {
				NSString *part = [tmp substringWithRange:NSMakeRange(range1.location, range2.location-range1.location)];
				NSMutableString *_tmp = [NSMutableString stringWithString:part];
				[_tmp replaceOccurrencesOfString:@"&#38;" withString:@"&" options:0 range:NSMakeRange(0, [_tmp length])];
				NSURL *url = [NSURL URLWithString:_tmp];
				NSString *lpath = [url path];
				if (!lpath) {
					NSLog(@"2 lpath = nil from %@", part);
				} else {
					[missingFiles addObject:lpath];
				}
			}
		}
	} else {
		[missingFiles addObject:@"No missing files found"];
	}
	
	[pool release];

	isProcessing = false;
}

- (IBAction)moveExtraFilesToTrash:(id)sender
{
	if (!timer &&
		[extrasTable numberOfSelectedRows] && 
		!moveToTrashIndexes) {
			int button = NSRunAlertPanel(@"Move selected to Trash", @"Do you want to move the selected files to the Trash?\n\nPlease notice that this operation can not be undone by iTLC", @"Move", @"No", nil);
			if (button == NSAlertDefaultReturn) {
				[labelForTotalSize setStringValue:@""];
				moveToTrashIndexes = [[NSMutableIndexSet alloc] initWithIndexSet:[extrasTable selectedRowIndexes]];
				[extrasTable selectRowIndexes:nil byExtendingSelection:NO];
				timer = [NSTimer scheduledTimerWithTimeInterval: 0.01
														 target: self
													   selector: @selector(moveOneFile:)
													   userInfo: nil
														repeats: YES];
			}
	}
}

- (void)moveOneFile:(NSTimer*)_timer
{
	if (moveToTrashIndexes) {
		int lastIdx = [moveToTrashIndexes lastIndex];
		if (lastIdx != NSNotFound) {
			NSString *filePath = [extraFiles objectAtIndex:lastIdx];
			NSString *newPath;
			int attemt = 0;
			while (true) {
				if (attemt)
					newPath = [NSString stringWithFormat:@"%@/.Trash/%d %@", [@"~/" stringByExpandingTildeInPath], attemt, [filePath lastPathComponent]];
				else
					newPath = [NSString stringWithFormat:@"%@/.Trash/%@", [@"~/" stringByExpandingTildeInPath], [filePath lastPathComponent]];
				if ([[NSFileManager defaultManager] movePath:filePath toPath:newPath handler:nil] == YES) {
					[extraFiles removeObjectAtIndex:lastIdx];
					[extrasTable reloadData];
					break;
				} else {
					attemt++;
					if (attemt > 300) {
						NSRunAlertPanel(@"File failed to be moved", @"Failed to move one file, move of files stopped", @"Close", nil, nil);
						[moveToTrashIndexes release];
						moveToTrashIndexes = nil;
						[extrasTable reloadData];
						[_timer invalidate];
						timer = nil;
						break;
					}
				}
			}
			[moveToTrashIndexes removeIndex:lastIdx];
		} else {
			[moveToTrashIndexes release];
			moveToTrashIndexes = nil;
			[extrasTable reloadData];
			[_timer invalidate];
			timer = nil;
		}
	} else {
		[extrasTable reloadData];
		[_timer invalidate];
		timer = nil;
	}

#if 0
	if ([extrasTable numberOfSelectedRows] > 0) {		
		NSIndexSet *indexes = [extrasTable selectedRowIndexes];
		NSUInteger idx = [indexes firstIndex];
		NSString *filePath;
		NSString *newPath;
		int attemt = 0;
		while (idx != NSNotFound && filePath = [extraFiles objectAtIndex:idx]) {
			if (attemt)
				newPath = [NSString stringWithFormat:@"%@/.Trash/%@ %d", [@"~/" stringByExpandingTildeInPath], [filePath lastPathComponent], attemt];
			else
				newPath = [NSString stringWithFormat:@"%@/.Trash/%@", [@"~/" stringByExpandingTildeInPath], [filePath lastPathComponent]];
			if ([[NSFileManager defaultManager] movePath:filePath toPath:newPath handler:nil] == YES) {
				attemt = 0;
				idx = [indexes indexGreaterThanIndex:idx];
			} else {
				attemt++;
			}
		}
	} else {
		hasExtraFiles = NO;
		[extrasTable reloadData];
		[_timer invalidate];
		timer = nil;
	}
#endif
}

@end
