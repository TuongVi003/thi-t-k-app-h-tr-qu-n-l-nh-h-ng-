import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';

/// Utility to generate invoice PDF from invoice JSON returned by the backend.
class InvoicePdf {
  /// Generate PDF bytes for the given invoice JSON map.
  /// The expected shape is the API response for /api/hoadon/{id}/
  static Future<Uint8List> generate(Map<String, dynamic> invoice) async {
    final pdf = pw.Document();

    final currency = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

    final order = invoice['order'] as Map<String, dynamic>? ?? {};
    final items = (order['chi_tiet_order'] as List<dynamic>?) ?? <dynamic>[];
    final tongTien = invoice['tong_tien'] != null ? double.tryParse(invoice['tong_tien'].toString()) ?? 0.0 : (order['tong_tien'] ?? 0);
    final paymentMethod = invoice['payment_method'] as String? ?? order['phuong_thuc_giao_hang'] as String? ?? '';
    final ngayTao = invoice['ngay_tao'] as String? ?? '';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(24),
        build: (context) {
          return [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text('HÓA ĐƠN', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 6),
                  pw.Text('Ngày: $ngayTao', style: pw.TextStyle(fontSize: 10)),
                ]),
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                  pw.Text('Mã hóa đơn: ${invoice['id']}', style: pw.TextStyle(fontSize: 12)),
                  pw.Text('Đơn hàng: ${order['id'] ?? ''}', style: pw.TextStyle(fontSize: 10)),
                ]),
              ],
            ),
            pw.SizedBox(height: 16),

            pw.Text('Chi tiết đơn hàng', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),

            pw.Table.fromTextArray(
              headers: ['Món', 'SL', 'Đơn giá', 'Thành tiền'],
              data: items.map((it) {
                final item = it as Map<String, dynamic>;
                final mon = item['mon_an_detail'] as Map<String, dynamic>?;
                final ten = mon != null ? mon['ten_mon'] ?? '' : (item['ten_mon'] ?? '');
                final sl = item['so_luong']?.toString() ?? '1';
                final gia = (item['gia'] != null) ? double.tryParse(item['gia'].toString()) ?? 0.0 : 0.0;
                final thanh = gia * (double.tryParse(sl) ?? 1);
                return [ten.toString(), sl, currency.format(gia), currency.format(thanh)];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerLeft,
              headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
              cellPadding: pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            ),

            pw.Divider(),
            pw.Container(
              alignment: pw.Alignment.centerRight,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Tổng cộng: ${currency.format(tongTien)}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.green)),
                  pw.SizedBox(height: 4),
                  pw.Text('Phương thức thanh toán: ${_paymentLabel(paymentMethod)}', style: pw.TextStyle(fontSize: 11)),
                ],
              ),
            ),

            pw.SizedBox(height: 24),
            pw.Text('Cám ơn quý khách!', style: pw.TextStyle(fontSize: 12)),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// Returns a widget that previews the PDF and allows printing/sharing.
  /// Use inside a navigation route or dialog.
  static Widget previewWidget(Map<String, dynamic> invoice) {
    return PdfPreview(
      build: (format) async => await generate(invoice),
      allowPrinting: true,
      allowSharing: true,
      dynamicLayout: false,
    );
  }

  /// Print directly to the system printer.
  static Future<void> printDirect(Map<String, dynamic> invoice) async {
    final bytes = await generate(invoice);
    await Printing.layoutPdf(onLayout: (format) => bytes);
  }

  /// Save the generated PDF to the app documents directory and return the file path.
  /// On most platforms this will be a user-accessible folder. Caller should inform the user.
  static Future<String> saveToFile(Map<String, dynamic> invoice) async {
    final bytes = await generate(invoice);
    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'invoice_${invoice['id'] ?? DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  /// Share the PDF using the platform share sheet.
  static Future<void> share(Map<String, dynamic> invoice) async {
    final bytes = await generate(invoice);
    final name = 'invoice_${invoice['id'] ?? DateTime.now().millisecondsSinceEpoch}.pdf';
    await Printing.sharePdf(bytes: bytes, filename: name);
  }

  /// Print/preview invoice by fetching data externally and generating PDF.
  static Future<void> printInvoiceFromJson(Map<String, dynamic> invoice) async {
    final bytes = await generate(invoice);
    await Printing.layoutPdf(onLayout: (format) => bytes);
  }

  static String _paymentLabel(String key) {
    switch (key) {
      case 'cash':
        return 'Tiền mặt';
      case 'card':
        return 'Thẻ/QR';
      default:
        return key;
    }
  }
}
