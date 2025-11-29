import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/invoice.dart';

class InvoicePdfGenerator {
  // Receipt size (80mm thermal printer width, auto height)
  static const PdfPageFormat receiptFormat = PdfPageFormat(
    80 * PdfPageFormat.mm,
    double.infinity,
    marginAll: 5 * PdfPageFormat.mm,
  );

  static Future<void> generateAndPrintInvoice(Invoice invoice) async {
    // Load Vietnamese-compatible font from Google Fonts
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: receiptFormat,
        theme: pw.ThemeData.withFont(
          base: font,
          bold: fontBold,
        ),
        build: (context) => _buildInvoiceContent(invoice),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Hoa_don_${invoice.id}.pdf',
    );
  }

  static pw.Widget _buildInvoiceContent(Invoice invoice) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'vi_VN');

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Header
        pw.Center(
          child: pw.Column(
            children: [
              pw.Text(
                'NHÀ HÀNG',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'HÓA ĐƠN THANH TOÁN',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Số hóa đơn: #${invoice.id}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
        ),

        pw.Divider(thickness: 1),

        // Date and customer info
        pw.Text(
          'Ngày: ${dateFormat.format(invoice.ngayTao)}',
          style: const pw.TextStyle(fontSize: 9),
        ),
        pw.SizedBox(height: 4),
        if (invoice.khachHangInfo != null) ...[
          pw.Text(
            'Khách hàng: ${invoice.khachHangInfo!.hoTen}',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.Text(
            'SĐT: ${invoice.khachHangInfo!.soDienThoai}',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ] else ...[
          pw.Text(
            'Khách hàng: Khách vãng lai',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ],

        pw.Divider(thickness: 1),

        // Items header
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              flex: 4,
              child: pw.Text(
                'Món ăn',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Expanded(
              flex: 1,
              child: pw.Text(
                'SL',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Expanded(
              flex: 2,
              child: pw.Text(
                'Giá',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.right,
              ),
            ),
            pw.Expanded(
              flex: 2,
              child: pw.Text(
                'Thành tiền',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),

        pw.Divider(thickness: 0.5),

        // Items
        ...invoice.chiTietMonAn.map((item) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 6),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                flex: 4,
                child: pw.Text(
                  item.tenMon,
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Text(
                  'x${item.soLuong}',
                  style: const pw.TextStyle(fontSize: 9),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  currencyFormat.format(item.giaDonVi),
                  style: const pw.TextStyle(fontSize: 9),
                  textAlign: pw.TextAlign.right,
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  currencyFormat.format(item.thanhTien),
                  style: const pw.TextStyle(fontSize: 9),
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          ),
        )),

        pw.Divider(thickness: 1),

        // Subtotal
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Tổng tiền món ăn:',
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.Text(
              currencyFormat.format(invoice.tongTienMonAn),
              style: const pw.TextStyle(fontSize: 9),
            ),
          ],
        ),

        // Discount
        if (invoice.tongGiamGia > 0) ...[
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Giảm giá:',
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.Text(
                '- ${currencyFormat.format(invoice.tongGiamGia)}',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ],
          ),
        ],

        // Shipping fee
        if (double.tryParse(invoice.phiGiaoHang) != null && 
            double.parse(invoice.phiGiaoHang) > 0) ...[
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Phí giao hàng:',
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.Text(
                currencyFormat.format(double.parse(invoice.phiGiaoHang)),
                style: const pw.TextStyle(fontSize: 9),
              ),
            ],
          ),
        ],

        pw.Divider(thickness: 1),

        // Total
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'TỔNG CỘNG:',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text(
              currencyFormat.format(invoice.tongTienCuoiCung),
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),

        pw.Divider(thickness: 1),

        // Payment method
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Hình thức thanh toán:',
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.Text(
              invoice.paymentMethodDisplay,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),

        pw.SizedBox(height: 12),

        // Footer
        pw.Center(
          child: pw.Column(
            children: [
              pw.Text(
                'Cảm ơn quý khách!',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Hẹn gặp lại!',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
