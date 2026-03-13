using LawyerSys.Services.Pdf;

var outputPath = Path.Combine(AppContext.BaseDirectory, "receipt-preview.pdf");
var pdf = ReceiptPdfBuilder.BuildCustomerReceipt(
    officeName: "Atlas Litigation Hub",
    officePhone: "+20 100 000 0000",
    customerName: "Atlas Customer",
    receiptNumber: 4201,
    paymentDate: new DateOnly(2026, 3, 10),
    amount: 4200,
    notes: "Retainer received for case preparation, evidence review, and upcoming hearing coordination.",
    caseCode: 3012);

await File.WriteAllBytesAsync(outputPath, pdf);
Console.WriteLine(outputPath);
