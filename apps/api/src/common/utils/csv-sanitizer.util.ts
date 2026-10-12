/**
 * Sanitizes a cell value to prevent CSV / Spreadsheet Formula Injection (CWE-1236).
 * Prepends a single quote if the value begins with dangerous formula triggers (=, +, -, @, \t, \r).
 * Handles proper RFC 4180 double-quoting for values containing commas, quotes, or newlines.
 */
export function sanitizeCsvCell(value: any): string {
  if (value === null || value === undefined) {
    return '';
  }
  let str = String(value);

  // Guard against spreadsheet formula injection (CWE-1236)
  if (/^[=\+\-@\t\r]/.test(str)) {
    str = `'${str}`;
  }

  // If contains commas, double quotes, or newlines, quote the cell and escape quotes
  if (/[",\n\r]/.test(str)) {
    str = `"${str.replace(/"/g, '""')}"`;
  }

  return str;
}

export interface CsvColumn {
  key: string;
  label: string;
}

/**
 * Converts tabular record data into an injection-safe CSV formatted string.
 */
export function generateSafeCsv(columns: CsvColumn[], rows: Record<string, any>[]): string {
  const headerLine = columns.map((col) => sanitizeCsvCell(col.label)).join(',');
  const rowLines = rows.map((row) => {
    return columns.map((col) => sanitizeCsvCell(row[col.key])).join(',');
  });

  return [headerLine, ...rowLines].join('\r\n');
}
