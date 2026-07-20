import { jsPDF } from 'jspdf';
import autoTable from 'jspdf-autotable';
import * as XLSX from 'xlsx';
import { formatCurrency } from '../utils';

// Date formatter
const formatDate = (raw) => {
  if (!raw) return '';
  const d = new Date(raw);
  if (Number.isNaN(d.getTime())) return raw;
  return d.toLocaleDateString('tr-TR', { day: 'numeric', month: 'short', year: 'numeric' });
};

// Common header for transactions
const transactionHeaders = ['Tarih', 'Tür', 'Kategori', 'Açıklama', 'Cari/Hesap', 'Tutar'];

const getTransactionRow = (t) => {
  const counterparty = t.contact_name || t.dest_name || t.source_name || '-';
  return [
    formatDate(t.date),
    t.type || '-',
    t.category || '-',
    t.description || '-',
    counterparty,
    formatCurrency(t.amount)
  ];
};

const getTransactionExcelRow = (t) => {
  const counterparty = t.contact_name || t.dest_name || t.source_name || '-';
  return [
    formatDate(t.date),
    t.type || '-',
    t.category || '-',
    t.description || '-',
    counterparty,
    t.amount
  ];
};

const slugify = (s) => {
  const cleaned = s.trim().replace(/[^\wığüşöçİĞÜŞÖÇ]+/g, '_');
  return cleaned === '' ? 'disa_aktarim' : cleaned;
};

// PDF Custom font support for Turkish Characters
// We will replace tricky chars just in case if a custom font isn't loaded.
const sanitizeTR = (str) => {
  if (typeof str !== 'string') return str;
  return str.replace(/İ/g, 'I').replace(/ı/g, 'i')
            .replace(/Ş/g, 'S').replace(/ş/g, 's')
            .replace(/Ğ/g, 'G').replace(/ğ/g, 'g')
            .replace(/Ü/g, 'U').replace(/ü/g, 'u')
            .replace(/Ö/g, 'O').replace(/ö/g, 'o')
            .replace(/Ç/g, 'C').replace(/ç/g, 'c');
};

const sanitizeRow = (row) => row.map(cell => sanitizeTR(cell));

// 1. Transactions PDF
export const exportTransactionsToPDF = (transactions, title = 'Hareketler') => {
  const doc = new jsPDF();
  
  doc.setFontSize(16);
  doc.text(sanitizeTR(title), 14, 22);

  const data = transactions.map(t => sanitizeRow(getTransactionRow(t)));

  if (data.length === 0) {
    doc.setFontSize(11);
    doc.text('Bu kritere uyan islem bulunamadi.', 14, 32);
  } else {
    autoTable(doc, {
      startY: 28,
      head: [transactionHeaders.map(sanitizeTR)],
      body: data,
      theme: 'grid',
      styles: { fontSize: 9 },
      headStyles: { fillColor: [44, 62, 80] },
      columnStyles: { 5: { halign: 'right' } }
    });
  }

  doc.save(`${slugify(title)}.pdf`);
};

// 2. Transactions Excel
export const exportTransactionsToExcel = (transactions, title = 'Hareketler') => {
  const data = transactions.map(getTransactionExcelRow);
  data.unshift(transactionHeaders); // Add headers at the beginning

  const worksheet = XLSX.utils.aoa_to_sheet(data);
  const workbook = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(workbook, worksheet, "Hareketler");

  XLSX.writeFile(workbook, `${slugify(title)}.xlsx`);
};

// 3. Project Cost Report PDF
export const exportProjectToPDF = (projectName, budgetLines, transactions) => {
  const doc = new jsPDF();
  
  doc.setFontSize(16);
  doc.text(`Proje Maliyet Raporu - ${sanitizeTR(projectName)}`, 14, 22);

  let currentY = 28;

  // Budget Summary
  if (budgetLines && budgetLines.length > 0) {
    doc.setFontSize(12);
    doc.text('Butce Ozeti', 14, currentY);
    currentY += 6;

    const budgetData = budgetLines.map(b => sanitizeRow([
      b.category,
      formatCurrency(b.budgeted),
      formatCurrency(b.actual),
      formatCurrency(b.remaining)
    ]));

    autoTable(doc, {
      startY: currentY,
      head: [['Kategori', 'Planlanan', 'Gerceklesen', 'Kalan']],
      body: budgetData,
      theme: 'grid',
      styles: { fontSize: 9 },
      headStyles: { fillColor: [44, 62, 80] }
    });
    
    currentY = doc.lastAutoTable ? doc.lastAutoTable.finalY + 12 : currentY + 30;
  }

  // Transactions
  doc.setFontSize(12);
  doc.text('Harcamalar', 14, currentY);
  currentY += 6;

  const data = transactions.map(t => sanitizeRow(getTransactionRow(t)));

  if (data.length === 0) {
    doc.setFontSize(11);
    doc.text('Bu projeye ait harcama bulunamadi.', 14, currentY);
  } else {
    autoTable(doc, {
      startY: currentY,
      head: [transactionHeaders.map(sanitizeTR)],
      body: data,
      theme: 'grid',
      styles: { fontSize: 9 },
      headStyles: { fillColor: [44, 62, 80] },
      columnStyles: { 5: { halign: 'right' } }
    });
  }

  doc.save(`${slugify('proje_maliyet_raporu_' + projectName)}.pdf`);
};

// 4. Project Cost Report Excel
export const exportProjectToExcel = (projectName, budgetLines, transactions) => {
  const workbook = XLSX.utils.book_new();

  // Budget Sheet
  if (budgetLines && budgetLines.length > 0) {
    const budgetData = budgetLines.map(b => [
      b.category,
      b.budgeted,
      b.actual,
      b.remaining
    ]);
    budgetData.unshift(['Kategori', 'Planlanan', 'Gerçekleşen', 'Kalan']);
    const budgetSheet = XLSX.utils.aoa_to_sheet(budgetData);
    XLSX.utils.book_append_sheet(workbook, budgetSheet, "Bütçe");
  }

  // Transactions Sheet
  const txData = transactions.map(getTransactionExcelRow);
  txData.unshift(transactionHeaders);
  const txSheet = XLSX.utils.aoa_to_sheet(txData);
  XLSX.utils.book_append_sheet(workbook, txSheet, "Harcamalar");

  XLSX.writeFile(workbook, `${slugify('proje_maliyet_raporu_' + projectName)}.xlsx`);
};
