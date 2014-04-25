//
//  VYMessageChunk.h
//  CoreBluetooth
//
//  Created by Vitaly Yurchenko on 4/22/14.
//  Copyright (c) 2014 Vitaly Yurchenko. All rights reserved.
//

@import Foundation;

extern const NSUInteger kVYMessageChunkMTULength;
extern const NSUInteger kVYMessageChunkHeaderLength;
extern const NSUInteger kVYMessageChunkBodyLength;

@interface VYMessageChunk : NSObject

@property (nonatomic, readonly) NSData *data;

@property (nonatomic, getter = isFirst) BOOL first;
@property (nonatomic, getter = isLast) BOOL last;
@property (nonatomic) NSData *body;

+ (instancetype)messageChunkWithData:(NSData *)data;
- (instancetype)initWithData:(NSData *)data;

@end
