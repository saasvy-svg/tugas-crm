import { google } from 'googleapis';

const SCOPES = ['https://www.googleapis.com/auth/spreadsheets'];

/**
 * Parses the service account JSON key from the environment variable.
 */
export function getAuthClient() {
  const keyString = process.env.GOOGLE_SERVICE_ACCOUNT_KEY;
  if (!keyString) {
    throw new Error('Missing GOOGLE_SERVICE_ACCOUNT_KEY environment variable.');
  }

  try {
    const credentials = JSON.parse(keyString);
    if (credentials.private_key) {
      credentials.private_key = credentials.private_key.replace(/\\n/g, '\n');
    }

    return new google.auth.GoogleAuth({
      credentials,
      scopes: SCOPES,
    });
  } catch (err) {
    throw new Error('Failed to parse GOOGLE_SERVICE_ACCOUNT_KEY. Ensure it is a valid JSON string.');
  }
}

/**
 * Converts 0-based column index to letter (0 -> 'A', 1 -> 'B', etc.)
 */
export function getColLetter(colIdx: number): string {
  let temp = colIdx + 1;
  let letter = '';
  while (temp > 0) {
    const mod = (temp - 1) % 26;
    letter = String.fromCharCode(65 + mod) + letter;
    temp = Math.floor((temp - mod) / 26);
  }
  return letter;
}

/**
 * Converts hex color string to Google Sheets RGB object (0.0 to 1.0)
 */
export function hexToRgb(hex: string) {
  const clean = hex.replace('#', '');
  const r = parseInt(clean.substring(0, 2), 16) / 255;
  const g = parseInt(clean.substring(2, 4), 16) / 255;
  const b = parseInt(clean.substring(4, 6), 16) / 255;
  return { red: r, green: g, blue: b };
}

/**
 * Get color theme based on tab name
 */
export function getTabTheme(tabName: string) {
  const lower = tabName.toLowerCase();
  if (lower.includes('project')) {
    return {
      tabColor: hexToRgb('#2563eb'),
      titleBg: hexToRgb('#0f172a'),
      subBg: hexToRgb('#f1f5f9'),
      subText: hexToRgb('#475569'),
      headerBg: hexToRgb('#1e293b'),
      headerBorder: hexToRgb('#0f172a'),
      zebraBg: hexToRgb('#f8fafc'),
      textDark: hexToRgb('#1e293b'),
      accentBorder: hexToRgb('#cbd5e1'),
      gridLine: hexToRgb('#e2e8f0'),
    };
  } else if (lower.includes('finan') || lower.includes('invoice') || lower.includes('uang')) {
    return {
      tabColor: hexToRgb('#059669'),
      titleBg: hexToRgb('#064e3b'),
      subBg: hexToRgb('#ecfdf5'),
      subText: hexToRgb('#065f46'),
      headerBg: hexToRgb('#047857'),
      headerBorder: hexToRgb('#064e3b'),
      zebraBg: hexToRgb('#f0fdf4'),
      textDark: hexToRgb('#064e3b'),
      accentBorder: hexToRgb('#a7f3d0'),
      gridLine: hexToRgb('#d1fae5'),
    };
  } else if (lower.includes('operat') || lower.includes('logis') || lower.includes('shipping')) {
    return {
      tabColor: hexToRgb('#d97706'),
      titleBg: hexToRgb('#78350f'),
      subBg: hexToRgb('#fffbeb'),
      subText: hexToRgb('#92400e'),
      headerBg: hexToRgb('#b45309'),
      headerBorder: hexToRgb('#78350f'),
      zebraBg: hexToRgb('#fffdf5'),
      textDark: hexToRgb('#1c1917'),
      accentBorder: hexToRgb('#fed7aa'),
      gridLine: hexToRgb('#ffedd5'),
    };
  } else if (lower.includes('account') || lower.includes('user') || lower.includes('staf') || lower.includes('klien')) {
    return {
      tabColor: hexToRgb('#7c3aed'),
      titleBg: hexToRgb('#3b0764'),
      subBg: hexToRgb('#f5f3ff'),
      subText: hexToRgb('#6b21a8'),
      headerBg: hexToRgb('#6d28d9'),
      headerBorder: hexToRgb('#4c1d95'),
      zebraBg: hexToRgb('#faf5ff'),
      textDark: hexToRgb('#1e1b4b'),
      accentBorder: hexToRgb('#ddd6fe'),
      gridLine: hexToRgb('#ede9fe'),
    };
  } else if (lower.includes('stok') || lower.includes('gudang') || lower.includes('invent') || lower.includes('bahan')) {
    return {
      tabColor: hexToRgb('#0d9488'),
      titleBg: hexToRgb('#134e4a'),
      subBg: hexToRgb('#f0fdfa'),
      subText: hexToRgb('#0f766e'),
      headerBg: hexToRgb('#0f766e'),
      headerBorder: hexToRgb('#134e4a'),
      zebraBg: hexToRgb('#f0fdfa'),
      textDark: hexToRgb('#134e4a'),
      accentBorder: hexToRgb('#99f6e4'),
      gridLine: hexToRgb('#ccfbf1'),
    };
  }

  // Default Slate Theme
  return {
    tabColor: hexToRgb('#475569'),
    titleBg: hexToRgb('#0f172a'),
    subBg: hexToRgb('#f8fafc'),
    subText: hexToRgb('#64748b'),
    headerBg: hexToRgb('#334155'),
    headerBorder: hexToRgb('#1e293b'),
    zebraBg: hexToRgb('#f8fafc'),
    textDark: hexToRgb('#1e293b'),
    accentBorder: hexToRgb('#cbd5e1'),
    gridLine: hexToRgb('#e2e8f0'),
  };
}

/**
 * Appends rows to a specific tab in a Google Sheet.
 */
export async function appendRows(sheetId: string, tabName: string, rows: any[][]) {
  if (!rows || rows.length === 0) return;

  const auth = getAuthClient();
  const sheets = google.sheets({ version: 'v4', auth });

  const request = {
    spreadsheetId: sheetId,
    range: `${tabName}!A1`,
    valueInputOption: 'RAW',
    insertDataOption: 'INSERT_ROWS',
    requestBody: { values: rows },
  };

  try {
    await sheets.spreadsheets.values.append(request);
  } catch (error: any) {
    console.error(`Failed to append rows to sheet ${sheetId} (tab: ${tabName}):`, error.message);
    throw new Error(`Google Sheets API Error: ${error.message}`);
  }
}

/**
 * Clears an entire tab and rewrites it with executive-level styling,
 * table borders, banners, zebra striping, and calibrated column widths.
 *
 * @param sheetId The Google Sheet ID
 * @param tabName The name of the tab/worksheet
 * @param rows 2D array of data to write (Row 0 is header)
 */
export async function clearAndWrite(sheetId: string, tabName: string, rows: any[][]) {
  const auth = getAuthClient();
  const sheets = google.sheets({ version: 'v4', auth });

  try {
    // 1. Get or Create Tab
    let sheetNumericId = 0;
    try {
      const meta = await sheets.spreadsheets.get({ spreadsheetId: sheetId });
      const found = (meta.data.sheets || []).find((s) => s.properties?.title === tabName);
      if (found) {
        sheetNumericId = found.properties?.sheetId ?? 0;
      } else {
        const addRes = await sheets.spreadsheets.batchUpdate({
          spreadsheetId: sheetId,
          requestBody: {
            requests: [{ addSheet: { properties: { title: tabName } } }],
          },
        });
        sheetNumericId = addRes.data.replies?.[0]?.addSheet?.properties?.sheetId ?? Date.now();
      }
    } catch (e: any) {
      console.warn(`Error resolving sheet ID for tab ${tabName}:`, e.message);
    }

    // 2. Clear content across A1:AZ1000
    try {
      await sheets.spreadsheets.values.clear({
        spreadsheetId: sheetId,
        range: `'${tabName}'!A1:AZ1000`,
      });
    } catch (clearErr) {}

    if (!rows || rows.length === 0) return;

    // 3. Prepare formatted data with sequential 'No' column & banners
    const originalHeaders = rows[0] || [];
    const originalData = rows.slice(1);

    // If original headers don't already have 'No', add it as first column
    const hasNoCol = String(originalHeaders[0] || '').toLowerCase() === 'no';
    const finalHeaders = hasNoCol ? originalHeaders : ['No', ...originalHeaders];

    const finalDataRows = originalData.map((r, idx) => {
      if (hasNoCol) return r;
      return [idx + 1, ...r];
    });

    const nowWIB = new Date().toLocaleString('id-ID', { timeZone: 'Asia/Jakarta' });
    const titleText = `VYLOGIX CRM — ${tabName.toUpperCase()}`;
    const subtitleText = `Sinkronisasi Otomatis Cloud CRM • Terkoneksi Realtime Database • Terakhir Diperbarui: ${nowWIB} WIB`;

    const payload = [
      [titleText],
      [subtitleText],
      finalHeaders,
      ...finalDataRows,
    ];

    const numCols = finalHeaders.length;
    const startColIdx = 1; // Start at Column B (index 1) to leave Column A as margin
    const endColIdx = startColIdx + numCols;
    const endColLetter = getColLetter(endColIdx - 1);
    const totalDataRows = finalDataRows.length;
    const dataEndRow = 4 + totalDataRows;

    // Write Values at B2
    await sheets.spreadsheets.values.update({
      spreadsheetId: sheetId,
      range: `'${tabName}'!B2:${endColLetter}${dataEndRow}`,
      valueInputOption: 'USER_ENTERED',
      requestBody: { values: payload },
    });

    // 4. Build Batch Styling Requests
    const theme = getTabTheme(tabName);
    const requests: any[] = [
      // Tab color & Frozen header row
      {
        updateSheetProperties: {
          properties: {
            sheetId: sheetNumericId,
            tabColor: theme.tabColor,
            gridProperties: { frozenRowCount: 4 },
          },
          fields: 'tabColor,gridProperties.frozenRowCount',
        },
      },
      // Reset format & unmerge
      {
        unmergeCells: {
          range: { sheetId: sheetNumericId, startRowIndex: 0, endRowIndex: 200, startColumnIndex: 0, endColumnIndex: 30 },
        },
      },
      {
        repeatCell: {
          range: { sheetId: sheetNumericId, startRowIndex: 0, endRowIndex: 200, startColumnIndex: 0, endColumnIndex: 30 },
          cell: { userEnteredFormat: {} },
          fields: 'userEnteredFormat',
        },
      },

      // Margin column A width: 25px
      {
        updateDimensionProperties: {
          range: { sheetId: sheetNumericId, dimension: 'COLUMNS', startIndex: 0, endIndex: 1 },
          properties: { pixelSize: 25 },
          fields: 'pixelSize',
        },
      },
      // Sequential 'No' column width: 45px
      {
        updateDimensionProperties: {
          range: { sheetId: sheetNumericId, dimension: 'COLUMNS', startIndex: 1, endIndex: 2 },
          properties: { pixelSize: 45 },
          fields: 'pixelSize',
        },
      },

      // Row Heights
      { updateDimensionProperties: { range: { sheetId: sheetNumericId, dimension: 'ROWS', startIndex: 0, endIndex: 1 }, properties: { pixelSize: 16 }, fields: 'pixelSize' } },
      { updateDimensionProperties: { range: { sheetId: sheetNumericId, dimension: 'ROWS', startIndex: 1, endIndex: 2 }, properties: { pixelSize: 36 }, fields: 'pixelSize' } }, // Row 2 (Title)
      { updateDimensionProperties: { range: { sheetId: sheetNumericId, dimension: 'ROWS', startIndex: 2, endIndex: 3 }, properties: { pixelSize: 24 }, fields: 'pixelSize' } }, // Row 3 (Subtitle)
      { updateDimensionProperties: { range: { sheetId: sheetNumericId, dimension: 'ROWS', startIndex: 3, endIndex: 4 }, properties: { pixelSize: 32 }, fields: 'pixelSize' } }, // Row 4 (Header)

      // Merge Title & Subtitle B2:EndCol2, B3:EndCol3
      { mergeCells: { range: { sheetId: sheetNumericId, startRowIndex: 1, endRowIndex: 2, startColumnIndex: startColIdx, endColumnIndex: endColIdx }, mergeType: 'MERGE_ALL' } },
      { mergeCells: { range: { sheetId: sheetNumericId, startRowIndex: 2, endRowIndex: 3, startColumnIndex: startColIdx, endColumnIndex: endColIdx }, mergeType: 'MERGE_ALL' } },

      // Title Banner Formatting
      {
        repeatCell: {
          range: { sheetId: sheetNumericId, startRowIndex: 1, endRowIndex: 2, startColumnIndex: startColIdx, endColumnIndex: endColIdx },
          cell: {
            userEnteredFormat: {
              backgroundColor: theme.titleBg,
              textFormat: { bold: true, fontSize: 12, foregroundColor: { red: 1, green: 1, blue: 1 } },
              horizontalAlignment: 'CENTER',
              verticalAlignment: 'MIDDLE',
            },
          },
          fields: 'userEnteredFormat(backgroundColor,textFormat,horizontalAlignment,verticalAlignment)',
        },
      },

      // Subtitle Banner Formatting
      {
        repeatCell: {
          range: { sheetId: sheetNumericId, startRowIndex: 2, endRowIndex: 3, startColumnIndex: startColIdx, endColumnIndex: endColIdx },
          cell: {
            userEnteredFormat: {
              backgroundColor: theme.subBg,
              textFormat: { italic: true, fontSize: 9, foregroundColor: theme.subText },
              horizontalAlignment: 'CENTER',
              verticalAlignment: 'MIDDLE',
            },
          },
          fields: 'userEnteredFormat(backgroundColor,textFormat,horizontalAlignment,verticalAlignment)',
        },
      },

      // Header Row Formatting
      {
        repeatCell: {
          range: { sheetId: sheetNumericId, startRowIndex: 3, endRowIndex: 4, startColumnIndex: startColIdx, endColumnIndex: endColIdx },
          cell: {
            userEnteredFormat: {
              backgroundColor: theme.headerBg,
              textFormat: { bold: true, fontSize: 10, foregroundColor: { red: 1, green: 1, blue: 1 } },
              horizontalAlignment: 'CENTER',
              verticalAlignment: 'MIDDLE',
              wrapStrategy: 'WRAP',
            },
          },
          fields: 'userEnteredFormat(backgroundColor,textFormat,horizontalAlignment,verticalAlignment,wrapStrategy)',
        },
      },
      // Header Borders
      {
        updateBorders: {
          range: { sheetId: sheetNumericId, startRowIndex: 3, endRowIndex: 4, startColumnIndex: startColIdx, endColumnIndex: endColIdx },
          top: { style: 'SOLID', color: theme.headerBorder },
          bottom: { style: 'SOLID_MEDIUM', color: theme.headerBorder },
          left: { style: 'SOLID', color: theme.headerBorder },
          right: { style: 'SOLID', color: theme.headerBorder },
          innerVertical: { style: 'SOLID', color: theme.headerBg },
        },
      },
    ];

    // Auto-detect and set appropriate column widths based on header name
    for (let c = 0; c < finalHeaders.length; c++) {
      const headerName = String(finalHeaders[c] || '').toLowerCase();
      let colWidth = 140; // default
      if (headerName === 'no') colWidth = 45;
      else if (headerName.includes('id')) colWidth = 110;
      else if (headerName.includes('title') || headerName.includes('nama') || headerName.includes('perihal') || headerName.includes('bahan')) colWidth = 280;
      else if (headerName.includes('klien') || headerName.includes('client') || headerName.includes('supplier')) colWidth = 230;
      else if (headerName.includes('email')) colWidth = 240;
      else if (headerName.includes('category') || headerName.includes('kategori')) colWidth = 110;
      else if (headerName.includes('status')) colWidth = 125;
      else if (headerName.includes('progress') || headerName.includes('progres') || headerName.includes('qty') || headerName.includes('stok')) colWidth = 100;
      else if (headerName.includes('date') || headerName.includes('deadline') || headerName.includes('tempo')) colWidth = 115;
      else if (headerName.includes('price') || headerName.includes('amount') || headerName.includes('nilai') || headerName.includes('tagihan') || headerName.includes('belanja')) colWidth = 145;
      else if (headerName.includes('resi') || headerName.includes('wa') || headerName.includes('whatsapp') || headerName.includes('phone')) colWidth = 140;

      requests.push({
        updateDimensionProperties: {
          range: { sheetId: sheetNumericId, dimension: 'COLUMNS', startIndex: startColIdx + c, endIndex: startColIdx + c + 1 },
          properties: { pixelSize: colWidth },
          fields: 'pixelSize',
        },
      });
    }

    // Data rows styling
    if (totalDataRows > 0) {
      // Row heights for data
      requests.push({
        updateDimensionProperties: {
          range: { sheetId: sheetNumericId, dimension: 'ROWS', startIndex: 4, endIndex: 4 + totalDataRows },
          properties: { pixelSize: 28 },
          fields: 'pixelSize',
        },
      });

      // Base font and vertical alignment
      requests.push({
        repeatCell: {
          range: { sheetId: sheetNumericId, startRowIndex: 4, endRowIndex: 4 + totalDataRows, startColumnIndex: startColIdx, endColumnIndex: endColIdx },
          cell: {
            userEnteredFormat: {
              verticalAlignment: 'MIDDLE',
              textFormat: { fontSize: 10, foregroundColor: theme.textDark },
            },
          },
          fields: 'userEnteredFormat(verticalAlignment,textFormat)',
        },
      });

      // Zebra striping
      for (let r = 0; r < totalDataRows; r++) {
        const bg = r % 2 === 0 ? { red: 1, green: 1, blue: 1 } : theme.zebraBg;
        requests.push({
          repeatCell: {
            range: { sheetId: sheetNumericId, startRowIndex: 4 + r, endRowIndex: 5 + r, startColumnIndex: startColIdx, endColumnIndex: endColIdx },
            cell: { userEnteredFormat: { backgroundColor: bg } },
            fields: 'userEnteredFormat.backgroundColor',
          },
        });
      }

      // Column alignments & numberFormats based on header type
      for (let c = 0; c < finalHeaders.length; c++) {
        const headerName = String(finalHeaders[c] || '').toLowerCase();
        let align = 'LEFT';
        let isBold = false;
        let numberFormat: any = null;

        if (
          headerName === 'no' ||
          headerName.includes('id') ||
          headerName.includes('status') ||
          headerName.includes('kategori') ||
          headerName.includes('category') ||
          headerName.includes('progress') ||
          headerName.includes('progres') ||
          headerName.includes('date') ||
          headerName.includes('deadline') ||
          headerName.includes('tempo') ||
          headerName.includes('terdaftar') ||
          headerName.includes('terbit') ||
          headerName.includes('wa') ||
          headerName.includes('whatsapp') ||
          headerName.includes('resi') ||
          headerName.includes('qty') ||
          headerName.includes('satuan')
        ) {
          align = 'CENTER';
        } else if (
          headerName.includes('price') ||
          headerName.includes('amount') ||
          headerName.includes('nilai') ||
          headerName.includes('tagihan') ||
          headerName.includes('belanja')
        ) {
          align = 'RIGHT';
          isBold = true;
        }

        if (headerName.includes('status') || headerName.includes('progress') || headerName.includes('progres') || headerName.includes('kategori')) {
          isBold = true;
        }

        // Set explicit number format so Google Sheets doesn't render raw serial numbers
        if (headerName.includes('date') || headerName.includes('deadline') || headerName.includes('tempo') || headerName.includes('terdaftar') || headerName.includes('terbit')) {
          numberFormat = { type: 'DATE', pattern: 'yyyy-mm-dd' };
        } else if (headerName.includes('price') || headerName.includes('amount') || headerName.includes('nilai') || headerName.includes('tagihan') || headerName.includes('belanja')) {
          numberFormat = { type: 'CURRENCY', pattern: '"Rp "#,##0' };
        } else if (headerName.includes('progress') || headerName.includes('progres')) {
          numberFormat = { type: 'PERCENT', pattern: '0%' };
        } else if (headerName.includes('wa') || headerName.includes('whatsapp') || headerName.includes('phone') || headerName.includes('resi')) {
          numberFormat = { type: 'TEXT' };
        }

        const formatFields: string[] = ['horizontalAlignment'];
        const cellFormat: any = { horizontalAlignment: align };

        if (isBold) {
          cellFormat.textFormat = { bold: true };
          formatFields.push('textFormat.bold');
        }

        if (numberFormat) {
          cellFormat.numberFormat = numberFormat;
          formatFields.push('numberFormat');
        }

        requests.push({
          repeatCell: {
            range: {
              sheetId: sheetNumericId,
              startRowIndex: 4,
              endRowIndex: 4 + totalDataRows,
              startColumnIndex: startColIdx + c,
              endColumnIndex: startColIdx + c + 1,
            },
            cell: {
              userEnteredFormat: cellFormat,
            },
            fields: `userEnteredFormat(${formatFields.join(',')})`,
          },
        });
      }

      // Grid Borders
      requests.push({
        updateBorders: {
          range: { sheetId: sheetNumericId, startRowIndex: 4, endRowIndex: 4 + totalDataRows, startColumnIndex: startColIdx, endColumnIndex: endColIdx },
          top: { style: 'SOLID', color: theme.accentBorder },
          bottom: { style: 'SOLID_MEDIUM', color: theme.headerBg },
          left: { style: 'SOLID', color: theme.accentBorder },
          right: { style: 'SOLID', color: theme.accentBorder },
          innerHorizontal: { style: 'SOLID', color: theme.gridLine },
          innerVertical: { style: 'SOLID', color: theme.accentBorder },
        },
      });
    }

    // Execute batchUpdate
    await sheets.spreadsheets.batchUpdate({
      spreadsheetId: sheetId,
      requestBody: { requests },
    });
  } catch (error: any) {
    console.error(`Failed to clear and write formatted table to sheet ${sheetId} (tab: ${tabName}):`, error.message);
    throw new Error(`Google Sheets API Error: ${error.message}`);
  }
}

/**
 * Validates if the service account has access to the given spreadsheet.
 */
export async function validateSheetAccess(sheetId: string): Promise<{ success: boolean; error?: string }> {
  const auth = getAuthClient();
  const sheets = google.sheets({ version: 'v4', auth });

  try {
    await sheets.spreadsheets.get({
      spreadsheetId: sheetId,
      includeGridData: false,
    });
    return { success: true };
  } catch (error: any) {
    console.error(`Validation failed for sheet ${sheetId}:`, error.message);
    return { success: false, error: error.message };
  }
}
