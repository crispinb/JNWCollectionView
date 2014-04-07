//
//  JNWCollectionViewFlowLayout.h
//  JNWCollectionView
//
//  Created by Jonathan Willing on 4/11/13.
//  Copyright (c) 2013 AppJon. All rights reserved.
//

// NB: this was jWilling's initial approach which he decided not to include in the release
// But it might be a useful starting point

#import "JNWCollectionViewLayout.h"

@protocol JNWCollectionViewFlowLayoutDelegate <NSObject>

- (CGSize)collectionView:(JNWCollectionView *)collectionView sizeForItemAtIndexPath:(NSIndexPath *)indexPath;

@optional
- (CGFloat)collectionView:(JNWCollectionView *)collectionView heightForHeaderInSection:(NSInteger)index;
- (CGFloat)collectionView:(JNWCollectionView *)collectionView heightForFooterInSection:(NSInteger)index;

@end

@interface JNWCollectionViewFlowLayout : JNWCollectionViewLayout

@property (nonatomic, weak) id<JNWCollectionViewFlowLayoutDelegate> delegate;
//@property (nonatomic, assign) CGFloat minimumItemVerticalSeparation;
@property (nonatomic, assign) CGFloat minimumItemHorizontalSeparation;

@end
