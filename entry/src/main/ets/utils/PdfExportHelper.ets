// entry/src/main/ets/utils/PdfExportHelper.ets

import { pdfService } from '@kit.PDFKit';
import { print } from '@kit.BasicServicesKit';
import { fileIo as fs, fileUri } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { componentSnapshot, promptAction } from '@kit.ArkUI';
import { image } from '@kit.ImageKit';
import { L } from '../i8n/LocalizationHelper';

export class PdfExportHelper {
  static async exportBuilderToPdf(
    context: common.UIAbilityContext,
    uiContext: UIContext,
    builder: () => void,
    fileName: string
  ): Promise<void> {
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

      const imagePath: string = context.filesDir + '/' + fileName + '.jpg';

      const imageFile: fs.File = fs.openSync(
        imagePath,
        fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC
      );

      await imagePacker.packToFile(pixelMap, imageFile.fd, packOpts);
      fs.closeSync(imageFile);

      // Verify the image file was created and is not empty.
      if (fs.statSync(imagePath).size === 0) {
        throw new Error('Generated image file is empty.');
      }

      // 3. Create the PDF and insert the image.
      const pdfDoc: pdfService.PdfDocument = new pdfService.PdfDocument();
      const pdfPath: string = context.filesDir + '/' + fileName + '.pdf';

      try {
        pdfDoc.createDocument(595.28, 841.89); // A4 size in points
        const page: pdfService.PdfPage = pdfDoc.getPage(0);

        // Insert the JPEG image.
        page.addImageObject(imagePath, 0, 0, 595.28, 841.89);

        // saveDocument() returns boolean: true = written, false = failed.
        // Check it BEFORE showing success — the previous build fired
        // the toast unconditionally, so save errors were invisible.
        const saved: boolean = pdfDoc.saveDocument(pdfPath);
        if (!saved) {
          throw new Error('saveDocument() returned false for ' + pdfPath);
        }
      } finally {
        // Release the document whether or not saveDocument() threw.
        // Without this, a save failure leaves a native handle open.
        pdfDoc.releaseDocument();
      }

      // 4. Sanity-check the file on disk. saveDocument() returning
      //    true does not guarantee non-zero bytes in every SDK build
      //    (rare disk-full case), so verify with stat() as well.
      let pdfSize = 0;
      try {
        pdfSize = fs.statSync(pdfPath).size;
      } catch (err) {
        throw new Error('PDF file missing after save: ' + pdfPath);
      }
      if (pdfSize === 0) {
        throw new Error('PDF file is empty: ' + pdfPath);
      }

      // 5. Success toast fires ONLY here, after every check passed.
      promptAction.showToast({ message: L.get('export_success') });

      // 6. Clean up the intermediate JPEG. The PDF embeds it; the
      //    raw file is no longer needed and would otherwise end up
      //    in filesDir (and therefore in any directory-based backup).
      try {
        fs.unlinkSync(imagePath);
      } catch (err) {
        // Non-fatal — the JPEG is harmless if it lingers.
      }

      // 7. Trigger the native HarmonyOS print dialog.
      print.print([fileUri.getUriFromPath(pdfPath)], context)
        .catch((err: Error) => {
          console.error('Print failed: ' + err.message);
        });

    } catch (err) {
      console.error('PDF generation failed: ' + JSON.stringify(err));
      promptAction.showToast({ message: L.get('export_failed') });
    }
  }
}