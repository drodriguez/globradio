//
//  COPEAppDelegate.h
//  radio3
//
//  Created by Javier Quevedo on 1/8/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class COPEViewController;

@interface COPEAppDelegate : NSObject <UIApplicationDelegate> {
@private
	UIWindow *window;
	COPEViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet COPEViewController *viewController;

@end
