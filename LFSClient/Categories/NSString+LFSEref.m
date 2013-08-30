//
//  NSString+LFSEref.m
//  LivefyreClient
//
//  Created by Thomas Goyne on 5/17/12.
//
//  Copyright (c) 2013 Livefyre
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.

#import "NSString+LFSEref.h"
#import <CommonCrypto/CommonCryptor.h>

static NSData *hexStringToBytes(NSString *string)
{
    NSMutableData *data = [NSMutableData data];
    for (NSUInteger i = 0; i + 2 <= string.length; i += 2) {
        uint8_t value = (uint8_t)strtol([[string substringWithRange:NSMakeRange(i, 2)] UTF8String], 0, 16);
        [data appendBytes:&value length:1];
    }
    return data;
}

@implementation NSString (LFSEref)

- (NSString *)decryptRC4WithKey:(NSString *)key
{
    NSData *inBytes = hexStringToBytes(self);
    NSData *keyBytes = hexStringToBytes(key);
    
    NSMutableData *outBytes = [NSMutableData dataWithLength:[inBytes length]];
    size_t dataOutMoved = 0;
    
    CCCryptorStatus ccStatus = CCCrypt(kCCDecrypt,
                                       kCCAlgorithmRC4,
                                       0,
                                       [keyBytes bytes],
                                       [keyBytes length],
                                       NULL, // iv
                                       [inBytes bytes],
                                       [inBytes length],
                                       [outBytes mutableBytes],
                                       [outBytes length],
                                       &dataOutMoved);
    
    NSString *decrypted = [[NSString alloc] initWithData:outBytes encoding:NSUTF8StringEncoding];
    
    if (ccStatus == kCCSuccess) {
        return decrypted;
    }
    return self;
}

- (NSString *)decodeErefWithKeys:(NSArray *)keys {
    for (NSString *key in keys) {
        NSString *decryptedPath = [self decryptRC4WithKey:key];
        if ([decryptedPath hasPrefix:@"eref://"]) {
            return decryptedPath;
        }
    }
    return nil;
}

@end
