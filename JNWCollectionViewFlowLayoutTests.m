// TODO: (17/2/14) I can't compile this until (Ex)Specta has eliminated GC (won't compile on Xcode 5.1x)

#import <XCTest/XCTest.h>
#import "JNWCollectionViewFlowLayout.h"

@interface DelegateStub : NSObject <JNWCollectionViewFlowLayoutDelegate>
@property (nonatomic, strong) CGSize (^itemSizeBlock)(NSIndexPath *);
@property (nonatomic, strong) NSArray *itemWidths;
@property (nonatomic, assign) CGFloat headerHeight;
@property (nonatomic, assign) CGFloat footerHeight;
@end

@implementation DelegateStub

- (CGSize)collectionView:(JNWCollectionView *)collectionView sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
	return self.itemSizeBlock(indexPath);
}

- (CGFloat)collectionView:(JNWCollectionView *)collectionView heightForHeaderInSection:(NSInteger)index1 {
	return self.headerHeight;
}

- (CGFloat)collectionView:(JNWCollectionView *)collectionView heightForFooterInSection:(NSInteger)index1 {
	return self.footerHeight;
}

@end

@interface CollectionViewStub : NSObject
@property (nonatomic, assign) NSSize contentSize;
@property (nonatomic, assign) NSUInteger numberOfItems;
@property (nonatomic, assign) NSUInteger numberOfSections;
- (id)initWithNumberOfItems:(NSUInteger)items sections:(NSUInteger)sections contentSize:(NSSize)size;
@end

@implementation CollectionViewStub
- (id)initWithNumberOfItems:(NSUInteger)items sections:(NSUInteger)sections contentSize:(NSSize)size {
	self = [super init];
	if (self) {
		self.numberOfItems = items;
		self.numberOfSections = sections;
		self.contentSize = size;
	}
	return self;
}

- (NSInteger)numberOfSectionsInCollectionView:(JNWCollectionView *)collectionView {
	return self.numberOfSections;
}

- (NSUInteger)numberOfItemsInSection:(NSInteger)section {
	return self.numberOfItems;
}

- (JNWCollectionViewCell *)collectionView:(JNWCollectionView *)collectionView
                   cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	return nil;
}
@end

@interface JNWCollectionViewFlowLayoutTests : XCTestCase
@end

@implementation JNWCollectionViewFlowLayoutTests {
    JNWCollectionViewFlowLayout *sut;
    // to keep collectionView belonging to sut in existence (layout object only holds a weak ref)
    id collectionView;
}

// Layout tests.
// These can be translated to Expecta + OCMock when integrating

- (void)setUp {
	[super setUp];

    
}

- (void)testIfThereAreNoSectionsThenThrows {

	sut = [[JNWCollectionViewFlowLayout alloc] initWithCollectionView:nil];
	id delegate = [DelegateStub new];
	sut.delegate = delegate;

	[sut prepareLayout];

	JNWCollectionViewLayoutAttributes *attributes;
	XCTAssertThrows(attributes = [sut layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathWithIndex:1]]);
}

- (void)testIfThereAreNoItemsInASectionThenThrows {

	CollectionViewStub *collectionViewStub = [CollectionViewStub new];
	collectionViewStub.numberOfSections = 1;
	collectionViewStub.numberOfItems = 0;
	sut = [[JNWCollectionViewFlowLayout alloc]
	                                                                 initWithCollectionView:(id) collectionViewStub];
	id delegate = [DelegateStub new];
	sut.delegate = delegate;

	[sut prepareLayout];

	JNWCollectionViewLayoutAttributes *attributes;
	XCTAssertThrows(attributes = [sut layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathWithIndex:1]]);
}

- (void)testFirstItemInFirstRowIsLaidOutFlushLeft {
	CGFloat interItemSpacing = 2.0f;

	NSArray *itemFrames = [self framesAfterLayoutForItemsOfWidth:@[@(5)]
	                                       withHorizontalSpacing:interItemSpacing
						                         verticalSpacing:0
										     collectionViewWidth:10];

	NSRect item1Frame = [self unboxFrame:itemFrames[0]];
	XCTAssertEqual(item1Frame.origin.x, 0);
}

- (void)testTwoItemsOfCombinedWidthLessThanCollectionViewWidthAreLaidOutHorizontally {
	CGFloat interItemSpacing = 1.0f;

	NSArray *itemFrames = [self framesAfterLayoutForItemsOfWidth:@[@1.0f, @1.0f]
	                                       withHorizontalSpacing:interItemSpacing
						                         verticalSpacing:0
										     collectionViewWidth:100];

	NSRect item1Frame = [self unboxFrame:itemFrames[0]];
	NSRect item2Frame = [self unboxFrame:itemFrames[1]];
	XCTAssertEqual(item2Frame.origin.x, item1Frame.origin.x + item1Frame.size.width + interItemSpacing);
	XCTAssertEqual(item2Frame.origin.y, item1Frame.origin.y);
}

- (void)testTwoItemsOfCombinedWidthGreaterThanCollectionViewWidthAreLaidOutVertically {
	CGFloat interItemSpacing = 2.0f;
	CGFloat lineSpacing = 2.0f;

	NSArray *itemFrames = [self framesAfterLayoutForItemsOfWidth:@[@2, @2]
	                                       withHorizontalSpacing:interItemSpacing
						                         verticalSpacing:lineSpacing
										     collectionViewWidth:5.0f];

	NSRect item1Frame = [self unboxFrame:itemFrames[0]];
	NSRect item2Frame = [self unboxFrame:itemFrames[1]];
	XCTAssertEqual(item1Frame.origin.x, 0);
	XCTAssertEqual(item2Frame.origin.x, 0); // new row
	XCTAssertEqual(item2Frame.origin.y, item1Frame.origin.y + item1Frame.size.height + lineSpacing);
}

- (void)testRowHeightIsDerivedFromTallestItem {

	NSNumber *tallestItemHeight = @4;
	CGFloat verticalSpacing = 2.0f;
	NSArray *itemWidths = @[@1, @1, @1];
	NSArray *itemHeights = @[@1, tallestItemHeight, @1];
	CGFloat collectionViewWidth = 3;

	NSArray *itemFrames = [self framesAfterLayoutForItemsOfWidth:itemWidths
	                                                     heights:itemHeights
		                                   withHorizontalSpacing:1.0f
								                 verticalSpacing:verticalSpacing
											 collectionViewWidth:collectionViewWidth];

	NSRect rect3 = [self unboxFrame:itemFrames[2]];

	XCTAssertEqual(rect3.origin.y, [tallestItemHeight floatValue] + verticalSpacing);
}

- (void)testFirstRowIsLaidOutBelowHeader {
	CGFloat headerHeight = 20.0f;
	NSArray *itemWidths = @[@10];
	NSArray *itemHeights = @[@10];

	NSArray *itemFrames = [self framesAfterLayoutForItemsOfWidth:itemWidths
	                                                     heights:itemHeights
		                                   withHorizontalSpacing:10
								                 verticalSpacing:0.0f
											        headerHeight:headerHeight
													footerHeight:0.0f
											 collectionViewWidth:15.0f];

	NSRect itemFrame = [self unboxFrame:itemFrames[0]];
	XCTAssertEqual(itemFrame.origin.y,  headerHeight);
}

- (void)testSubsequentSectionStartsBelowPreviousSection {

	NSNumber *itemsHeight = @20;
	NSArray *itemFrames = [self framesAfterLayoutForItemsOfWidth:@[@10]
	                                                     heights:@[itemsHeight]
		                                   withHorizontalSpacing:0.0f
								                 verticalSpacing:0.0f
											        headerHeight:0.0f
													footerHeight:0.0f
											 collectionViewWidth:100.0f
												numberOfSections:2];

	NSRect item2Frame = [self unboxFrame:itemFrames[1]];

	XCTAssertEqual(item2Frame.origin.y, [itemsHeight floatValue]);
}

#pragma mark - Alignment
- (void)testCentreAlignmentInSoleRow {
    
    NSArray *itemFrames = [self framesAfterLayoutForItemsOfWidth:@[@10, @10] heights:@[@10, @20] withHorizontalSpacing:0 verticalSpacing:0 headerHeight:0 footerHeight:0 itemAlignment:JNWCollectionViewFlowLayoutAlignmentCentre collectionViewWidth:40 numberOfSections:1];
    
    NSRect itemFrame = [self unboxFrame:itemFrames[0]];
    XCTAssertEqual(itemFrame.origin.y, 5);
}

- (void)testCentreAlignmentInFirstRow {
    
    NSArray *itemFrames = [self framesAfterLayoutForItemsOfWidth:@[@10, @10, @10] heights:@[@10, @20, @10] withHorizontalSpacing:0 verticalSpacing:0 headerHeight:0 footerHeight:0 itemAlignment:JNWCollectionViewFlowLayoutAlignmentCentre collectionViewWidth:20 numberOfSections:1];
    
    NSRect itemFrame = [self unboxFrame:itemFrames[0]];
    XCTAssertEqual(itemFrame.origin.y, 5);
}

- (void)testCentreAlignmentInSubsequentRow {
    
    NSArray *itemFrames = [self framesAfterLayoutForItemsOfWidth:@[@10, @10, @10, @10] heights:@[@10, @20, @10, @20] withHorizontalSpacing:0 verticalSpacing:0 headerHeight:0 footerHeight:0 itemAlignment:JNWCollectionViewFlowLayoutAlignmentCentre collectionViewWidth:20 numberOfSections:1];
    
    NSRect itemFrame = [self unboxFrame:itemFrames[2]];
    XCTAssertEqual(itemFrame.origin.y, 25);
}

- (void)testBottomAlignmentInSoleRow {
    
    NSArray *itemFrames = [self framesAfterLayoutForItemsOfWidth:@[@10, @10] heights:@[@10, @20] withHorizontalSpacing:0 verticalSpacing:0 headerHeight:0 footerHeight:0 itemAlignment:JNWCollectionViewFlowLayoutAlignmentBottom collectionViewWidth:40 numberOfSections:1];
    
    NSRect itemFrame = [self unboxFrame:itemFrames[0]];
    XCTAssertEqual(itemFrame.origin.y, 10);
}

#pragma mark - Optional JNWCollectionViewLayout Overrides
#pragma mark (CGRect)rectForSectionAtIndex:(NSInteger)sectionIndex {
- (void)testLayoutCalculatesCorrectSectionRectForOneRow {
    [self framesAfterLayoutForItemsOfWidth:@[@10] heights:@[@10] withHorizontalSpacing:0 verticalSpacing:10 headerHeight:0 footerHeight:0 collectionViewWidth:100 numberOfSections:1];
    
    NSRect rectForSection1 = [sut rectForSectionAtIndex:0];
    
    XCTAssertTrue(CGRectEqualToRect(rectForSection1, CGRectMake(0, 0, 100, 10)));
}

- (void)testLayoutCalculatesCorrectSectionRectForSectionWithMultipleRows {
    [self framesAfterLayoutForItemsOfWidth:@[@10, @10, @10] heights:@[@10, @10, @10] withHorizontalSpacing:5 verticalSpacing:5 headerHeight:0 footerHeight:0 collectionViewWidth:20 numberOfSections:1];
    
    NSRect rectForSection1 = [sut rectForSectionAtIndex:0];
    
    XCTAssertTrue(CGRectEqualToRect(rectForSection1, CGRectMake(0, 0, 20, 40)));
}

- (void)testLayoutCalculatesCorrectSectionOriginForSecondSection {
    [self framesAfterLayoutForItemsOfWidth:@[@10, @10] heights:@[@10, @10] withHorizontalSpacing:5 verticalSpacing:0 headerHeight:0 footerHeight:0 collectionViewWidth:20 numberOfSections:2];
    
    NSRect rectForSection2 = [sut rectForSectionAtIndex:1];
    
    NSLog(@"was: %@", NSStringFromRect(rectForSection2));
    XCTAssertTrue(CGRectEqualToRect(rectForSection2, CGRectMake(0, 20, 20, 20)));
}

#pragma mark (NSArray *)indexPathsForItemsInRect:(CGRect)rect {
- (void)testNoIndexPathsForNoItems {
    [self framesAfterLayoutForItemsOfWidth:@[] heights:@[] withHorizontalSpacing:0 verticalSpacing:0 headerHeight:0 footerHeight:0 collectionViewWidth:20 numberOfSections:1];
    
    NSArray *indexPaths = [sut indexPathsForItemsInRect:NSMakeRect(0, 0, 20, 1000)];
    
    XCTAssertEqual(indexPaths.count, 0);
}

- (void)testIncludesIndexPathForSingleItem {
    [self framesAfterLayoutForItemsOfWidth:@[@10] heights:@[@10] withHorizontalSpacing:0 verticalSpacing:0 headerHeight:0 footerHeight:0 collectionViewWidth:20 numberOfSections:1];
    
    NSArray *indexPaths = [sut indexPathsForItemsInRect:NSMakeRect(0, 0, 20, 1000)];
    
    XCTAssertEqual(indexPaths.count, 1);
}

- (void)testExcludesIndexPathForItemOutsideOfRect {
    [self framesAfterLayoutForItemsOfWidth:@[@10, @10] heights:@[@10, @10] withHorizontalSpacing:5 verticalSpacing:0 headerHeight:0 footerHeight:0 collectionViewWidth:15 numberOfSections:1];
    
    NSArray *indexPaths = [sut indexPathsForItemsInRect:NSMakeRect(0, 0, 10, 10)];
    
    XCTAssertEqual(indexPaths.count, 1);
}

- (void)testIncludesIndexPathsForSubsequentSections {
    [self framesAfterLayoutForItemsOfWidth:@[@10, @10] heights:@[@10, @10] withHorizontalSpacing:5 verticalSpacing:0 headerHeight:0 footerHeight:0 collectionViewWidth:15 numberOfSections:2];
    
    NSArray *indexPaths = [sut indexPathsForItemsInRect:NSMakeRect(0, 20, 10, 10)];
    
    XCTAssertTrue([indexPaths[0] isEqual:[NSIndexPath jnw_indexPathForItem:0 inSection:1]]);
}

#pragma mark - Test utilities

- (NSRect)unboxFrame:(NSValue *)boxedFrame {

	NSRect unboxedRect;
	[boxedFrame getValue:&unboxedRect];
	return unboxedRect;
}

// for tests with unvarying item heights
- (NSArray *)framesAfterLayoutForItemsOfWidth:(NSArray *)itemWidths
                        withHorizontalSpacing:(CGFloat)interItemSpacing
					          verticalSpacing:(CGFloat)lineSpacing
						  collectionViewWidth:(CGFloat)collectionViewWidth {

	NSMutableArray *itemHeights = [NSMutableArray array];
	for (int i = 0; i < itemWidths.count; i++) {
		[itemHeights addObject:@10];
	}

	return [self framesAfterLayoutForItemsOfWidth:itemWidths
	                                      heights:itemHeights
		                    withHorizontalSpacing:interItemSpacing
								  verticalSpacing:lineSpacing
							  collectionViewWidth:collectionViewWidth];
}

// Number of items is determined by the itemWidths/Heights arrays (which must have equal counts)
- (NSArray *)framesAfterLayoutForItemsOfWidth:(NSArray *)itemWidths
                                      heights:(NSArray *)itemHeights
	                    withHorizontalSpacing:(CGFloat)interItemSpacing
							  verticalSpacing:(CGFloat)lineSpacing
						  collectionViewWidth:(CGFloat)collectionViewWidth {

	return [self framesAfterLayoutForItemsOfWidth:itemWidths
	                                      heights:itemHeights
		                    withHorizontalSpacing:interItemSpacing
								  verticalSpacing:lineSpacing
									 headerHeight:0.0f
									 footerHeight:0.0f
							  collectionViewWidth:collectionViewWidth];
}

- (NSArray *)framesAfterLayoutForItemsOfWidth:(NSArray *)itemWidths
                                      heights:(NSArray *)itemHeights
	                    withHorizontalSpacing:(CGFloat)interItemSpacing
							  verticalSpacing:(CGFloat)lineSpacing
								 headerHeight:(CGFloat)headerHeight
								 footerHeight:(CGFloat)footerHeight
						  collectionViewWidth:(CGFloat)collectionViewWidth {

	return [self framesAfterLayoutForItemsOfWidth:itemWidths
	                                      heights:itemHeights
		                    withHorizontalSpacing:interItemSpacing
								  verticalSpacing:lineSpacing
									 headerHeight:headerHeight
									 footerHeight:footerHeight
							  collectionViewWidth:collectionViewWidth
								 numberOfSections:1];
}

// currently assumes each section has the same item number and sizes
// NB: configured sut is an ivar
- (NSArray *)framesAfterLayoutForItemsOfWidth:(NSArray *)itemWidths
                                      heights:(NSArray *)itemHeights
	                    withHorizontalSpacing:(CGFloat)interItemSpacing
							  verticalSpacing:(CGFloat)lineSpacing
								 headerHeight:(CGFloat)headerHeight
								 footerHeight:(CGFloat)footerHeight
						  collectionViewWidth:(CGFloat)collectionViewWidth
							 numberOfSections:(NSInteger)sections {

    return [self framesAfterLayoutForItemsOfWidth:itemWidths heights:itemHeights withHorizontalSpacing:interItemSpacing verticalSpacing:lineSpacing headerHeight:headerHeight footerHeight:footerHeight itemAlignment:JNWCollectionViewFlowLayoutAlignmentTop collectionViewWidth:collectionViewWidth numberOfSections:sections];
}

- (NSArray *)framesAfterLayoutForItemsOfWidth:(NSArray *)itemWidths
                                      heights:(NSArray *)itemHeights
	                    withHorizontalSpacing:(CGFloat)interItemSpacing
							  verticalSpacing:(CGFloat)lineSpacing
								 headerHeight:(CGFloat)headerHeight
								 footerHeight:(CGFloat)footerHeight
                                itemAlignment:(JNWCollectionViewFlowLayoutAlignment)alignment
						  collectionViewWidth:(CGFloat)collectionViewWidth
							 numberOfSections:(NSInteger)sections {
    
	NSAssert(itemWidths.count == itemHeights.count, @"itemWidths and Heights must have equal counts");
    
	collectionView = [[CollectionViewStub alloc]
                      initWithNumberOfItems:itemWidths.count
                      sections:sections
                      contentSize:(NSSize) {.width = collectionViewWidth, .height = 1000}];
    
	sut = [[JNWCollectionViewFlowLayout alloc] initWithCollectionView:(id) collectionView];
	sut.minimumInterItemSpacing = interItemSpacing;
	sut.minimumLineSpacing = lineSpacing;
    sut.alignment = alignment;
	DelegateStub *delegate = [DelegateStub new];
	delegate.itemSizeBlock = ^(NSIndexPath *indexPath) {
		NSInteger itemIndex = [indexPath indexAtPosition:1];
		NSNumber *itemWidth = itemWidths[itemIndex];
		NSNumber *itemHeight = itemHeights[itemIndex];
		CGSize size = CGSizeMake([itemWidth floatValue], [itemHeight floatValue]);
		return size;
	};
	delegate.headerHeight = headerHeight;
	delegate.footerHeight = footerHeight;
	sut.delegate = delegate;
    
	[sut prepareLayout];
    
	NSMutableArray *itemFrames = [NSMutableArray array];
	for (int sectionIndex = 0; sectionIndex < sections; sectionIndex++) {
		// section index
		NSIndexPath *sectionIndexPath = [NSIndexPath indexPathWithIndex:sectionIndex];
		for (int itemIndex = 0; itemIndex < itemWidths.count; itemIndex++) {
			NSIndexPath *itemIndexPath = [sectionIndexPath indexPathByAddingIndex:itemIndex];
			JNWCollectionViewLayoutAttributes *itemLayoutAttributes = [sut layoutAttributesForItemAtIndexPath:itemIndexPath];
			NSRect frame = itemLayoutAttributes.frame;
			NSValue *boxedFrame = [NSValue valueWithBytes:&frame objCType:@encode(NSRect)];
			[itemFrames addObject:boxedFrame];
		}
	}
    
	return itemFrames;
}

@end
