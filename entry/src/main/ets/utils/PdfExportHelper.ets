// entry/src/main/ets/utils/PdfExportHelper.ets

import { pdfService } from '@kit.PDFKit';
import { fileIo as fs, picker } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { componentSnapshot, promptAction } from '@kit.ArkUI';
import { image } from '@kit.ImageKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { L } from '../i18n/LocalizationHelper';
import { AppLogger } from '../helper/AppLogger';

export class PdfExportHelper {

  static async exportBuilderToPdf(
    context: common.UIAbilityContext,
    uiContext: UIContext,
    builder: () => void,
    fileName: string
  ): Promise<void> {
    let sandboxJpgPath = '';
    let sandboxPdfPath = '';

    try {
      promptAction.showToast({ message: L.get('export_saving') });

      // ── 1. Snapshot ──────────────────────────────────────
      const snapshotOptions: componentSnapshot.SnapshotOptions = { scale: 1 };
      const pixelMap: image.PixelMap = await uiContext
        .getComponentSnapshot()
        .createFromBuilder(builder, 10, false, snapshotOptions);

      AppLogger.info('PdfExportHelper',
        `snapshot ok: ${pixelMap.getImageInfoSync().size.width}×` +
          `${pixelMap.getImageInfoSync().size.height}`);

      // ── 2. JPEG ──────────────────────────────────────────
      sandboxJpgPath = context.filesDir + '/' + fileName + '.jpg';
      PdfExportHelper.deleteIfExists(sandboxJpgPath);

      const imagePacker: image.ImagePacker = image.createImagePacker();
      const packOpts: image.PackingOption = { format: 'image/jpeg', quality: 95 };
      const imageFile: fs.File = fs.openSync(
        sandboxJpgPath,
        fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC
      );
      await imagePacker.packToFile(pixelMap, imageFile.fd, packOpts);
      fs.closeSync(imageFile);

      const jpgSize = fs.statSync(sandboxJpgPath).size;
      AppLogger.info('PdfExportHelper', `jpeg packed: ${jpgSize} bytes`);
      if (jpgSize === 0) {
        throw new Error('Generated image file is empty.');
      }

      // ── 3. PDF in sandbox ────────────────────────────────
      sandboxPdfPath = context.filesDir + '/' + fileName + '.pdf';
      // Delete any stale PDF from a previous failed run so
      // saveDocument() starts on a clean path.
      PdfExportHelper.deleteIfExists(sandboxPdfPath);

      const pdfDoc: pdfService.PdfDocument = new pdfService.PdfDocument();
      try {
        pdfDoc.createDocument(595.28, 841.89); // A4 in points
        const page: pdfService.PdfPage = pdfDoc.getPage(0);
        page.addImageObject(sandboxJpgPath, 0, 0, 595.28, 841.89);

        const saved: boolean = pdfDoc.saveDocument(sandboxPdfPath);
        if (!saved) {
          throw new Error('saveDocument() returned false');
        }
      } finally {
        pdfDoc.releaseDocument();
      }

      const pdfSize = fs.statSync(sandboxPdfPath).size;
      AppLogger.info('PdfExportHelper', `pdf saved: ${pdfSize} bytes`);
      if (pdfSize === 0) {
        throw new Error('PDF file is empty in sandbox');
      }

      // ── 4. Pick destination ──────────────────────────────
      const dstUri = await PdfExportHelper.pickSaveLocation(context, fileName);
      if (dstUri.length === 0) {
        return; // user cancelled
      }

      // ── 5. Copy to destination (the critical fix) ────────
      const copied = PdfExportHelper.copyFileToUri(sandboxPdfPath, dstUri);
      if (!copied) {
        throw new Error('Failed to write PDF to chosen location');
      }

      promptAction.showToast({ message: L.get('export_success') });
    } catch (err) {
      const e = err as BusinessError;
      AppLogger.error('PdfExportHelper',
        `export failed: code=${e.code ?? ''} msg=${e.message ?? JSON.stringify(err)}`);
      promptAction.showToast({ message: L.get('export_failed') });
    } finally {
      PdfExportHelper.deleteIfExists(sandboxJpgPath);
      PdfExportHelper.deleteIfExists(sandboxPdfPath);
    }
  }

  // ============================================================
  // COPY — fixed implementation
  // ============================================================

  /**
   * Copy the sandbox PDF into the user-chosen document URI.
   *
   * The URI returned by DocumentViewPicker.save() is a write-only
   * content:// handle with a pre-created 0-byte file. It cannot be
   * opened with READ_WRITE — only WRITE_ONLY.
   *
   * fs.writeSync() accepts ArrayBuffer | string, NOT Uint8Array.
   * The previous implementation passed a Uint8Array, which threw
   * "invalid parameter" on device (silently swallowed by the outer
   * catch) and left the pre-created 0-byte file in place.
   *
   * This version uses fs.copyFileSync(srcPath, dstFd), which is the
   * documented pattern for picker URI writes and handles the
   * read/flush/close cycle internally.
   */
  private static copyFileToUri(srcPath: string, dstUri: string): boolean {
    let dstFile: fs.File | null = null;
    try {
      // Picker pre-creates the file, so no CREATE flag needed.
      // TRUNC may be rejected on some firmware — fall back to
      // plain WRITE_ONLY if it throws.
      try {
        dstFile = fs.openSync(
          dstUri,
          fs.OpenMode.WRITE_ONLY | fs.OpenMode.TRUNC
        );
      } catch (e1) {
        AppLogger.warn('PdfExportHelper',
          'WRITE_ONLY|TRUNC failed, retrying WRITE_ONLY');
        dstFile = fs.openSync(dstUri, fs.OpenMode.WRITE_ONLY);
      }

      // copyFileSync accepts (path | fd) for both arguments.
      // srcPath is a real sandbox path, dstFile.fd is the picker fd.
      fs.copyFileSync(srcPath, dstFile.fd);

      // Verify the write actually landed.
      const dstStat = fs.statSync(dstUri);
      AppLogger.info('PdfExportHelper',
        `copy complete: dst size = ${dstStat.size} bytes`);

      return dstStat.size > 0;
    } catch (err) {
      const e = err as BusinessError;
      AppLogger.error('PdfExportHelper',
        `copyFileToUri failed: code=${e.code ?? ''} msg=${e.message ?? JSON.stringify(err)}`);
      return false;
    } finally {
      if (dstFile !== null) {
        try {
          fs.closeSync(dstFile);
        } catch (ign) { /* ignore */
        }
      }
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  private static async pickSaveLocation(
    context: common.UIAbilityContext,
    fileName: string
  ): Promise<string> {
    try {
      const documentPicker = new picker.DocumentViewPicker(context);
      const options = new picker.DocumentSaveOptions();
      options.newFileNames = [`${fileName}.pdf`];
      const uris = await documentPicker.save(options);
      if (!uris || uris.length === 0) {
        return '';
      }
      return uris[0];
    } catch (err) {
      AppLogger.info('PdfExportHelper', 'save picker dismissed');
      return '';
    }
  }

  private static deleteIfExists(path: string): void {
    if (path.length === 0) {
      return;
    }
    try {
      fs.unlinkSync(path);
    } catch (ign) { /* file absent — fine */
    }
  }
}