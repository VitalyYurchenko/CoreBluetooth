//
//  VYMessage.h
//  CoreBluetooth
//
//  Created by Vitaly Yurchenko on 4/16/14.
//  Copyright (c) 2014 Vitaly Yurchenko. All rights reserved.
//

@import Foundation;

@class VYMessageChunk;

@interface VYMessage : NSObject

@property (nonatomic, readonly) NSData *data;

+ (instancetype)messageWithData:(NSData *)data;
+ (instancetype)messageWithChunk:(VYMessageChunk *)chunk;
- (instancetype)initWithData:(NSData *)data;
- (instancetype)initWithChunk:(VYMessageChunk *)chunk;

- (NSUInteger)chunkCount;
- (VYMessageChunk *)firstChunk;
- (VYMessageChunk *)currentChunk;
- (VYMessageChunk *)nextChunk;
- (VYMessageChunk *)chunkAtIndex:(NSUInteger)index;

@end

@interface VYMutableMessage : VYMessage

- (void)addChunk:(VYMessageChunk *)chunk;

@end