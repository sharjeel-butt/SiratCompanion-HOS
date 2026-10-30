// entry/src/main/ets/utils/PdfExportHelper.ets

import { pdfService } from '@kit.PDFKit';
import { fileIo as fs, picker, ReadOptions } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { componentSnapshot, promptAction } from '@kit.ArkUI';
import { image } from '@kit.ImageKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { L } from '../i8n/LocalizationHelper';

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

      // 1. Render the UI builder to a PixelMap.
      const snapshotOptions: componentSnapshot.SnapshotOptions = { scale: 1 };
      const pixelMap: image.PixelMap = await uiContext
        .getComponentSnapshot()
        .createFromBuilder(builder, 10, false, snapshotOptions);

      // 2. Pack the PixelMap to a JPEG file (more reliable for PDF Kit).
      const imagePacker: image.ImagePacker = image.createImagePacker();
      const packOpts: image.PackingOption = { format: 'image/jpeg', quality: 95 };
      sandboxJpgPath = context.filesDir + '/' + fileName + '.jpg';

      const imageFile: fs.File = fs.openSync(
        sandboxJpgPath,
        fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC
      );

      await imagePacker.packToFile(pixelMap, imageFile.fd, packOpts);
      fs.closeSync(imageFile);

      if (fs.statSync(sandboxJpgPath).size === 0) {
        throw new Error('Generated image file is empty.');
      }

      // 3. Create the PDF in the sandbox.
      const pdfDoc: pdfService.PdfDocument = new pdfService.PdfDocument();
      sandboxPdfPath = context.filesDir + '/' + fileName + '.pdf';

      try {
        pdfDoc.createDocument(595.28, 841.89); // A4 in points
        const page: pdfService.PdfPage = pdfDoc.getPage(0);
        page.addImageObject(sandboxJpgPath, 0, 0, 595.28, 841.89);

        const saved: boolean = pdfDoc.saveDocument(sandboxPdfPath);
        if (!saved) {
          throw new Error('saveDocument() returned false for ' + sandboxPdfPath);
        }
      } finally {
        pdfDoc.releaseDocument();
      }

      // 4. Sanity-check the file on disk.
      let pdfSize = 0;
      try {
        pdfSize = fs.statSync(sandboxPdfPath).size;
      } catch (err) {
        throw new Error('PDF file missing after save: ' + sandboxPdfPath);
      }
      if (pdfSize === 0) {
        throw new Error('PDF file is empty: ' + sandboxPdfPath);
      }

      // 5. Prompt the user for a save location. On HarmonyOS,
      //    third-party apps cannot request the system-level
      //    PRINT permission and the previous print.print() call
      //    therefore always failed silently. Letting the user
      //    save the PDF to a file manager location gives them a
      //    working, discoverable artefact they can open in any
      //    PDF viewer, print from there, or share.
      const dstUri = await PdfExportHelper.pickSaveLocation(context, fileName);
      if (dstUri.length === 0) {
        // User cancelled the picker — no error, no toast.
        return;
      }

      const copied = PdfExportHelper.copyFileToUri(sandboxPdfPath, dstUri);
      if (!copied) {
        throw new Error('Failed to write PDF to chosen location: ' + dstUri);
      }

      promptAction.showToast({ message: L.get('export_success') });
    } catch (err) {
      console.error('PDF generation failed: ' + JSON.stringify(err));
      promptAction.showToast({ message: L.get('export_failed') });
    } finally {
      // Clean up both intermediate sandbox files.
      if (sandboxJpgPath.length > 0) {
        try {
          fs.unlinkSync(sandboxJpgPath);
        } catch (e) { /* ignore */
        }
      }
      if (sandboxPdfPath.length > 0) {
        try {
          fs.unlinkSync(sandboxPdfPath);
        } catch (e) { /* ignore */
        }
      }
    }
  }

  /**
   * Prompt the user for a destination filename via the system
   * DocumentViewPicker. Returns '' if the picker is dismissed.
   */
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
      return '';
    }
  }

  /**
   * Copy the sandbox PDF into the user-chosen document URI.
   * Returns true on success.
   */
  private static copyFileToUri(srcPath: string, dstUri: string): boolean {
    let srcFile: fs.File | null = null;
    let dstFile: fs.File | null = null;
    try {
      srcFile = fs.openSync(srcPath, fs.OpenMode.READ_ONLY);

      try {
        dstFile = fs.openSync(dstUri, fs.OpenMode.WRITE_ONLY | fs.OpenMode.TRUNC);
      } catch (e) {
        dstFile = fs.openSync(
          dstUri,
          fs.OpenMode.WRITE_ONLY | fs.OpenMode.CREATE | fs.OpenMode.TRUNC
        );
      }

      const stat = fs.statSync(srcPath);
      const buf = new ArrayBuffer(stat.size);
      const readOpts: ReadOptions = { offset: 0, length: stat.size };
      const bytesRead = fs.readSync(srcFile.fd, buf, readOpts);
      fs.writeSync(dstFile.fd, new Uint8Array(buf, 0, bytesRead));

      fs.closeSync(srcFile);
      fs.closeSync(dstFile);
      return true;
    } catch (err) {
      const e = err as BusinessError;
      console.error('copyFileToUri failed: ' + e.code + ' ' + e.message);
      try {
        if (srcFile) {
          fs.closeSync(srcFile);
        }
      } catch (ign) { /* ignore */
      }
      try {
        if (dstFile) {
          fs.closeSync(dstFile);
        }
      } catch (ign) { /* ignore */
      }
      return false;
    }
  }
}