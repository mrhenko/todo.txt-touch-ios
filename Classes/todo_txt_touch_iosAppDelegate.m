/**
 *
 * Todo.txt-Touch-iOS/Classes/todo_txt_touch_iosAppDelegate.m
 *
 * Copyright (c) 2009-2011 Gina Trapani, Shawn McGuire
 *
 * LICENSE:
 *
 * This file is part of Todo.txt Touch, an iOS app for managing your todo.txt file (http://todotxt.com).
 *
 * Todo.txt Touch is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation, either version 2 of the License, or (at your option) any
 * later version.
 *
 * Todo.txt Touch is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
 * warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with Todo.txt Touch.  If not, see
 * <http://www.gnu.org/licenses/>.
 *
 * @author Gina Trapani <ginatrapani[at]gmail[dot]com>
 * @author Shawn McGuire <mcguiresm[at]gmail[dot]com> 
 * @license http://www.gnu.org/licenses/gpl.html
 * @copyright 2009-2011 Gina Trapani, Shawn McGuire
 *
 * Copyright (c) 2011 Gina Trapani and contributors, http://todotxt.com
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "todo_txt_touch_iosAppDelegate.h"
#import "todo_txt_touch_iosViewController.h"
#import "TaskBag.h"
#import "TaskBagFactory.h"
#import "AsyncTask.h"
#import "Network.h"
#import "LocalFileTaskRepository.h"

@implementation todo_txt_touch_iosAppDelegate

@synthesize window;
@synthesize viewController;
@synthesize navigationController;
@synthesize taskBag;
@synthesize remoteClientManager;


#pragma mark -
#pragma mark Application lifecycle

+ (todo_txt_touch_iosAppDelegate*) sharedDelegate {
	return (todo_txt_touch_iosAppDelegate*)[[UIApplication sharedApplication] delegate];
}

+ (id<TaskBag>) sharedTaskBag {
	return [[todo_txt_touch_iosAppDelegate sharedDelegate] taskBag];
}

+ (RemoteClientManager*) sharedRemoteClientManager {
	return [[todo_txt_touch_iosAppDelegate sharedDelegate] remoteClientManager];
}

+ (void) syncClient {	
	[[todo_txt_touch_iosAppDelegate sharedDelegate] performSelectorOnMainThread:@selector(syncClient) withObject:nil waitUntilDone:NO];
}

+ (void) pushToRemote {	
	[[todo_txt_touch_iosAppDelegate sharedDelegate] performSelectorOnMainThread:@selector(pushToRemote) withObject:nil waitUntilDone:NO];
}

+ (void) pullFromRemote {
	[[todo_txt_touch_iosAppDelegate sharedDelegate] pullFromRemote];
}

+ (BOOL) isOfflineMode {
	return [[todo_txt_touch_iosAppDelegate sharedDelegate] isOfflineMode];
}

+ (void) logout {
	return [[todo_txt_touch_iosAppDelegate sharedDelegate] logout];
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    
    remoteClientManager = [[RemoteClientManager alloc] initWithDelegate:self];
    taskBag = [[TaskBagFactory getTaskBag] retain];
		
	// Start listening for network status updates.
	[Network startNotifier];
	
    // Add the view controller's view to the window and display.
    [self.window addSubview:navigationController.view];

	if (![remoteClientManager.currentClient isAuthenticated]) {
		[remoteClientManager.currentClient presentLoginControllerFromController:navigationController];
	}
	
	[self.window makeKeyAndVisible];

    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, called instead of applicationWillTerminate: when the user quits.
     */
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    /*
     Called as part of  transition from the background to the inactive state: here you can undo many of the changes made on entering the background.
     */
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
	[self syncClient];
}


- (void)applicationWillTerminate:(UIApplication *)application {
    /*
     Called when the application is about to terminate.
     See also applicationDidEnterBackground:.
     */
}

#pragma mark -
#pragma mark Remote functions

- (void) syncClient {
	[self syncClientForceChoice:NO];
}

- (void) syncClientForceChoice:(BOOL)forceChoice {
	if ([self isOfflineMode] || forceChoice) {
		if (![remoteClientManager.currentClient isAvailable]) {
			// TODO: go offline
		} else {
			// TODO: sync choice dialog
		}
	} else {
		if (![remoteClientManager.currentClient isAvailable]) {
			// TODO: go offline
		} else {
			[self pullFromRemote];
		}
	}
}

- (void) pushToRemote {
	if ([self isOfflineMode]) {
		return;
	}
	
	if (![remoteClientManager.currentClient isAvailable]) {
		// TODO: go offline
	} else {
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
		// We probably shouldn't be assuming LocalFileTaskRepository here, 
		// but that is what the Android app does, so why not?
		[remoteClientManager.currentClient pushTodo:[LocalFileTaskRepository filename]];
		// pushTodo is asynchronous. When it returns, it will call
		// the delegate method 'uploadedFile'
	}	
}

- (void) pullFromRemote {
	if ([self isOfflineMode]) {
		return;
	}
	
	if (![remoteClientManager.currentClient isAvailable]) {
		// TODO: go offline
	} else {
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
		[remoteClientManager.currentClient pullTodo];
		// pullTodo is asynchronous. When it returns, it will call
		// the delegate method 'loadedFile'
	}	
}

- (BOOL) isOfflineMode {
	//TODO implement isOfflineMode
	return NO;
}

- (void) logout {
	[remoteClientManager.currentClient deauthenticate];
	// TODO: delete user preferences

	[remoteClientManager.currentClient presentLoginControllerFromController:navigationController];
}

#pragma mark -
#pragma mark RemoteClientDelegate methods

- (void)remoteClient:(id<RemoteClient>)client loadedFile:(NSString*)destPath {
	if (destPath) {
		[taskBag reloadWithFile:destPath];
		// Send notification so that whichever screen is active can refresh itself
		[[NSNotificationCenter defaultCenter] postNotificationName: kTodoChangedNotification object: nil];
	}
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];	
}

- (void)remoteClient:(id<RemoteClient>)client uploadedFile:(NSString*)destPath {
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}


#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
}

- (void)remoteClient:(id<RemoteClient>)client loginControllerDidLogin:(BOOL)success {
	if (success) {
		[self syncClient];
	}
}

- (void)dealloc {
    [viewController release];
	[navigationController release];
    [window release];
    [taskBag release];
	[remoteClientManager release];
    [super dealloc];
}


@end
