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

      // Use filesDir for better persistence and stability
      const imagePath: string = context.filesDir + '/' + fileName + '.jpg';

      const imageFile: fs.File = fs.openSync(
        imagePath,
        fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC
      );

      await imagePacker.packToFile(pixelMap, imageFile.fd, packOpts);
      fs.closeSync(imageFile);

      // Verify the image file was created and is not empty
      if (fs.statSync(imagePath).size === 0) {
        throw new Error('Generated image file is empty.');
      }

      // 3. Create the PDF and insert the image.
      const pdfDoc: pdfService.PdfDocument = new pdfService.PdfDocument();
      const pdfPath: string = context.filesDir + '/' + fileName + '.pdf';

      pdfDoc.createDocument(595.28, 841.89); // A4 size in points
      const page: pdfService.PdfPage = pdfDoc.getPage(0);

      // Insert the JPEG image
      page.addImageObject(imagePath, 0, 0, 595.28, 841.89);

      // Save the PDF
      const saveResult = pdfDoc.saveDocument(pdfPath);
      pdfDoc.releaseDocument();

      // Check the save result if the API provides one
      // if (saveResult !== pdfService.ParseResult.PARSE_SUCCESS) {
      //    throw new Error('Failed to save PDF document.');
      // }

      promptAction.showToast({ message: L.get('export_success') });

      // 4. Trigger the native HarmonyOS print dialog.
      // Use fileUri for the print service.
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