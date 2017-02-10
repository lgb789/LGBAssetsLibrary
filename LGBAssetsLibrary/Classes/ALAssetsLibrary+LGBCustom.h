//
//  ALAssetsLibrary+LGBCustom.h
//  AlbumDemo
//
//  Created by lgb789 on 2017/2/8.
//  Copyright © 2017年 com.dnj. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>
#import <UIKit/UIKit.h>

@interface ALAssetsLibrary (LGBCustom)

/**
 保存图片到自定义相册

 @param image 要保存到图片
 @param album 自定义相册名字
 @param completion 保存操作完成后执行
 */
-(void)saveImage:(UIImage *)image toAlbum:(NSString *)album completion:(ALAssetsLibraryWriteImageCompletionBlock)completion;


/**
 保存视频到自定义相册

 @param fileURL 视频链接
 @param album 自定义相册名
 @param completion 保存操作完成后执行
 */
-(void)saveVideo:(NSURL *)fileURL toAlbum:(NSString *)album completion:(void(^)(NSURL *assetURL, NSError *error))completion;

@end
