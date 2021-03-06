//
//  AppDelegate.h
//  Rate-iOS
//
//  Created by 李大爷的电脑 on 7/31/16.
//  Copyright © 2016 MuShare. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <AFNetworking/AFNetworking.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) AFHTTPSessionManager *httpSessionManager;
@property (strong, nonatomic) AFHTTPSessionManager *httpSessionManagerForJSON;
@property (strong, nonatomic) AFHTTPSessionManager *newsSessionManager;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (nonatomic) BOOL refreshRates;
@property (nonatomic, strong) NSDictionary *regInfo;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

- (void)setRootViewControllerWithIdentifer:(NSString *)identifer;

@end

