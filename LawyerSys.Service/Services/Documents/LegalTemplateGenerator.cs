using LawyerSys.Services.Reporting;
using System.Globalization;
using System.Text;
using DocumentFormat.OpenXml;
using DocumentFormat.OpenXml.Packaging;
using DocumentFormat.OpenXml.Wordprocessing;

namespace LawyerSys.Services.Documents;

public static class LegalTemplateGenerator
{
    private static readonly Dictionary<string, (string Name, string Description, string Body)> TemplatesEn = new(StringComparer.OrdinalIgnoreCase)
    {
        // Original Templates
        ["power-of-attorney"] = (
            "Power Of Attorney",
            "Generate a power of attorney draft with case and customer details.",
            "POWER OF ATTORNEY\n\nClient: {{CustomerName}}\nCase Code: {{CaseCode}}\nCase Type: {{CaseType}}\nDate: {{Today}}\n\nI, {{CustomerName}}, hereby appoint {{LawyerName}} as my legal attorney to represent me in the above case.\n\nScope of Authority:\n{{Scope}}\n\nThis power of attorney is valid until revoked in writing.\n\nClient Signature: ____________________\nDate: ____________________\n"
        ),
        ["contract"] = (
            "Legal Services Contract",
            "Generate a legal services contract draft.",
            "LEGAL SERVICES CONTRACT\n\nThis agreement is made on {{Today}} between {{LawFirmName}} and {{CustomerName}} regarding case {{CaseCode}} ({{CaseType}}).\n\nScope of Services:\n{{Scope}}\n\nFee Agreement:\n{{FeeTerms}}\n\nTerm: This agreement shall remain in effect until the conclusion of the matter or termination by either party.\n\nClient Signature: ____________________\nDate: ____________________\n\nLawyer Signature: ____________________\nDate: ____________________\n"
        ),
        ["court-filing"] = (
            "Court Filing Draft",
            "Generate a court filing draft with case context.",
            "COURT FILING DRAFT\n\nTo: {{CourtName}}\nCase Code: {{CaseCode}}\nCase Type: {{CaseType}}\nFiled by: {{LawyerName}}\nOn behalf of: {{CustomerName}}\nDate: {{Today}}\n\nSubject:\n{{Subject}}\n\nStatement:\n{{Statement}}\n\nRespectfully submitted,\n{{LawyerName}}\n{{LawFirmName}}\n"
        ),
        
        // New Templates - Motions
        ["motion-to-dismiss"] = (
            "Motion to Dismiss",
            "Generate a motion to dismiss with supporting arguments.",
            "MOTION TO DISMISS\n\nTo: {{CourtName}}\nCase Code: {{CaseCode}}\nCase Type: {{CaseType}}\nMovant: {{CustomerName}}\nRepresented by: {{LawyerName}}\nDate: {{Today}}\n\nComes now {{CustomerName}}, by and through counsel {{LawyerName}}, and respectfully moves this Court to dismiss the above-referenced case.\n\nGrounds:\n{{Statement}}\n\nWherefore, movant respectfully requests that this Court grant this motion and dismiss this case.\n\nRespectfully submitted,\n{{LawyerName}}\n{{LawFirmName}}\n"
        ),
        ["motion-summary-judgment"] = (
            "Motion for Summary Judgment",
            "Generate a motion for summary judgment.",
            "MOTION FOR SUMMARY JUDGMENT\n\nTo: {{CourtName}}\nCase Code: {{CaseCode}}\nCase Type: {{CaseType}}\nMovant: {{CustomerName}}\nDate: {{Today}}\n\nComes now {{CustomerName}}, and moves this Court for summary judgment pursuant to applicable rules of civil procedure.\n\nStatement of Facts:\n{{Statement}}\n\nLegal Argument:\n{{Subject}}\n\nConclusion:\nFor the foregoing reasons, movant respectfully requests that this Court grant summary judgment in favor of {{CustomerName}}.\n\nRespectfully submitted,\n{{LawyerName}}\n{{LawFirmName}}\n"
        ),
        
        // New Templates - Letters
        ["demand-letter"] = (
            "Demand Letter",
            "Generate a formal demand letter to opposing party.",
            "DEMAND LETTER\n\nDate: {{Today}}\nFrom: {{LawyerName}}, {{LawFirmName}}\nOn behalf of: {{CustomerName}}\n\nRE: {{Subject}}\n\nDear Sir/Madam,\n\nThis letter serves as formal demand on behalf of our client, {{CustomerName}}, regarding {{CaseType}}.\n\nFacts:\n{{Statement}}\n\nDemand:\n{{Scope}}\n\nPlease respond to this demand within 14 days of receipt. Failure to respond may result in legal action without further notice.\n\nSincerely,\n{{LawyerName}}\n{{LawFirmName}}\n"
        ),
        ["engagement-letter"] = (
            "Engagement Letter",
            "Generate a client engagement letter.",
            "ENGAGEMENT LETTER\n\nDate: {{Today}}\nTo: {{CustomerName}}\nFrom: {{LawyerName}}, {{LawFirmName}}\n\nRE: Legal Representation - {{CaseType}}\n\nDear {{CustomerName}},\n\nThank you for choosing our firm. This letter confirms our engagement to represent you in the matter referenced above.\n\nScope of Representation:\n{{Scope}}\n\nFee Arrangement:\n{{FeeTerms}}\n\nClient Responsibilities:\nYou agree to cooperate fully, provide all requested information, and keep us informed of any developments.\n\nPlease sign below to acknowledge your agreement to these terms.\n\nSincerely,\n{{LawyerName}}\n{{LawFirmName}}\n\nClient Acknowledgment:\nSignature: ____________________\nDate: ____________________\n"
        ),
        ["termination-letter"] = (
            "Termination Letter",
            "Generate a letter terminating legal representation.",
            "TERMINATION OF REPRESENTATION\n\nDate: {{Today}}\nTo: {{CustomerName}}\nFrom: {{LawyerName}}, {{LawFirmName}}\n\nRE: Termination of Legal Representation - Case {{CaseCode}}\n\nDear {{CustomerName}},\n\nThis letter confirms that our representation of you in the above matter has concluded as of {{Today}}.\n\nReason for Termination:\n{{Statement}}\n\nYour files and documents will be made available to you or your new counsel upon request. Please note that you remain responsible for any outstanding fees.\n\nWe wish you the best in your future endeavors.\n\nSincerely,\n{{LawyerName}}\n{{LawFirmName}}\n"
        ),
        
        // New Templates - Pleadings
        ["complaint"] = (
            "Complaint",
            "Generate a formal complaint for court filing.",
            "COMPLAINT\n\nTo: {{CourtName}}\nCase Code: {{CaseCode}}\nPlaintiff: {{CustomerName}}\nRepresented by: {{LawyerName}}\nDate: {{Today}}\n\nComes now {{CustomerName}}, Plaintiff, by and through counsel, and files this Complaint against Defendant(s).\n\nJURISDICTION AND VENUE\nThis Court has jurisdiction over this matter pursuant to applicable law.\n\nPARTIES\nPlaintiff {{CustomerName}} is a resident of the jurisdiction.\n\nFACTS\n{{Statement}}\n\nCLAIMS FOR RELIEF\n{{Subject}}\n\nPRAYER FOR RELIEF\nWherefore, Plaintiff requests that this Court:\n{{Scope}}\n\nRespectfully submitted,\n{{LawyerName}}\n{{LawFirmName}}\n"
        ),
        ["answer"] = (
            "Answer to Complaint",
            "Generate an answer to a complaint.",
            "ANSWER TO COMPLAINT\n\nTo: {{CourtName}}\nCase Code: {{CaseCode}}\nDefendant: {{CustomerName}}\nRepresented by: {{LawyerName}}\nDate: {{Today}}\n\nComes now {{CustomerName}}, Defendant, and responds to the Complaint filed in this matter.\n\nGENERAL DENIAL\nDefendant denies each and every allegation contained in the Complaint, except as specifically admitted herein.\n\nAFFIRMATIVE DEFENSES\n{{Statement}}\n\nCOUNTERCLAIMS\n{{Subject}}\n\nWherefore, Defendant requests that this Court dismiss the Complaint and grant such other relief as the Court deems just.\n\nRespectfully submitted,\n{{LawyerName}}\n{{LawFirmName}}\n"
        ),
        
        // New Templates - Agreements
        ["settlement-agreement"] = (
            "Settlement Agreement",
            "Generate a settlement agreement between parties.",
            "SETTLEMENT AGREEMENT\n\nThis Settlement Agreement is entered into on {{Today}} between the parties in Case {{CaseCode}}.\n\nPARTIES\nParty 1: {{CustomerName}}\nRepresented by: {{LawyerName}}\n\nRECITALS\nWhereas, the parties desire to resolve all disputes related to {{CaseType}}.\n\nTERMS OF SETTLEMENT\n{{Scope}}\n\nPAYMENT TERMS\n{{FeeTerms}}\n\nRELEASE\nUpon fulfillment of the terms, each party releases the other from all claims related to this matter.\n\nMISCELLANEOUS\nThis agreement constitutes the entire agreement between the parties.\n\nParty 1 Signature: ____________________\nDate: ____________________\n\nParty 2 Signature: ____________________\nDate: ____________________\n"
        ),
        ["nda"] = (
            "Non-Disclosure Agreement",
            "Generate a non-disclosure agreement.",
            "NON-DISCLOSURE AGREEMENT\n\nThis Non-Disclosure Agreement ('Agreement') is entered into on {{Today}}.\n\nPARTIES\nDisclosing Party: {{LawFirmName}}\nReceiving Party: {{CustomerName}}\n\nPURPOSE\n{{Subject}}\n\nOBLIGATIONS\nThe Receiving Party agrees to:\n1. Keep all Confidential Information strictly confidential\n2. Use the information only for the stated purpose\n3. Not disclose to any third parties without written consent\n\nSCOPE OF CONFIDENTIAL INFORMATION\n{{Scope}}\n\nTERM\nThis Agreement shall remain in effect for a period specified in {{FeeTerms}} or until terminated by written notice.\n\nReceiving Party Signature: ____________________\nDate: ____________________\n"
        ),
        
        // New Templates - Discovery
        ["interrogatories"] = (
            "Interrogatories",
            "Generate interrogatories for discovery.",
            "INTERROGATORIES\n\nTo: {{CourtName}}\nCase Code: {{CaseCode}}\nPropounding Party: {{CustomerName}}\nby {{LawyerName}}\nDate: {{Today}}\n\nPursuant to applicable rules of civil procedure, {{CustomerName}} propounds the following interrogatories to be answered under oath within the time prescribed by law.\n\nDEFINITIONS AND INSTRUCTIONS\nThese interrogatories are continuing in nature. Please supplement your answers if you obtain additional information.\n\nINTERROGATORIES\n{{Statement}}\n\nPlease respond within 30 days of service.\n\nRespectfully submitted,\n{{LawyerName}}\n{{LawFirmName}}\n"
        ),
        
        // New Templates - Other
        ["legal-memo"] = (
            "Legal Memorandum",
            "Generate an internal legal memorandum.",
            "LEGAL MEMORANDUM\n\nTo: File\nFrom: {{LawyerName}}\nDate: {{Today}}\nRE: {{Subject}} - Case {{CaseCode}}\n\nQUESTION PRESENTED\n{{Subject}}\n\nBRIEF ANSWER\n{{Scope}}\n\nFACTS\n{{Statement}}\n\nDISCUSSION\n[Analysis to be completed]\n\nCONCLUSION\n[Conclusion to be completed]\n\n{{LawyerName}}\n{{LawFirmName}}\n"
        ),
        ["affidavit"] = (
            "Affidavit",
            "Generate a sworn affidavit.",
            "AFFIDAVIT\n\nCOURT: {{CourtName}}\nCase Code: {{CaseCode}}\nCase Type: {{CaseType}}\n\nSTATE OF ____________\nCOUNTY OF ____________\n\nI, {{CustomerName}}, being duly sworn, depose and state:\n\n1. I am over the age of 18 and competent to make this affidavit.\n\n2. I have personal knowledge of the facts stated herein.\n\n3. {{Statement}}\n\n4. The foregoing is true and correct to the best of my knowledge.\n\nAffiant: {{CustomerName}}\n\nSignature: ____________________\nDate: {{Today}}\n\nSWORN TO AND SUBSCRIBED before me this _____ day of ________, 20___.\n\nNotary Public: ____________________\n"
        ),
        
        // Additional Templates - Agreements
        ["lease-agreement"] = (
            "Lease Agreement",
            "Generate a property lease agreement.",
            "LEASE AGREEMENT\n\nThis Lease Agreement is entered into on {{Today}}.\n\nLANDLORD: {{LawFirmName}}\nTENANT: {{CustomerName}}\n\nPROPERTY DESCRIPTION\n{{Subject}}\n\nLEASE TERMS\n{{Scope}}\n\nRENT AND PAYMENT\n{{FeeTerms}}\n\nSECURITY DEPOSIT\nTenant shall pay a security deposit as specified in the payment terms.\n\nMAINTENANCE AND REPAIRS\nTenant shall maintain the premises in good condition. Landlord shall be responsible for major structural repairs.\n\nDEFAULT\nIn the event of default, Landlord may terminate this lease and take possession of the premises.\n\nGOVERNING LAW\nThis lease shall be governed by applicable laws.\n\nLandlord Signature: ____________________\nDate: ____________________\n\nTenant Signature: ____________________\nDate: ____________________\n"
        ),
        ["sublease-agreement"] = (
            "Sublease Agreement",
            "Generate a sublease agreement for property.",
            "SUBLEASE AGREEMENT\n\nThis Sublease Agreement is entered into on {{Today}}.\n\nORIGINAL LANDLORD: ____________________\nSUBLESSOR: {{LawFirmName}}\nSUBLESSEE: {{CustomerName}}\n\nPROPERTY DESCRIPTION\n{{Subject}}\n\nMASTER LEASE REFERENCE\nThis sublease is subject to the terms of the master lease dated ____________.\n\nSUBLEASE TERMS\n{{Scope}}\n\nRENT AND PAYMENT\n{{FeeTerms}}\n\nCONSENT\nThis sublease is made with the consent of the original landlord.\n\nSublessor Signature: ____________________\nDate: ____________________\n\nSublessee Signature: ____________________\nDate: ____________________\n"
        ),
        ["employment-contract"] = (
            "Employment Contract",
            "Generate an employment contract.",
            "EMPLOYMENT CONTRACT\n\nThis Employment Contract is entered into on {{Today}}.\n\nEMPLOYER: {{LawFirmName}}\nEMPLOYEE: {{CustomerName}}\n\nPOSITION AND DUTIES\n{{Subject}}\n\nJOB RESPONSIBILITIES\n{{Scope}}\n\nCOMPENSATION AND BENEFITS\n{{FeeTerms}}\n\nTERM OF EMPLOYMENT\nThis employment shall commence on ____________ and continue until terminated by either party.\n\nCONFIDENTIALITY\nEmployee agrees to maintain confidentiality of all proprietary information.\n\nTERMINATION\nEither party may terminate this agreement with appropriate notice as required by law.\n\nGOVERNING LAW\nThis contract shall be governed by applicable laws.\n\nEmployer Signature: ____________________\nDate: ____________________\n\nEmployee Signature: ____________________\nDate: ____________________\n"
        ),
        ["service-agreement"] = (
            "Service Agreement",
            "Generate a general service agreement.",
            "SERVICE AGREEMENT\n\nThis Service Agreement is entered into on {{Today}}.\n\nSERVICE PROVIDER: {{LawFirmName}}\nCLIENT: {{CustomerName}}\n\nSERVICES TO BE PROVIDED\n{{Subject}}\n\nSCOPE OF WORK\n{{Scope}}\n\nPAYMENT TERMS\n{{FeeTerms}}\n\nTERM\nThis agreement shall commence on ____________ and continue until completion of services or termination.\n\nCONFIDENTIALITY\nBoth parties agree to maintain confidentiality of shared information.\n\nLIMITATION OF LIABILITY\nService provider's liability shall be limited to the total fees paid under this agreement.\n\nGOVERNING LAW\nThis agreement shall be governed by applicable laws.\n\nService Provider Signature: ____________________\nDate: ____________________\n\nClient Signature: ____________________\nDate: ____________________\n"
        ),
        ["partnership-agreement"] = (
            "Partnership Agreement",
            "Generate a business partnership agreement.",
            "PARTNERSHIP AGREEMENT\n\nThis Partnership Agreement is entered into on {{Today}}.\n\nPARTNERS:\n{{CustomerName}}\n{{LawFirmName}}\n\nPARTNERSHIP NAME\n{{Subject}}\n\nPURPOSE OF PARTNERSHIP\n{{Scope}}\n\nCAPITAL CONTRIBUTIONS\n{{FeeTerms}}\n\nPROFIT AND LOSS DISTRIBUTION\nProfits and losses shall be distributed according to each partner's capital contribution.\n\nMANAGEMENT AND AUTHORITY\nEach partner shall have equal authority in management decisions.\n\nADMISSION AND WITHDRAWAL\nNew partners may be admitted with unanimous consent. A partner may withdraw with appropriate notice.\n\nDISSOLUTION\nThe partnership may be dissolved by mutual agreement or as required by law.\n\nPartner 1 Signature: ____________________\nDate: ____________________\n\nPartner 2 Signature: ____________________\nDate: ____________________\n"
        ),
        ["release-form"] = (
            "Release and Waiver Form",
            "Generate a liability release and waiver form.",
            "RELEASE AND WAIVER FORM\n\nDate: {{Today}}\n\nRELEASOR: {{CustomerName}}\nRELEASEE: {{LawFirmName}}\n\nRELEASE DESCRIPTION\n{{Subject}}\n\nIn consideration of {{Scope}}, the undersigned hereby releases, waives, and forever discharges the Releasee from any and all claims, demands, damages, actions, or causes of action arising from {{Statement}}.\n\nACKNOWLEDGMENT\nThe undersigned acknowledges having read and understood this release, and signs it voluntarily.\n\nTHIS RELEASE IS INTENDED TO BE A COMPLETE BAR TO ALL CLAIMS.\n\nReleasor Signature: ____________________\nDate: ____________________\n\nWitness Signature: ____________________\nDate: ____________________\n"
        ),
        
        // Additional Templates - Legal Notices
        ["cease-and-desist"] = (
            "Cease and Desist Letter",
            "Generate a cease and desist letter.",
            "CEASE AND DESIST LETTER\n\nDate: {{Today}}\nFrom: {{LawyerName}}, {{LawFirmName}}\nOn behalf of: {{CustomerName}}\n\nTo: ____________________\n\nRE: CEASE AND DESIST - {{Subject}}\n\nDear Sir/Madam,\n\nYou are hereby directed to CEASE AND DESIST all activities related to:\n\n{{Statement}}\n\nOur client, {{CustomerName}}, has rights that are being violated by your actions. These activities include but are not limited to:\n\n{{Scope}}\n\nDEMAND\nYou are hereby requested to immediately:\n1. Cease all activities described above\n2. Provide written confirmation of compliance within 10 days\n3. Refrain from any future violations\n\nLEGAL CONSEQUENCES\nFailure to comply may result in legal action seeking injunctive relief, damages, and attorney fees.\n\nSincerely,\n{{LawyerName}}\n{{LawFirmName}}\n"
        ),
        ["legal-notice"] = (
            "Legal Notice",
            "Generate a formal legal notice.",
            "LEGAL NOTICE\n\nDate: {{Today}}\nFrom: {{LawyerName}}, {{LawFirmName}}\nRepresenting: {{CustomerName}}\n\nTo: ____________________\n\nRE: {{Subject}}\n\nTAKE NOTICE that {{CustomerName}} hereby provides the following notice:\n\n{{Statement}}\n\nPARTICULARS\n{{Scope}}\n\nRELIEF SOUGHT\n{{FeeTerms}}\n\nYou are required to respond to this notice within 15 days of receipt. Failure to respond may result in appropriate legal proceedings without further notice.\n\nISSUED BY:\n{{LawyerName}}\n{{LawFirmName}}\n\nDate: {{Today}}\n"
        ),
        
        // Additional Templates - Court Documents
        ["appeal-brief"] = (
            "Appeal Brief",
            "Generate an appeal brief for appellate court.",
            "APPEAL BRIEF\n\nCOURT: {{CourtName}}\nAPPELLATE DIVISION\nCase Code: {{CaseCode}}\nCase Type: {{CaseType}}\n\nAPPELLANT: {{CustomerName}}\nAPPELLEE: ____________________\n\nCOUNSEL\n{{LawyerName}}\n{{LawFirmName}}\n\nDate: {{Today}}\n\nTABLE OF CONTENTS\n[To be completed]\n\nTABLE OF AUTHORITIES\n[To be completed]\n\nSTATEMENT OF JURISDICTION\nThis Court has jurisdiction over this appeal pursuant to applicable law.\n\nSTATEMENT OF THE CASE\n{{Statement}}\n\nISSUES PRESENTED\n{{Subject}}\n\nARGUMENT\n{{Scope}}\n\nCONCLUSION\nFor the foregoing reasons, Appellant respectfully requests that this Court reverse the decision below and grant such other relief as the Court deems appropriate.\n\nRespectfully submitted,\n{{LawyerName}}\n{{LawFirmName}}\nCounsel for Appellant\n"
        ),
        ["writ-of-execution"] = (
            "Writ of Execution",
            "Generate a writ of execution for judgment enforcement.",
            "WRIT OF EXECUTION\n\nCOURT: {{CourtName}}\nCase Code: {{CaseCode}}\nCase Type: {{CaseType}}\n\nJUDGMENT CREDITOR: {{CustomerName}}\nJUDGMENT DEBTOR: ____________________\nDate: {{Today}}\n\nTO THE SHERIFF OR OTHER AUTHORIZED OFFICER:\n\nWHEREAS, a judgment was entered in the above-entitled case on ____________ in favor of {{CustomerName}} for:\n\n{{FeeTerms}}\n\nNOW, THEREFORE, you are commanded to execute this writ by levying upon the property of the Judgment Debtor, including but not limited to:\n\n{{Scope}}\n\n{{Statement}}\n\nYou are further commanded to make return of this writ within the time prescribed by law.\n\nISSUED under the seal of this Court on {{Today}}.\n\nCLERK OF COURT: ____________________\n\nBy: ____________________\nDeputy Clerk\n"
        )
    };


    private static readonly Dictionary<string, (string Name, string Description, string Body)> TemplatesAr = new(StringComparer.OrdinalIgnoreCase)
    {
        // Original Templates
        ["power-of-attorney"] = (
            "توكيل",
            "إنشاء مسودة توكيل مع تفاصيل القضية والعميل.",
            "توكيل\n\nالعميل: {{CustomerName}}\nرقم القضية: {{CaseCode}}\nنوع القضية: {{CaseType}}\nالتاريخ: {{Today}}\n\nأنا، {{CustomerName}}، أقوم بتعيين {{LawyerName}} كمحامي قانوني لتمثيلني في القضية المذكورة أعلاه.\n\nنطاق الصلاحيات:\n{{Scope}}\n\nهذا التوكيل ساري المفعول حتى يتم إلغاؤه كتابيًا.\n\nتوقيع العميل: ____________________\nالتاريخ: ____________________\n"
        ),
        ["contract"] = (
            "عقد الخدمات القانونية",
            "إنشاء مسودة عقد خدمات قانونية.",
            "عقد الخدمات القانونية\n\nتم إبرام هذا الاتفاق في {{Today}} بين {{LawFirmName}} و {{CustomerName}} بشأن القضية {{CaseCode}} ({{CaseType}}).\n\nنطاق الخدمات:\n{{Scope}}\n\nاتفاقية الأتعاب:\n{{FeeTerms}}\n\nالمدة: يظل هذا العقد ساري المفعول حتى انتهاء الموضوع أو إنهائه من قبل أي من الطرفين.\n\nتوقيع العميل: ____________________\nالتاريخ: ____________________\n\nتوقيع المحامي: ____________________\nالتاريخ: ____________________\n"
        ),
        ["court-filing"] = (
            "مسودة قيد المحكمة",
            "إنشاء مسودة قيد محكمة مع سياق القضية.",
            "مسودة قيد المحكمة\n\nإلى: {{CourtName}}\nرقم القضية: {{CaseCode}}\nنوع القضية: {{CaseType}}\nمقدم بواسطة: {{LawyerName}}\nنيابة عن: {{CustomerName}}\nالتاريخ: {{Today}}\n\nالموضوع:\n{{Subject}}\n\nالبيان:\n{{Statement}}\n\nمع فائق الاحترام،\n{{LawyerName}}\n{{LawFirmName}}\n"
        ),
        
        // New Templates - Motions
        ["motion-to-dismiss"] = (
            "طلب رفض الدعوى",
            "إنشاء طلب لرفض الدعوى مع الحجج الداعمة.",
            "طلب رفض الدعوى\n\nإلى: {{CourtName}}\nرقم القضية: {{CaseCode}}\nنوع القضية: {{CaseType}}\nمقدم الطلب: {{CustomerName}}\nممثل بواسطة: {{LawyerName}}\nالتاريخ: {{Today}}\n\nيتقدم {{CustomerName}}، من خلال محاميه {{LawyerName}}، بطلب إلى هذه المحكمة لرفض الدعوى المذكورة أعلاه.\n\nالأسباب:\n{{Statement}}\n\nلذلك، يطلب مقدم الطلب من المحكمة الموافقة على هذا الطلب ورفض هذه الدعوى.\n\nمع فائق الاحترام،\n{{LawyerName}}\n{{LawFirmName}}\n"
        ),
        ["motion-summary-judgment"] = (
            "طلب حكم موجز",
            "إنشاء طلب للحصول على حكم موجز.",
            "طلب حكم موجز\n\nإلى: {{CourtName}}\nرقم القضية: {{CaseCode}}\nنوع القضية: {{CaseType}}\nمقدم الطلب: {{CustomerName}}\nالتاريخ: {{Today}}\n\nيتقدم {{CustomerName}} بطلب إلى هذه المحكمة للحصول على حكم موجز.\n\nبيان الوقائع:\n{{Statement}}\n\nالحجة القانونية:\n{{Subject}}\n\nالخلاصة:\nللأسباب المذكورة أعلاه، يطلب مقدم الطلب من المحكمة منح حكم موجز لصالح {{CustomerName}}.\n\nمع فائق الاحترام،\n{{LawyerName}}\n{{LawFirmName}}\n"
        ),
        
        // New Templates - Letters
        ["demand-letter"] = (
            "خطاب مطالبة",
            "إنشاء خطاب مطالبة رسمي للطرف المقابل.",
            "خطاب مطالبة\n\nالتاريخ: {{Today}}\nمن: {{LawyerName}}، {{LawFirmName}}\nنيابة عن: {{CustomerName}}\n\nالموضوع: {{Subject}}\n\nعزيزي السيد/السيدة،\n\nيعتبر هذا الخطاب مطالبة رسمية نيابة عن موكلنا {{CustomerName}} فيما يتعلق بـ {{CaseType}}.\n\nالوقائع:\n{{Statement}}\n\nالمطالبة:\n{{Scope}}\n\nيرجى الرد على هذه المطالبة في غضون 14 يومًا من الاستلام. قد يؤدي عدم الرد إلى اتخاذ إجراء قانوني دون إشعار آخر.\n\nمع خالص التحية،\n{{LawyerName}}\n{{LawFirmName}}\n"
        ),
        ["engagement-letter"] = (
            "خطاب تعيين",
            "إنشاء خطاب تعيين عميل.",
            "خطاب تعيين\n\nالتاريخ: {{Today}}\nإلى: {{CustomerName}}\nمن: {{LawyerName}}، {{LawFirmName}}\n\nالموضوع: التمثيل القانوني - {{CaseType}}\n\nعزيزي {{CustomerName}}،\n\nشكرًا لاختيارك مكتبنا. يؤكد هذا الخطاب تعييننا لتمثيلك في الموضوع المذكور أعلاه.\n\nنطاق التمثيل:\n{{Scope}}\n\nالاتفاق على الأتعاب:\n{{FeeTerms}}\n\nمسؤوليات العميل:\nتوافق على التعاون الكامل وتقديم جميع المعلومات المطلوبة وإبلاغنا بأي مستجدات.\n\nيرجى التوقيع أدناه للإقرار بموافقتك على هذه الشروط.\n\nمع خالص التحية،\n{{LawyerName}}\n{{LawFirmName}}\n\nإقرار العميل:\nالتوقيع: ____________________\nالتاريخ: ____________________\n"
        ),
        ["termination-letter"] = (
            "خطاب إنهاء التمثيل",
            "إنشاء خطاب لإنهاء التمثيل القانوني.",
            "إنهاء التمثيل القانوني\n\nالتاريخ: {{Today}}\nإلى: {{CustomerName}}\nمن: {{LawyerName}}، {{LawFirmName}}\n\nالموضوع: إنهاء التمثيل القانوني - القضية {{CaseCode}}\n\nعزيزي {{CustomerName}}،\n\nيؤكد هذا الخطاب أن تمثيلنا لك في الموضوع المذكور أعلاه قد انتهى اعتبارًا من {{Today}}.\n\nسبب الإنهاء:\n{{Statement}}\n\nستكون ملفاتك ومستنداتك متاحة لك أو لمحاميك الجديد عند الطلب. يرجى ملاحظة أنك تظل مسؤولاً عن أي رسوم مستحقة.\n\nنتمنى لك التوفيق في مساعيك المستقبلية.\n\nمع خالص التحية،\n{{LawyerName}}\n{{LawFirmName}}\n"
        ),
        
        // New Templates - Pleadings
        ["complaint"] = (
            "دعوى قضائية",
            "إنشاء دعوى قضائية رسمية لتقديمها للمحكمة.",
            "دعوى قضائية\n\nإلى: {{CourtName}}\nرقم القضية: {{CaseCode}}\nالمدعي: {{CustomerName}}\nممثل بواسطة: {{LawyerName}}\nالتاريخ: {{Today}}\n\nيتقدم {{CustomerName}}، المدعي، من خلال محاميه، بتقديم هذه الدعوى ضد المدعى عليه (عليهم).\n\nالاختصاص والمكان\nلهذه المحكمة اختصاص بهذا الموضوع.\n\nالأطراف\nالمدعي {{CustomerName}} مقيم في هذا الاختصاص.\n\nالوقائع\n{{Statement}}\n\nالمطالبات\n{{Subject}}\n\nالطلبات\nلذلك، يطلب المدعي من هذه المحكمة:\n{{Scope}}\n\nمع فائق الاحترام،\n{{LawyerName}}\n{{LawFirmName}}\n"
        ),
        ["answer"] = (
            "الرد على الدعوى",
            "إنشاء رد على دعوى قضائية.",
            "الرد على الدعوى\n\nإلى: {{CourtName}}\nرقم القضية: {{CaseCode}}\nالمدعى عليه: {{CustomerName}}\nممثل بواسطة: {{LawyerName}}\nالتاريخ: {{Today}}\n\nيرد {{CustomerName}}، المدعى عليه، على الدعوى المرفوعة في هذا الموضوع.\n\nالإنكار العام\nينكر المدعى عليه جميع الادعاءات الواردة في الدعوى، باستثناء ما تم الاعتراف به صراحة.\n\nالدفوع الإيجابية\n{{Statement}}\n\nالدعاوى المقابلة\n{{Subject}}\n\nلذلك، يطلب المدعى عليه من هذه المحكمة رفض الدعوى ومنح أي تعويض آخر تراه المحكمة عادلاً.\n\nمع فائق الاحترام،\n{{LawyerName}}\n{{LawFirmName}}\n"
        ),
        
        // New Templates - Agreements
        ["settlement-agreement"] = (
            "اتفاقية تسوية",
            "إنشاء اتفاقية تسوية بين الأطراف.",
            "اتفاقية تسوية\n\nتم إبرام اتفاقية التسوية هذه في {{Today}} بين الأطراف في القضية {{CaseCode}}.\n\nالأطراف\nالطرف الأول: {{CustomerName}}\nممثل بواسطة: {{LawyerName}}\n\nالديباجة\nحيث أن الأطراف يرغبون في حل جميع النزاعات المتعلقة بـ {{CaseType}}.\n\nشروط التسوية\n{{Scope}}\n\nشروط الدفع\n{{FeeTerms}}\n\nالإبراء\nعند الوفاء بالشروط، يبرئ كل طرف الطرف الآخر من جميع المطالبات المتعلقة بهذا الموضوع.\n\nأحكام متنوعة\nتشكل هذه الاتفاقية الاتفاق الكامل بين الأطراف.\n\nتوقيع الطرف الأول: ____________________\nالتاريخ: ____________________\n\nتوقيع الطرف الثاني: ____________________\nالتاريخ: ____________________\n"
        ),
        ["nda"] = (
            "اتفاقية عدم إفشاء",
            "إنشاء اتفاقية عدم إفشاء.",
            "اتفاقية عدم إفشاء\n\nتم إبرام اتفاقية عدم الإفشاء هذه ('الاتفاقية') في {{Today}}.\n\nالأطراف\nالطرف المفصح: {{LawFirmName}}\nالطرف المتلقي: {{CustomerName}}\n\nالغرض\n{{Subject}}\n\nالالتزامات\nيوافق الطرف المتلقي على:\n1. الحفاظ على جميع المعلومات السرية بشكل صارم\n2. استخدام المعلومات فقط للغرض المحدد\n3. عدم الإفصاح لأي طرف ثالث دون موافقة كتابية\n\nنطاق المعلومات السرية\n{{Scope}}\n\nالمدة\nتظل هذه الاتفاقية سارية المفعول للمدة المحددة في {{FeeTerms}} أو حتى يتم إنهاؤها بإشعار كتابي.\n\nتوقيع الطرف المتلقي: ____________________\nالتاريخ: ____________________\n"
        ),
        
        // New Templates - Discovery
        ["interrogatories"] = (
            "استجوابات",
            "إنشاء استجوابات للإثبات.",
            "استجوابات\n\nإلى: {{CourtName}}\nرقم القضية: {{CaseCode}}\nالطرف المقدم: {{CustomerName}}\nبواسطة {{LawyerName}}\nالتاريخ: {{Today}}\n\nوفقًا للقواعد المعمول بها، يقدم {{CustomerName}} الاستجوابات التالية للإجابة عليها تحت القسم خلال المدة المحددة بموجب القانون.\n\nالتعريفات والتعليمات\nهذه الاستجوابات ذات طبيعة مستمرة. يرجى استكمال إجاباتك إذا حصلت على معلومات إضافية.\n\nالاستجوابات\n{{Statement}}\n\nيرجى الرد خلال 30 يومًا من الإعلان.\n\nمع فائق الاحترام،\n{{LawyerName}}\n{{LawFirmName}}\n"
        ),
        
        // New Templates - Other
        ["legal-memo"] = (
            "مذكرة قانونية",
            "إنشاء مذكرة قانونية داخلية.",
            "مذكرة قانونية\n\nإلى: الملف\nمن: {{LawyerName}}\nالتاريخ: {{Today}}\nالموضوع: {{Subject}} - القضية {{CaseCode}}\n\nالسؤال المطروح\n{{Subject}}\n\nالجواب المختصر\n{{Scope}}\n\nالوقائع\n{{Statement}}\n\nالمناقشة\n[يتم إكمال التحليل]\n\nالخلاصة\n[يتم إكمال الخلاصة]\n\n{{LawyerName}}\n{{LawFirmName}}\n"
        ),
        ["affidavit"] = (
            "إقرار بالقسم",
            "إنشاء إقرار بالقسم.",
            "إقرار بالقسم\n\nالمحكمة: {{CourtName}}\nرقم القضية: {{CaseCode}}\nنوع القضية: {{CaseType}}\n\nالولاية: ____________\nالمحافظة: ____________\n\nأنا، {{CustomerName}}، بعد أداء اليمين القانونية، أقر وأشهد بما يلي:\n\n1. أنا فوق سن 18 وأهل لتقديم هذا الإقرار.\n\n2. لدي معرفة شخصية بالحقائق المذكورة هنا.\n\n3. {{Statement}}\n\n4. ما سبق صحيح ودقيق على حد علمي.\n\nالمقر: {{CustomerName}}\n\nالتوقيع: ____________________\nالتاريخ: {{Today}}\n\nتم أداء اليمين والتوقيع أمامي في يوم _____ من شهر ______، سنة 20___.\n\nالموثق: ____________________\n"
        ),
        
        // Additional Templates - Agreements
        ["lease-agreement"] = (
            "عقد إيجار",
            "إنشاء عقد إيجار عقار.",
            "عقد إيجار\n\nتم إبرام عقد الإيجار هذا في {{Today}}.\n\nالمؤجر: {{LawFirmName}}\nالمستأجر: {{CustomerName}}\n\nوصف العقار\n{{Subject}}\n\nشروط الإيجار\n{{Scope}}\n\nالإيجار والدفع\n{{FeeTerms}}\n\nالتأمين\nيدفع المستأجر تأمينًا كما هو محدد في شروط الدفع.\n\nالصيانة والإصلاحات\nيحافظ المستأجر على المكان بحالة جيدة. يتحمل المؤجر مسؤولية الإصلاحات الهيكلية الكبرى.\n\nالإخلال بالعقد\nفي حالة الإخلال، يجوز للمؤجر إنهاء هذا العقد واستعادة حيازة المكان.\n\nالقانون الواجب التطبيق\nيخضع هذا العقد للقوانين المعمول بها.\n\nتوقيع المؤجر: ____________________\nالتاريخ: ____________________\n\nتوقيع المستأجر: ____________________\nالتاريخ: ____________________\n"
        ),
        ["sublease-agreement"] = (
            "عقد إيجار من الباطن",
            "إنشاء عقد إيجار من الباطن لعقار.",
            "عقد إيجار من الباطن\n\nتم إبرام عقد الإيجار من الباطن هذا في {{Today}}.\n\nالمؤجر الأصلي: ____________________\nالمؤجر من الباطن: {{LawFirmName}}\nالمستأجر من الباطن: {{CustomerName}}\n\nوصف العقار\n{{Subject}}\n\nالإشارة لعقد الإيجار الأصلي\nيخضع هذا العقد لشروط عقد الإيجار الأصلي المؤرخ ____________.\n\nشروط الإيجار من الباطن\n{{Scope}}\n\nالإيجار والدفع\n{{FeeTerms}}\n\nالموافقة\nتم إبرام هذا العقد بموافقة المؤجر الأصلي.\n\nتوقيع المؤجر من الباطن: ____________________\nالتاريخ: ____________________\n\nتوقيع المستأجر من الباطن: ____________________\nالتاريخ: ____________________\n"
        ),
        ["employment-contract"] = (
            "عقد عمل",
            "إنشاء عقد عمل.",
            "عقد عمل\n\nتم إبرام عقد العمل هذا في {{Today}}.\n\nصاحب العمل: {{LawFirmName}}\nالموظف: {{CustomerName}}\n\nالمنصاب والمهام\n{{Subject}}\n\nمسؤوليات الوظيفة\n{{Scope}}\n\nالراتب والمزايا\n{{FeeTerms}}\n\nمدة العمالة\nتبدأ هذه العمالة في ____________ وتستمر حتى إنهائها من أي من الطرفين.\n\nالسرية\nيوافق الموظف على الحفاظ على سرية جميع المعلومات الخاصة.\n\nالإنهاء\nيجوز لأي من الطرفين إنهاء هذا العقد بإشعار مناسب حسب ما يقتضيه القانون.\n\nالقانون الواجب التطبيق\nيخضع هذا العقد للقوانين المعمول بها.\n\nتوقيع صاحب العمل: ____________________\nالتاريخ: ____________________\n\nتوقيع الموظف: ____________________\nالتاريخ: ____________________\n"
        ),
        ["service-agreement"] = (
            "عقد خدمات",
            "إنشاء عقد خدمات عام.",
            "عقد خدمات\n\nتم إبرام عقد الخدمات هذا في {{Today}}.\n\nمقدم الخدمة: {{LawFirmName}}\nالعميل: {{CustomerName}}\n\nالخدمات المقدمة\n{{Subject}}\n\nنطاق العمل\n{{Scope}}\n\nشروط الدفع\n{{FeeTerms}}\n\nالمدة\nيبدأ هذا العقد في ____________ ويستمر حتى إتمام الخدمات أو الإنهاء.\n\nالسرية\nيوافق كلا الطرفين على الحفاظ على سرية المعلومات المشتركة.\n\nتحديد المسؤولية\nتكون مسؤولية مقدم الخدمة محدودة بإجمالي الرسوم المدفوعة بموجب هذا العقد.\n\nالقانون الواجب التطبيق\nيخضع هذا العقد للقوانين المعمول بها.\n\nتوقيع مقدم الخدمة: ____________________\nالتاريخ: ____________________\n\nتوقيع العميل: ____________________\nالتاريخ: ____________________\n"
        ),
        ["partnership-agreement"] = (
            "عقد شراكة",
            "إنشاء عقد شراكة تجارية.",
            "عقد شراكة\n\nتم إبرام عقد الشراكة هذا في {{Today}}.\n\nالشركاء:\n{{CustomerName}}\n{{LawFirmName}}\n\nاسم الشراكة\n{{Subject}}\n\nغرض الشراكة\n{{Scope}}\n\nمساهمات رأس المال\n{{FeeTerms}}\n\nتوزيع الأرباح والخسائر\nيتم توزيع الأرباح والخسائر حسب مساهمة كل شريك في رأس المال.\n\nالإدارة والصلاحيات\nيملك كل شريك صلاحية متساوية في قرارات الإدارة.\n\nالانضمام والانسحاب\nيجوز انضمام شركاء جدد بموافقة جماعية. يجوز للشريك الانسحاب بإشعار مناسب.\n\nالحل\nيجوز حل الشراكة بالاتفاق المتبادل أو حسب ما يقتضيه القانون.\n\nتوقيع الشريك الأول: ____________________\nالتاريخ: ____________________\n\nتوقيع الشريك الثاني: ____________________\nالتاريخ: ____________________\n"
        ),
        ["release-form"] = (
            "نموذج إبراء ذمة وتنازل",
            "إنشاء نموذج إبراء ذمة وتنازل عن المسؤولية.",
            "نموذج إبراء ذمة وتنازل\n\nالتاريخ: {{Today}}\n\nالمتنازل: {{CustomerName}}\nالمتنازل له: {{LawFirmName}}\n\nوصف الإبراء\n{{Subject}}\n\nنظرًا لـ {{Scope}}، يتنازل الموقع أدناه ويبرئ ذمة المتنازل له من جميع المطالبات والمطالب والأضرار والإجراءات أو أسباب الإجراءات الناشئة عن {{Statement}}.\n\nالإقرار\nيقر الموقع أدناه بقراءته وفهمه لهذا الإبراء، ويوقعه طواعية.\n\nهذا الإبراء يُعد حاجزًا كاملاً لجميع المطالبات.\n\nتوقيع المتنازل: ____________________\nالتاريخ: ____________________\n\nتوقيع الشاهد: ____________________\nالتاريخ: ____________________\n"
        ),
        
        // Additional Templates - Legal Notices
        ["cease-and-desist"] = (
            "خطاب كف وإزعاج",
            "إنشاء خطاب كف وإزعاج.",
            "خطاب كف وإزعاج\n\nالتاريخ: {{Today}}\nمن: {{LawyerName}}، {{LawFirmName}}\nنيابة عن: {{CustomerName}}\n\nإلى: ____________________\n\nالموضوع: كف وإزعاج - {{Subject}}\n\nعزيزي السيد/السيدة،\n\nيتم توجيهك بموجب هذا إلى الكف عن جميع الأنشطة المتعلقة بـ:\n\n{{Statement}}\n\nلموكلنا {{CustomerName}} حقوق يتم انتهاكها من خلال تصرفاتك. تشمل هذه الأنشطة على سبيل المثال لا الحصر:\n\n{{Scope}}\n\nالمطالبة\nيُطلب منك فورًا:\n1. الكف عن جميع الأنشطة المذكورة أعلاه\n2. تقديم تأكيد كتابي بالامتثال خلال 10 أيام\n3. الامتناع عن أي انتهاكات مستقبلية\n\nالعواقب القانونية\nعدم الامتثال قد يؤدي إلى إجراءات قانونية تطلب إعفاء قضائي وتعويضات وأتعاب المحامين.\n\nمع خالص التحية،\n{{LawyerName}}\n{{LawFirmName}}\n"
        ),
        ["legal-notice"] = (
            "إشعار قانوني",
            "إنشاء إشعار قانوني رسمي.",
            "إشعار قانوني\n\nالتاريخ: {{Today}}\nمن: {{LawyerName}}، {{LawFirmName}}\nنيابة عن: {{CustomerName}}\n\nإلى: ____________________\n\nالموضوع: {{Subject}}\n\nيُعلَم بموجب هذا أن {{CustomerName}} يقدم الإشعار التالي:\n\n{{Statement}}\n\nالتفاصيل\n{{Scope}}\n\nالتعويض المطلوب\n{{FeeTerms}}\n\nيُطلب منك الرد على هذا الإشعار خلال 15 يومًا من الاستلام. عدم الرد قد يؤدي إلى إجراءات قانونية مناسبة دون إشعار آخر.\n\nصادر عن:\n{{LawyerName}}\n{{LawFirmName}}\n\nالتاريخ: {{Today}}\n"
        ),
        
        // Additional Templates - Court Documents
        ["appeal-brief"] = (
            "مذكرة استئناف",
            "إنشاء مذكرة استئناف لمحكمة الاستئناف.",
            "مذكرة استئناف\n\nالمحكمة: {{CourtName}}\nمحكمة الاستئناف\nرقم القضية: {{CaseCode}}\nنوع القضية: {{CaseType}}\n\nالمستأنف: {{CustomerName}}\nالمستأنف ضده: ____________________\n\nالمحامي\n{{LawyerName}}\n{{LawFirmName}}\n\nالتاريخ: {{Today}}\n\nجدول المحتويات\n[يتم إكماله]\n\nجدول المراجع\n[يتم إكماله]\n\nبيان الاختصاص\nلهذه المحكمة اختصاص بهذا الاستئناف.\n\nبيان القضية\n{{Statement}}\n\nالقضايا المطروحة\n{{Subject}}\n\nالمرافعة\n{{Scope}}\n\nالخلاصة\nللأسباب المذكورة أعلاه، يطلب المستأنف من هذه المحكمة إلغاء القرار أدناه ومنح أي تعويض آخر تراه المحكمة مناسبًا.\n\nمع فائق الاحترام،\n{{LawyerName}}\n{{LawFirmName}}\nمحامي المستأنف\n"
        ),
        ["writ-of-execution"] = (
            "أمر تنفيذ",
            "إنشاء أمر تنفيذ لتنفيذ الحكم.",
            "أمر تنفيذ\n\nالمحكمة: {{CourtName}}\nرقم القضية: {{CaseCode}}\nنوع القضية: {{CaseType}}\n\nدائن الحكم: {{CustomerName}}\nمدين الحكم: ____________________\nالتاريخ: {{Today}}\n\nإلى المحكم أو الضابط المخول:\n\nحيث صدر حكم في القضية أعلاه بتاريخ ____________ لصالح {{CustomerName}} بمبلغ:\n\n{{FeeTerms}}\n\nلذلك، تؤمرون بتنفيذ هذا الأمر بالحجز على أموال مدينة الحكم، بما في ذلك على سبيل المثال لا الحصر:\n\n{{Scope}}\n\n{{Statement}}\n\nتؤمرون أيضًا بإعادة هذا الأمر خلال المدة المحددة بموجب القانون.\n\nصدر تحت ختم هذه المحكمة في {{Today}}.\n\nكاتب المحكمة: ____________________\n\nبواسطة: ____________________\nنائب الكاتب\n"
        )
    };

    private static Dictionary<string, (string Name, string Description, string Body)> GetTemplates(string? culture)
    {
        var normalizedCulture = culture?.ToLowerInvariant() ?? "en";
        
        // Check for Arabic variants
        if (normalizedCulture.StartsWith("ar"))
        {
            return TemplatesAr;
        }
        
        return TemplatesEn;
    }

    public static IEnumerable<(string Key, string Name, string Description)> ListTemplates(string? culture = null)
    {
        var templates = GetTemplates(culture);
        return templates.Select(kv => (kv.Key, kv.Value.Name, kv.Value.Description));
    }

    public static bool Exists(string templateType)
    {
        // Check in both templates since we don't know the culture at this point
        return TemplatesEn.ContainsKey(templateType) || TemplatesAr.ContainsKey(templateType);
    }

    public static string Render(string templateType, IDictionary<string, string> variables, string? culture = null)
    {
        var templates = GetTemplates(culture);
        
        if (!templates.TryGetValue(templateType, out var templateData))
        {
            // Fallback to English if template not found
            templateData = TemplatesEn[templateType];
        }
        
        var template = templateData.Body;
        foreach (var kv in variables)
        {
            template = template.Replace($"{{{{{kv.Key}}}}}", kv.Value ?? string.Empty, StringComparison.OrdinalIgnoreCase);
        }

        return template;
    }

    public static byte[] BuildOutput(string content, string format)
    {
        var formatLower = format.ToLowerInvariant();
        
        return formatLower switch
        {
            "pdf" => ReportExportBuilder.BuildSimplePdf("Generated Legal Document", content.Split('\n')),
            "docx" => BuildDocx(content),
            _ => Encoding.UTF8.GetBytes(content)
        };
    }

    public static string GetContentType(string format)
    {
        var formatLower = format.ToLowerInvariant();
        
        return formatLower switch
        {
            "pdf" => "application/pdf",
            "docx" => "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            _ => "text/plain"
        };
    }

    public static string GetFileExtension(string format)
    {
        var formatLower = format.ToLowerInvariant();
        
        return formatLower switch
        {
            "pdf" => "pdf",
            "docx" => "docx",
            _ => "txt"
        };
    }

    private static byte[] BuildDocx(string content)
    {
        using var memoryStream = new MemoryStream();
        using (var wordDocument = WordprocessingDocument.Create(memoryStream, WordprocessingDocumentType.Document, true))
        {
            // Add main document part
            var mainPart = wordDocument.AddMainDocumentPart();
            mainPart.Document = new Document();
            var body = mainPart.Document.AppendChild(new Body());

            // Split content by lines and add paragraphs
            var lines = content.Split('\n');
            foreach (var line in lines)
            {
                var paragraph = body.AppendChild(new Paragraph());
                var run = paragraph.AppendChild(new Run());
                
                // Check if this is a heading (all caps or ends with colon)
                var trimmedLine = line.Trim();
                if (!string.IsNullOrEmpty(trimmedLine))
                {
                    var isHeading = trimmedLine.Length > 0 && 
                                   (trimmedLine == trimmedLine.ToUpper() || trimmedLine.EndsWith(':'));
                    
                    if (isHeading && trimmedLine.Length < 100)
                    {
                        var runProperties = run.AppendChild(new RunProperties());
                        runProperties.AppendChild(new Bold());
                        runProperties.AppendChild(new FontSize { Val = "28" }); // 14pt
                    }
                    
                    run.AppendChild(new Text(line));
                }
                else
                {
                    // Empty line for spacing
                    run.AppendChild(new Text(string.Empty));
                }
            }

            mainPart.Document.Save();
        }

        return memoryStream.ToArray();
    }
}
