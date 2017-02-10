//
//  ALAssetsLibrary+LGBCustom.m
//  AlbumDemo
//
//  Created by lgb789 on 2017/2/8.
//  Copyright © 2017年 com.dnj. All rights reserved.
//

#import "ALAssetsLibrary+LGBCustom.h"
//#import <Photos/Photos.h>

#ifdef DEBUG_LIBRARY
#define DDLog(fmt, ...)     NSLog(@"[%@:%d] "fmt, [[NSString stringWithFormat:@"%s", __FILE__] lastPathComponent], __LINE__, ##__VA_ARGS__)
#else
#define DDLog
#endif

@implementation ALAssetsLibrary (LGBCustom)

-(void)completionBlock:(ALAssetsLibraryWriteImageCompletionBlock)block params:(NSURL *)url error:(NSError *)error
{
    if (block) {
        block(url, error);
    }
}

-(void)group:(ALAssetsGroup *)group addAsset:(NSURL *)assetURL completion:(ALAssetsLibraryWriteImageCompletionBlock)completion
{
    
    [self assetForURL:assetURL resultBlock:^(ALAsset *asset) {
        DDLog(@"add asset");
        if ([group addAsset:asset]) {
            [self completionBlock:completion params:assetURL error:nil];
        }else{
            NSString *msg = [NSString stringWithFormat:@"failed to add asset:%@ to group:%@", asset, group];
            NSError *err = [NSError errorWithDomain:@"AssetsLibrary LGBCustom" code:200 userInfo:@{NSLocalizedDescriptionKey:msg}];
            [self completionBlock:completion params:assetURL error:err];
        }
    } failureBlock:^(NSError *error) {
        [self completionBlock:completion params:assetURL error:error];
    }];
}

//使用runtime
-(void)runtimePhotoLibraryAddAssetURL:(NSURL *)assetURL toAlbum:(NSString *)album completion:(ALAssetsLibraryWriteImageCompletionBlock)completion
{
    Class PHPhotolibrary_class = NSClassFromString(@"PHPhotoLibrary");
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    id sharedPhotoLibrary = [PHPhotolibrary_class performSelector:NSSelectorFromString(@"sharedPhotoLibrary")];
#pragma clang diagnostic pop
    SEL performChange = NSSelectorFromString(@"performChanges:completionHandler:");
    NSMethodSignature *methodSignature = [sharedPhotoLibrary methodSignatureForSelector:performChange];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
    
    [invocation setTarget:sharedPhotoLibrary];
    [invocation setSelector:performChange];
    
    void (^changeBlock)() = ^{
        Class PHAssetCollectionChangeRequest_class = NSClassFromString(@"PHAssetCollectionChangeRequest");
        SEL creationRequestForAssetCollectionWithTitle = NSSelectorFromString(@"creationRequestForAssetCollectionWithTitle:");
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [PHAssetCollectionChangeRequest_class performSelector:creationRequestForAssetCollectionWithTitle withObject:album];
#pragma clang diagnostic pop
        
    };
    
    [invocation setArgument:&changeBlock atIndex:2];
   
    void (^completionHandler)(BOOL success, NSError *__nullable error) = ^(BOOL success, NSError *__nullable error){
        if (success) {
            [self enumerateGroupsWithTypes:ALAssetsGroupAlbum usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                if ([[group valueForProperty:ALAssetsGroupPropertyName] isEqualToString:album]) {
                    [self group:group addAsset:assetURL completion:completion];
                    *stop = YES;
                }
            } failureBlock:^(NSError *error) {
                completion(assetURL, error);
            }];

        }
        if (error) {
            completion(assetURL, error);
        }
    };
    [invocation setArgument:&completionHandler atIndex:3];
    
    [invocation invoke];
}

//使用photos.framework
/*
-(void)photoLibraryAddAssetURL:(NSURL *)assetURL toAlbum:(NSString *)album completion:(ALAssetsLibraryWriteImageCompletionBlock)completion
{
    DDLog(@"support photolibrary");
//    __block PHObjectPlaceholder *placeHolder;
    //创建相册
    void(^changeBlock)(void) = ^(void){
        DDLog(@"create asset collection");
        [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:album];
//        placeHolder = request.placeholderForCreatedAssetCollection;
        
    };
    //添加照片到自定义相册
    void(^completionHandler)(BOOL success, NSError * _Nullable error) = ^(BOOL success, NSError * _Nullable error){
        DDLog(@"create succsss:%d", success);
        if (error) {
            [self completionBlock:completion params:assetURL error:error];
        }
        if (success) {
            [self enumerateGroupsWithTypes:ALAssetsGroupAlbum usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                if (group) {
                    if ([[group valueForProperty:ALAssetsGroupPropertyName] isEqualToString:album]) {
                        [self group:group addAsset:assetURL completion:completion];
                        *stop = YES;
                    }
                }
            } failureBlock:^(NSError *error) {
                [self completionBlock:completion params:assetURL error:error];
            }];
            
        }
    };
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:changeBlock completionHandler:completionHandler];
    
}
*/

-(void)addAssetURL:(NSURL *)assetURL toAlbum:(NSString *)album completion:(ALAssetsLibraryWriteImageCompletionBlock)completion
{
    __block BOOL albumFounded = NO;
    //block变量
    void(^addAssetBlock)(ALAssetsGroup *group) = ^(ALAssetsGroup *group){
        [self group:group addAsset:assetURL completion:completion];
    };
    
    void(^failureBlock)(NSError *error) = ^(NSError *error){
        [self completionBlock:completion params:assetURL error:error];
    };
    DDLog(@"add asset url");
    ALAssetsLibraryGroupsEnumerationResultsBlock enumberateBlock = ^(ALAssetsGroup *group, BOOL *stop){
        DDLog(@"group:%@", group);
        if ([[group valueForProperty:ALAssetsGroupPropertyName] isEqualToString:album]) {
            DDLog(@"found album");
            albumFounded = YES;
            //添加照片到相册
//            [self group:group addAsset:assetURL completion:completion];
            addAssetBlock(group);
            
            //找到自定义相册，停止遍历
            *stop = YES;
        }
        //遍历的最后一项是nil
        if (group == nil && albumFounded == NO) {//找不到自定义相册
            
            Class photoLibrary_class = NSClassFromString(@"PHPhotoLibrary");
            if (photoLibrary_class) {
                //直接使用类库
                //[self photoLibraryAddAssetURL:assetURL toAlbum:album completion:completion];
                //使用runtime
                [self runtimePhotoLibraryAddAssetURL:assetURL toAlbum:album completion:completion];
            }else{
                DDLog(@"not support photolibrary");
                [self addAssetsGroupAlbumWithName:album resultBlock:addAssetBlock failureBlock:failureBlock];
            }
            
        }
    };
    
    [self enumerateGroupsWithTypes:ALAssetsGroupAlbum usingBlock:enumberateBlock failureBlock:failureBlock];
}

-(ALAssetsLibraryWriteImageCompletionBlock)blockAddAlbum:(NSString *)album completion:(ALAssetsLibraryWriteImageCompletionBlock)completion
{
    return ^(NSURL *assetURL, NSError *error){
        //保存到系统相册出错返回
        if (error != nil) {
            //执行上层block
            [self completionBlock:completion params:assetURL error:error];
            return ;
        }
        DDLog(@"block album");
        //添加照片到自定义相册
        [self addAssetURL:assetURL toAlbum:album completion:completion];
    };
}

-(void)saveImage:(UIImage *)image toAlbum:(NSString *)album completion:(ALAssetsLibraryWriteImageCompletionBlock)completion
{
    //保存照片到系统相册 使用这个方法可以保持相片原来方向
    [self writeImageToSavedPhotosAlbum:image.CGImage orientation:(ALAssetOrientation)image.imageOrientation completionBlock:[self blockAddAlbum:album completion:completion]];//添加照片block
}

-(void)saveVideo:(NSURL *)fileURL toAlbum:(NSString *)album completion:(void(^)(NSURL *assetURL, NSError *error))completion
{
    [self writeVideoAtPathToSavedPhotosAlbum:fileURL completionBlock:[self blockAddAlbum:album completion:completion]];
}

@end
