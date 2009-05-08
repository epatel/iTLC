//
//  AppController.h
//  iTLC
//
//  Created by Edward Patel on 2007-11-15.
//  Copyright 2007 Memention AB. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AppController : NSObject {
	IBOutlet NSTabView *tabView;
	IBOutlet NSButton *startButton;
	IBOutlet NSTextField *label;
	IBOutlet NSProgressIndicator *progressBar;
	IBOutlet NSTextField *labelForTotalSize;
	
	IBOutlet NSTableView *extrasTable;
	IBOutlet NSTableView *missingsTable;

	IBOutlet NSButton *moveToTrashButton;
	
	NSMutableArray *extraFiles;
	NSMutableArray *extraFilesSizes;
	NSMutableArray *missingFiles;
	NSMutableArray *multipleReferences;
	
	NSMutableIndexSet *moveToTrashIndexes;
	
	// For scanning
	BOOL isProcessing;
	BOOL hasExtraFiles;
	
	// For moving files
	NSTimer *timer;
}
- (IBAction)startProcessing:(id)sender;
- (IBAction)moveExtraFilesToTrash:(id)sender;
@end
