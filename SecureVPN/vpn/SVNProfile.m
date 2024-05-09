//
//  SVNProfile.m
//  SecureVPN
//
//  Created by  securevpn on 2024/2/21.
//

#import "SVNProfile.h"
#import "SVTools.h"

@implementation SVNProfile

- (NSString *)serverAddress {
    if (_serverAddress.length == 0) {
        _serverAddress = @"104.200.17.204";
    }
    return _serverAddress;
}

- (NSString *)username {
    if (_username.length == 0) {
        _username = [SVTools randomStringWithLengh:10];
    }
    return _username;
}

- (NSString *)password {
    if (_password.length == 0) {
        _password = @"qwertyuiop";
    }
    return _password;
}

@end
