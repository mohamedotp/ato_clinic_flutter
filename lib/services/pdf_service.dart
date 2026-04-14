import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/patient.dart';
import '../models/visit.dart';

class PdfService {
  static Future<void> generatePatientReport({
    required Patient patient,
    required List<Visit> visits,
    required String clinicName,
  }) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.cairoRegular();
    final boldFont = await PdfGoogleFonts.cairoBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        build: (context) => [
          _buildHeader(clinicName, boldFont),
          _buildPatientInfo(patient, boldFont),
          pw.SizedBox(height: 20),
          _buildVisitsTable(visits, boldFont),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'تقرير_${patient.fullName}.pdf',
    );
  }

  static pw.Widget _buildHeader(String clinicName, pw.Font font) {
    return pw.Column(
      children: [
        pw.Text(clinicName, style: pw.TextStyle(font: font, fontSize: 24, fontWeight: pw.FontWeight.bold)),
        pw.Divider(thickness: 2),
        pw.SizedBox(height: 10),
        pw.Text('تقرير طبي مفصل', style: pw.TextStyle(font: font, fontSize: 18)),
        pw.SizedBox(height: 20),
      ],
    );
  }

  static pw.Widget _buildPatientInfo(Patient patient, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(border: pw.Border.all()),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text('اسم المريض: ${patient.fullName}', style: pw.TextStyle(font: font, fontSize: 14)),
          pw.Text('رقم الهاتف: ${patient.phone ?? "غير مسجل"}', style: pw.TextStyle(font: font, fontSize: 14)),
          pw.Text('تاريخ الإنشاء: ${patient.createdAt.toString().split(" ")[0]}', style: pw.TextStyle(font: font, fontSize: 14)),
        ],
      ),
    );
  }

  static pw.Widget _buildVisitsTable(List<Visit> visits, pw.Font font) {
    return pw.TableHelper.fromTextArray(
      cellAlignment: pw.Alignment.centerRight,
      headerStyle: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.teal),
      data: <List<String>>[
        ['التاريخ', 'التشخيص', 'العلاج'],
        ...visits.map((v) => [
              v.visitDate?.toString().split(" ")[0] ?? "",
              v.diagnosis ?? "بدون",
              v.treatment ?? "بدون",
            ]),
      ],
    );
  }
}
