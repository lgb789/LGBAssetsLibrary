//
//  LGBViewController.m
//  LGBAssetsLibrary
//
//  Created by lgb789@126.com on 02/10/2017.
//  Copyright (c) 2017 lgb789@126.com. All rights reserved.
//

#import "LGBViewController.h"
#import "ALAssetsLibrary+LGBCustom.h"
#import <MobileCoreServices/MobileCoreServices.h>

#define kAlbumName  @"custom album"

@interface LGBViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (nonatomic, strong) ALAssetsLibrary *library;
@end

@implementation LGBViewController

-(ALAssetsLibrary *)library
{
    if (_library == nil) {
        _library = [[ALAssetsLibrary alloc] init];
    }
    return _library;
}

/**
 保存视频
 */
-(void)saveVideo
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"test_video" ofType:@"m4v"];
    NSURL *videoURL = [NSURL fileURLWithPath:path];
    [self.library saveVideo:videoURL toAlbum:kAlbumName completion:^(NSURL *assetURL, NSError *error) {
        NSLog(@"error:%@", error);
    }];
}

#pragma mark - UIImagePickerControllerDelegate
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    [self imagePickerControllerDidCancel:picker];
    
    UIImage *image = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
    [self.library saveImage:image toAlbum:kAlbumName completion:^(NSURL *assetURL, NSError *error) {
        NSLog(@"save image error:%@", error);
    }];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

/**
 拍照
 */
-(void)takePhoto
{
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [[[UIAlertView alloc] initWithTitle:@"相机不可用" message:@"当前设备相机不可用" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil] show];
        return;
    }
    
    UIImagePickerController *controller = [[UIImagePickerController alloc] init];
    controller.mediaTypes = @[(NSString *)kUTTypeImage];
    controller.sourceType = UIImagePickerControllerSourceTypeCamera;
    controller.delegate = self;
    
    [self.navigationController presentViewController:controller animated:YES completion:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    UIBarButtonItem *item1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveVideo)];
    
    UIBarButtonItem *item2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(takePhoto)];
    
    self.navigationItem.rightBarButtonItems = @[item1, item2];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
