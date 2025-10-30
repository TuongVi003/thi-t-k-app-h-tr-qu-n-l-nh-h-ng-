# Hướng dẫn sử dụng tính năng chọn vị trí giao hàng

## Tổng quan
Tính năng này cho phép khách hàng chọn vị trí giao hàng trên bản đồ khi đặt hàng mang về với phương thức "Giao hàng tận nơi".

## Các file đã thay đổi

### 1. `lib/presentations/screens/location_picker_screen.dart` (MỚI)
Màn hình chọn vị trí trên bản đồ sử dụng `flutter_map`.

**Tính năng:**
- Hiển thị bản đồ OpenStreetMap
- Cho phép người dùng chạm vào bản đồ để chọn vị trí
- Hiển thị marker tại vị trí đã chọn
- Nhập địa chỉ chi tiết kèm theo tọa độ
- Xác nhận và trả về thông tin vị trí + địa chỉ

**Sử dụng:**
```dart
final locationResult = await Navigator.push<Map<String, dynamic>?>(
  context,
  MaterialPageRoute(
    builder: (context) => const LocationPickerScreen(),
  ),
);

if (locationResult != null) {
  LatLng location = locationResult['location'];
  String address = locationResult['address'];
  String formattedAddress = locationResult['formattedAddress'];
}
```

### 2. `lib/presentations/screens/cart_page.dart` (CẬP NHẬT)
Tích hợp tính năng chọn vị trí vào quy trình đặt hàng.

**Thay đổi:**
- Import `latlong2` và `location_picker_screen.dart`
- Thêm biến `viTriGiaoHang` để lưu tọa độ
- Tách dialog chọn phương thức giao hàng thành 2 bước:
  1. Chọn phương thức (Tự đến lấy / Giao hàng tận nơi)
  2. Nếu chọn "Giao hàng tận nơi", mở màn hình chọn vị trí trên bản đồ
- Gửi `latitude` và `longitude` kèm theo API request

### 3. `lib/presentations/takeaway/service/takeaway_service.dart` (CẬP NHẬT)
Thêm tham số `latitude` và `longitude` vào hàm `createTakeawayOrder()`.

**Thay đổi:**
```dart
static Future<TakeawayOrder> createTakeawayOrder({
  // ... các tham số cũ
  double? latitude,
  double? longitude,
}) async {
  // ...
  final orderData = {
    // ...
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
  };
  // ...
}
```

## Quy trình đặt hàng với giao hàng tận nơi

1. **Khách hàng thêm món vào giỏ hàng**
2. **Nhấn "Đặt hàng mang về"**
3. **Chọn ngày lấy món** (Date picker)
4. **Chọn giờ lấy món** (Time picker với validation không được chọn quá khứ)
5. **Chọn phương thức giao hàng** (Dialog)
   - Tự đến lấy
   - Giao hàng tận nơi
6. **Nếu chọn "Giao hàng tận nơi":**
   - Mở màn hình bản đồ (`LocationPickerScreen`)
   - Chạm vào bản đồ để chọn vị trí
   - Nhập địa chỉ chi tiết (số nhà, đường, phường, quận,...)
   - Xác nhận vị trí
7. **Gửi đơn hàng lên server** với thông tin:
   - `phuong_thuc_giao_hang`: "Giao hàng tận nơi"
   - `dia_chi_giao_hang`: "Địa chỉ chi tiết (lat, lng)"
   - `latitude`: 10.123456
   - `longitude`: 106.654321
8. **Hiển thị màn hình thành công**

## Thư viện sử dụng

### flutter_map ^8.2.2
- Hiển thị bản đồ OpenStreetMap
- Hỗ trợ marker, tile layer, interaction

### latlong2 ^0.9.0
- Xử lý tọa độ địa lý (LatLng)
- Tính toán khoảng cách, bearing, etc.

## Lưu ý

1. **Vị trí mặc định:** Trung tâm TP.HCM (10.8231, 106.6297)
2. **OpenStreetMap Tiles:** Sử dụng tile miễn phí từ `tile.openstreetmap.org`
3. **User Agent:** Cần thiết lập trong `urlTemplate` để tuân thủ OSM usage policy
4. **Validation:** 
   - Bắt buộc nhập địa chỉ chi tiết
   - Bắt buộc chọn vị trí trên bản đồ
5. **Backend:** Server cần hỗ trợ nhận và lưu trữ `latitude`, `longitude`

## Mở rộng trong tương lai

1. **Geocoding:** Chuyển đổi địa chỉ thành tọa độ và ngược lại
2. **Current Location:** Tự động lấy vị trí hiện tại của người dùng
3. **Search:** Tìm kiếm địa điểm trên bản đồ
4. **Distance Calculation:** Tính khoảng cách và phí ship dựa trên vị trí
5. **Delivery Zones:** Giới hạn khu vực giao hàng
6. **Route Planning:** Hiển thị đường đi từ nhà hàng đến địa chỉ giao hàng

## Backend API Requirements

Server cần cập nhật API endpoint `/api/takeaway/` để nhận thêm 2 fields:

```python
# Example Django model
class TakeawayOrder(models.Model):
    # ... existing fields
    phuong_thuc_giao_hang = models.CharField(max_length=50, null=True, blank=True)
    dia_chi_giao_hang = models.TextField(null=True, blank=True)
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)
```

Response trả về cũng nên bao gồm các trường này để hiển thị lại trên UI.
