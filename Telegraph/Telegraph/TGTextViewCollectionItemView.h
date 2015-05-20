#import "TGCollectionItemView.h"

@interface TGTextViewCollectionItemView : TGCollectionItemView

@property (nonatomic, copy) void (^textChanged)(NSString *);

- (void)setText:(NSString *)text;

- (void)setPlaceHolder:(NSString *)placeHolder;

@end
