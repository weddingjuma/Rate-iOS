//
//  LoadingViewController.m
//  Rate-iOS
//
//  Created by lidaye on 8/5/16.
//  Copyright © 2016 MuShare. All rights reserved.
//

#import "LoadingViewController.h"
#import "DaoManager.h"
#import "InternetTool.h"
#import "UserTool.h"
#import "AlertTool.h"

@interface LoadingViewController ()

@end

@implementation LoadingViewController {
    DaoManager *dao;
    AFHTTPSessionManager *manager;
    UserTool *user;
}

- (void)viewDidLoad {
    if (DEBUG) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    [super viewDidLoad];
    dao = [[DaoManager alloc] init];
    manager = [InternetTool getSessionManager];
    user = [[UserTool alloc] init];
    [self loadCurriencies];
}


- (void)loadCurriencies {
    if (DEBUG) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
        NSLog(@"Currency revison is %ld.", user.currencyRev);
    }

    [manager GET:[InternetTool createUrl:@"api/currencies/list"]
      parameters:@{
                   @"lan": user.lan,
                   @"rev": [NSNumber numberWithInteger:user.currencyRev]
                   }
        progress:nil
         success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
             InternetResponse *response = [[InternetResponse alloc] initWithResponseObject:responseObject];
             if ([response statusOK]) {
                 NSObject *result = [response getResponseResult];
                 NSArray *currencies = [result valueForKey:@"currencies"];
                 for (NSObject *currency in currencies) {
                     [dao.currencyDao saveOrUpdateWithJSONObject:currency];
                 }
                 [dao saveContext];
                 //Set new currency revision.
                 user.currencyRev = [[result valueForKey:@"revision"] intValue];
                 //Set Based Currency Id if it is null
                 if (user.basedCurrencyId == nil) {
                     Currency *basedCurrency = [dao.currencyDao getByCode:@"USD"];
                     user.basedCurrencyId = basedCurrency.cid;
                 }
             }
             
             [self performSegueWithIdentifier:@"mainTabControllerSegue" sender:self];
         }
         failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
             if (DEBUG) {
                 NSLog(@"Server error: %@", error.localizedDescription);
             }
             _loadingActivityIndicatorView.hidden = YES;
             _tipLabel.hidden = NO;
             _useWithoutInternetButton.hidden = NO;
             InternetResponse *response = [[InternetResponse alloc] initWithError:error];
             switch ([response errorCode]) {
                 case ErrorCodeNotConnectedToInternet:
            
                     break;
                     
                 default:
                     break;
             }
         }];
}



- (IBAction)useWithoutInternet:(id)sender {
    if (DEBUG) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    [self performSegueWithIdentifier:@"mainTabControllerSegue" sender:self];
}

@end
