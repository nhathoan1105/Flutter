class FoodItem {
  final String name;
  final String serving;
  final int calories;
  final String category;

  const FoodItem(this.name, this.serving, this.calories, this.category);
}

/// Approximate calories per typical serving.
const foodDatabase = <FoodItem>[
  // Món chính
  FoodItem('Phở bò', '1 tô', 450, 'Món chính'),
  FoodItem('Bún bò Huế', '1 tô', 480, 'Món chính'),
  FoodItem('Bún chả', '1 phần', 500, 'Món chính'),
  FoodItem('Cơm tấm sườn', '1 đĩa', 600, 'Món chính'),
  FoodItem('Bánh mì thịt', '1 ổ', 400, 'Món chính'),
  FoodItem('Mì Quảng', '1 tô', 450, 'Món chính'),
  FoodItem('Hủ tiếu', '1 tô', 400, 'Món chính'),
  FoodItem('Bánh cuốn', '1 đĩa', 300, 'Món chính'),
  FoodItem('Xôi mặn', '1 gói', 400, 'Món chính'),
  FoodItem('Cháo gà', '1 tô', 250, 'Món chính'),
  FoodItem('Cơm chiên', '1 đĩa', 550, 'Món chính'),
  FoodItem('Bánh bao nhân thịt', '1 cái', 300, 'Món chính'),
  FoodItem('Gỏi cuốn', '1 cuốn', 70, 'Món chính'),
  // Thành phần
  FoodItem('Cơm trắng', '1 chén', 200, 'Thành phần'),
  FoodItem('Trứng gà luộc', '1 quả', 75, 'Thành phần'),
  FoodItem('Ức gà luộc', '100 g', 165, 'Thành phần'),
  FoodItem('Thịt heo nạc', '100 g', 145, 'Thành phần'),
  FoodItem('Thịt bò', '100 g', 250, 'Thành phần'),
  FoodItem('Cá hồi', '100 g', 210, 'Thành phần'),
  FoodItem('Đậu hũ', '100 g', 80, 'Thành phần'),
  FoodItem('Rau luộc', '1 đĩa', 50, 'Thành phần'),
  FoodItem('Khoai lang luộc', '1 củ (150 g)', 130, 'Thành phần'),
  FoodItem('Yến mạch', '40 g', 150, 'Thành phần'),
  // Trái cây
  FoodItem('Chuối', '1 quả', 105, 'Trái cây'),
  FoodItem('Táo', '1 quả', 95, 'Trái cây'),
  FoodItem('Cam', '1 quả', 60, 'Trái cây'),
  FoodItem('Xoài', '1 quả', 200, 'Trái cây'),
  FoodItem('Dưa hấu', '1 miếng (300 g)', 90, 'Trái cây'),
  // Đồ uống & ăn vặt
  FoodItem('Sữa tươi', '1 hộp 180 ml', 120, 'Đồ uống'),
  FoodItem('Sữa chua', '1 hũ', 100, 'Đồ uống'),
  FoodItem('Cà phê sữa đá', '1 ly', 150, 'Đồ uống'),
  FoodItem('Trà sữa trân châu', '1 ly', 450, 'Đồ uống'),
  FoodItem('Nước ngọt', '1 lon', 140, 'Đồ uống'),
  FoodItem('Bia', '1 lon', 150, 'Đồ uống'),
  FoodItem('Bánh snack', '1 gói', 160, 'Ăn vặt'),
  FoodItem('Chè', '1 ly', 300, 'Ăn vặt'),
];
