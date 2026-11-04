import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/constants/skills.dart';

class BillService {
  static const _orange = PdfColor.fromInt(0xFFF97316);
  static const _blue = PdfColor.fromInt(0xFF1E40AF);
  static const _grey = PdfColor.fromInt(0xFF6B7280);
  static const _light = PdfColor.fromInt(0xFFF3F4F6);
  static const _green = PdfColor.fromInt(0xFF16A34A);

  static pw.Widget _label(String t) => pw.Text(t,
      style: pw.TextStyle(
          fontSize: 8, color: _grey, fontWeight: pw.FontWeight.bold));

  static pw.Widget _party(String title, String name, List<String> lines) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: _light,
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _label(title),
            pw.SizedBox(height: 6),
            pw.Text(name,
                style: pw.TextStyle(
                    fontSize: 13, fontWeight: pw.FontWeight.bold)),
            ...lines.map((l) => pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 2),
                  child: pw.Text(l,
                      style: const pw.TextStyle(fontSize: 10, color: _grey)),
                )),
          ],
        ),
      ),
    );
  }

  static pw.Widget _cell(String t,
      {bool bold = false,
      bool right = false,
      PdfColor color = PdfColors.black}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: pw.Text(t,
          textAlign: right ? pw.TextAlign.right : pw.TextAlign.left,
          style: pw.TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
    );
  }

  static pw.Widget _totalRow(String l, String v,
      {bool big = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(l,
              style: pw.TextStyle(
                  fontSize: big ? 14 : 11,
                  fontWeight: big ? pw.FontWeight.bold : pw.FontWeight.normal,
                  color: big ? PdfColors.black : _grey)),
          pw.Text(v,
              style: pw.TextStyle(
                  fontSize: big ? 18 : 11,
                  fontWeight: pw.FontWeight.bold,
                  color: color ?? PdfColors.black)),
        ],
      ),
    );
  }

  static Future<void> show(String requestId, Map<String, dynamic> r) async {
    final db = FirebaseFirestore.instance;
    final owner =
        (await db.collection('users').doc(r['ownerId']).get()).data();
    final worker =
        (await db.collection('users').doc(r['workerId']).get()).data();
    final skill = allSkills.firstWhere((s) => s.id == r['skillId']).en;
    final paidAt = (r['paidAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final date = DateFormat('dd MMM yyyy').format(paidAt);
    final time = DateFormat('hh:mm a').format(paidAt);
    final receiptNo = 'KW-${requestId.substring(0, 8).toUpperCase()}';
    final wage = (r['wagePerDay'] as num).toInt();
    final method = '${r['paymentMethod'] ?? '-'}';
    final payId = r['razorpayPaymentId'];

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header band
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: _orange,
                borderRadius: pw.BorderRadius.circular(12),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('KovaiWorks',
                          style: pw.TextStyle(
                              fontSize: 26,
                              color: PdfColors.white,
                              fontWeight: pw.FontWeight.bold)),
                      pw.Text('Velaiku Aalu Ready',
                          style: const pw.TextStyle(
                              fontSize: 11, color: PdfColors.white)),
                      pw.Text('Coimbatore, Tamil Nadu',
                          style: const pw.TextStyle(
                              fontSize: 9, color: PdfColors.white)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('WAGE RECEIPT',
                          style: pw.TextStyle(
                              fontSize: 16,
                              color: PdfColors.white,
                              fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 4),
                      pw.Text('No: $receiptNo',
                          style: const pw.TextStyle(
                              fontSize: 10, color: PdfColors.white)),
                      pw.Text('Date: $date',
                          style: const pw.TextStyle(
                              fontSize: 10, color: PdfColors.white)),
                      pw.Text('Time: $time',
                          style: const pw.TextStyle(
                              fontSize: 10, color: PdfColors.white)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Parties
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _party('PAID BY (EMPLOYER)', '${owner?['businessName'] ?? '-'}',
                    [
                  '${owner?['name'] ?? ''}',
                  '${r['area']}, Coimbatore',
                  '${owner?['phone'] ?? ''}',
                ]),
                pw.SizedBox(width: 12),
                _party('PAID TO (WORKER)', '${worker?['name'] ?? '-'}', [
                  'Skill: $skill',
                  '${worker?['area'] ?? ''}, Coimbatore',
                  '${worker?['phone'] ?? ''}',
                ]),
              ],
            ),
            pw.SizedBox(height: 20),

            // Items table
            pw.Table(
              border: const pw.TableBorder(
                bottom: pw.BorderSide(color: _light, width: 1),
                horizontalInside: pw.BorderSide(color: _light, width: 1),
              ),
              columnWidths: {
                0: const pw.FlexColumnWidth(4),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: _blue),
                  children: [
                    _cell('DESCRIPTION',
                        bold: true, color: PdfColors.white),
                    _cell('QTY',
                        bold: true, right: true, color: PdfColors.white),
                    _cell('RATE',
                        bold: true, right: true, color: PdfColors.white),
                    _cell('AMOUNT',
                        bold: true, right: true, color: PdfColors.white),
                  ],
                ),
                pw.TableRow(children: [
                  _cell('Daily wage - $skill\n${r['businessName']}, ${r['area']}'),
                  _cell('1 day', right: true),
                  _cell('Rs. $wage', right: true),
                  _cell('Rs. $wage', right: true, bold: true),
                ]),
              ],
            ),
            pw.SizedBox(height: 16),

            // Totals + PAID stamp
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Center(
                    child: pw.Transform.rotate(
                      angle: -0.2,
                      child: pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 24, vertical: 8),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: _green, width: 3),
                          borderRadius: pw.BorderRadius.circular(8),
                        ),
                        child: pw.Text('PAID',
                            style: pw.TextStyle(
                                fontSize: 30,
                                color: _green,
                                fontWeight: pw.FontWeight.bold)),
                      ),
                    ),
                  ),
                ),
                pw.SizedBox(
                  width: 210,
                  child: pw.Column(
                    children: [
                      _totalRow('Subtotal', 'Rs. $wage'),
                      _totalRow('Platform fee', 'Rs. 0'),
                      pw.Divider(color: _light),
                      _totalRow('TOTAL PAID', 'Rs. $wage',
                          big: true, color: _orange),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Payment details
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: _light, width: 1.5),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _label('PAYMENT DETAILS'),
                  pw.SizedBox(height: 6),
                  pw.Text('Method: $method',
                      style: const pw.TextStyle(fontSize: 10)),
                  if (payId != null)
                    pw.Text('Transaction ID: $payId',
                        style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Status: Completed',
                      style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Booking ref: $requestId',
                      style:
                          const pw.TextStyle(fontSize: 8, color: _grey)),
                ],
              ),
            ),

            pw.Spacer(),
            pw.Divider(color: _light),
            pw.Center(
              child: pw.Text('Thank you for using KovaiWorks!',
                  style: pw.TextStyle(
                      fontSize: 11,
                      color: _orange,
                      fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 4),
            pw.Center(
              child: pw.Text(
                  'This is a computer-generated receipt (test mode). No signature required.',
                  style: const pw.TextStyle(fontSize: 8, color: _grey)),
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      name: 'KovaiWorks_$receiptNo',
      onLayout: (_) => pdf.save(),
    );
  }
}