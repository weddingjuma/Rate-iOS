//
//  RatesTableViewController.m
//  Rate-iOS
//
//  Created by 李大爷的电脑 on 7/31/16.
//  Copyright © 2016 MuShare. All rights reserved.
//

#import "RatesTableViewController.h"
#import "InternetTool.h"
#import "UserTool.h"
#import "DaoManager.h"
#import <SVGKit/SVGKit.h>
#import <MJRefresh/MJRefresh.h>

@interface RatesTableViewController ()

@end

@implementation RatesTableViewController {
    AFHTTPSessionManager *manager;
    UserTool *user;
    DaoManager *dao;
    NSArray *rates;
    NSString *selectedRate;
}

- (void)viewDidLoad {
    if(DEBUG) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    [super viewDidLoad];
    manager = [InternetTool getSessionManager];
    user = [[UserTool alloc] init];
    dao = [[DaoManager alloc] init];
    _basedCurrency = [dao.currencyDao getByCid:user.basedCurrencyId];
    if(user.cacheRates != nil) {
        rates = user.cacheRates;
        [self.tableView reloadData];
    }
    
    self.tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        [self refreshRates];
    }];

}

- (void)viewDidDisappear:(BOOL)animated {
    if(DEBUG) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
}

- (void)viewWillAppear:(BOOL)animated {
    if(DEBUG) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    //Reset base currency name.
    [self.navigationItem.leftBarButtonItem setTitle:_basedCurrency.name];
    //Reload rates values.
    [self refreshRates];
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(DEBUG) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    return rates.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(DEBUG) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"rateIdentifier"
                                                                               forIndexPath:indexPath];
    SVGKFastImageView *currencyImageView = (SVGKFastImageView *)[cell viewWithTag:1];
    UILabel *codeLabel = (UILabel *)[cell viewWithTag:2];
    UILabel *nameLabel = (UILabel *)[cell viewWithTag:3];
    UILabel *rateLabel = (UILabel *)[cell viewWithTag:4];
    NSObject *rate = [rates objectAtIndex:indexPath.row];
    Currency *currency = [dao.currencyDao getByCid:[rate valueForKey:@"cid"]];
    currencyImageView.image = [SVGKImage imageNamed:[NSString stringWithFormat:@"%@.svg", currency.icon]];
    codeLabel.text = currency.code;
    nameLabel.text = currency.name;
    rateLabel.text = [NSString stringWithFormat:@"%.4f", [[rate valueForKey:@"value"] floatValue]];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    if(DEBUG) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    return 0.1;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if(DEBUG) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    selectedRate = [rates objectAtIndex:indexPath.row];
    [self performSegueWithIdentifier:@"rateSegue" sender:self];
}

#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if(DEBUG) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    if([segue.identifier isEqualToString:@"selectBaseSegue"]) {
        [segue.destinationViewController setValue:@YES forKey:@"selectable"];
        //Tell Currencies Controller what attribute to set.
        [segue.destinationViewController setValue:@"basedCurrency" forKey:@"currencyAttributeName"];
    } else if([segue.identifier isEqualToString:@"rateSegue"]) {
        [segue.destinationViewController setValue:selectedRate forKey:@"selectedRate"];
    }
}

#pragma mark - Service
- (void)refreshRates {
    if(DEBUG) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setObject:_basedCurrency.cid forKey:@"from"];
    
    if(user.token != nil) {
        [parameters setObject:[NSNumber numberWithInt:1] forKey:@"favorite"];
    }
    [manager GET:[InternetTool createUrl:@"api/rate/current"]
      parameters:parameters
        progress:nil
         success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
             InternetResponse *response = [[InternetResponse alloc] initWithResponseObject:responseObject];
             if([response statusOK]) {
                 rates = [[response getResponseResult] objectForKey:@"rates"];
                 [self.tableView reloadData];
                 if(rates != nil) {
                     user.cacheRates = rates;
                 }
             }
             [self.tableView.mj_header endRefreshing];
             
             //Refresh favorite currencies stored in local database.
             for(Currency *currency in [dao.currencyDao findAll]) {
                 currency.favorite = [NSNumber numberWithBool:NO];
             }
             for(NSObject *rate in rates) {
                 Currency *currency = [dao.currencyDao getByCid:[rate valueForKey:@"cid"]];
                 currency.favorite = [NSNumber numberWithBool:YES];
             }
             [dao saveContext];
         }
         failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
             if(DEBUG) {
                 NSLog(@"Server error: %@", error.localizedDescription);
             }
             InternetResponse *response = [[InternetResponse alloc] initWithError:error];
             [response errorCode];
         }];
    
}

@end

