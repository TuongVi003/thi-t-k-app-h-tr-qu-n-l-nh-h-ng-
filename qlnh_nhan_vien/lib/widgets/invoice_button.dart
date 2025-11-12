import 'package:flutter/material.dart';
import '../services/invoice_service.dart';
import '../utils/invoice_pdf.dart';

class InvoiceButton extends StatefulWidget {
  final int? hoaDonId;
  final String label;

  /// If [hoaDonId] is null, the widget will prompt the user to enter an invoice ID before fetching.
  const InvoiceButton({Key? key, this.hoaDonId, this.label = 'In hóa đơn'}) : super(key: key);

  @override
  State<InvoiceButton> createState() => _InvoiceButtonState();
}

class _InvoiceButtonState extends State<InvoiceButton> {
  bool _loading = false;

  Future<void> _onPressed() async {
    setState(() => _loading = true);
    try {
      int? id = widget.hoaDonId;
      if (id == null) {
        // prompt user to enter invoice id
        final text = await showDialog<String?>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Nhập mã hóa đơn'),
            content: TextField(
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'ID hóa đơn'),
              onSubmitted: (v) => Navigator.of(context).pop(v),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(null), child: const Text('Hủy')),
              ElevatedButton(onPressed: () => Navigator.of(context).pop(null), child: const Text('OK')),
            ],
          ),
        );

        if (text == null) return;
        id = int.tryParse(text);
        if (id == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ID không hợp lệ')));
          }
          return;
        }
      }

      final invoice = await InvoiceService.getInvoice(id);
      if (!mounted) return;
      await _showOptions(invoice);
    } catch (e) {
      final msg = e.toString();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $msg')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showOptions(Map<String, dynamic> invoice) async {
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.preview),
                title: const Text('Xem trước'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => InvoicePreviewPage(invoice: invoice)));
                },
              ),
              ListTile(
                leading: const Icon(Icons.print),
                title: const Text('In (gửi tới máy in hệ thống)'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  if (!mounted) return;
                  try {
                    setState(() => _loading = true);
                    await InvoicePdf.printDirect(invoice);
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lệnh in đã gửi')));
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi in: ${e.toString()}')));
                  } finally {
                    if (mounted) setState(() => _loading = false);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.save),
                title: const Text('Lưu file PDF'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  if (!mounted) return;
                  try {
                    setState(() => _loading = true);
                    final path = await InvoicePdf.saveToFile(invoice);
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã lưu: $path')));
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi lưu: ${e.toString()}')));
                  } finally {
                    if (mounted) setState(() => _loading = false);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Chia sẻ'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  if (!mounted) return;
                  try {
                    setState(() => _loading = true);
                    await InvoicePdf.share(invoice);
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi chia sẻ: ${e.toString()}')));
                  } finally {
                    if (mounted) setState(() => _loading = false);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _loading ? null : _onPressed,
      icon: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.print),
      label: Text(_loading ? 'Đang xử lý...' : widget.label),
    );
  }
}

/// A small preview page that shows the PDF using PdfPreview and provides a download button.
class InvoicePreviewPage extends StatefulWidget {
  final Map<String, dynamic> invoice;

  const InvoicePreviewPage({Key? key, required this.invoice}) : super(key: key);

  @override
  State<InvoicePreviewPage> createState() => _InvoicePreviewPageState();
}

class _InvoicePreviewPageState extends State<InvoicePreviewPage> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xem trước hóa đơn'),
        actions: [
          IconButton(
            icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.download),
            onPressed: _saving
                ? null
                : () async {
                    setState(() => _saving = true);
                    try {
                      final path = await InvoicePdf.saveToFile(widget.invoice);
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã lưu: $path')));
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi lưu: ${e.toString()}')));
                    } finally {
                      if (mounted) setState(() => _saving = false);
                    }
                  },
          )
        ],
      ),
      body: HeroMode(
        enabled: false,
        child: InvoicePdf.previewWidget(widget.invoice),
      ),
    );
  }
}
