//
//  SVWebVC.m
//  SecureVPN
//
//  Created by  securevpn on 2024/1/5.
//

#import "SVWebVC.h"
#import <WebKit/WKWebView.h>
#import <WebKit/WKWebViewConfiguration.h>
#import "SVNavigationView.h"
#import "SVConstant.h"
#import "UIView+SV.h"

@interface SVWebVC ()
@property (nonatomic, strong) SVNavigationView *navView;
@property (nonatomic, strong) WKWebView *webView;
@end

@implementation SVWebVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.webView = [[WKWebView alloc] initWithFrame:self.view.bounds];
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.url]]];
    [self.view addSubview:self.webView];
    
    self.navView = [[SVNavigationView alloc] init];
    [self.navView.rightButton nImage:[UIImage imageNamed:@"back_black"] hImage:nil];
    [self.navView.rightButton addTarget:self action:@selector(backAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.navView];
}

- (void)backAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
