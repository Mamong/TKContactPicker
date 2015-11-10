//
//  AppDelegate.m
//  TKContactsMultiPicker
//
//  Created by Jongtae Ahn on 12. 8. 31..
//  Copyright (c) 2012년 TABKO Inc. All rights reserved.
//

#import "AppDelegate.h"
#import "MainViewController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.mainViewController = [[MainViewController alloc] initWithNibName:@"MainViewController" bundle:nil];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:self.mainViewController];
    TKPeoplePickerNavigationController *picker = [[TKPeoplePickerNavigationController alloc]init];
    picker.peoplePickerDelegate = self;
    picker.pickerStyle = TKPeoplePickerNavigationControllerStyleAllPhones;
    self.tabBarController = [[UITabBarController alloc]init];
    _tabBarController.viewControllers = @[navigationController,picker];
    self.window.rootViewController = self.tabBarController;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)tkPeoplePickerNavigationController:(TKPeoplePickerNavigationController *)peoplePicker didSelectContact:(TKContact *)contact
{
    NSLog(@"select contact");
}
//
-(void)tkPeoplePickerNavigationController:(TKPeoplePickerNavigationController *)peoplePicker didSelectContacts:(NSArray *)contacts
{
    NSLog(@"select contacts");
}

@end
