using System;
using System.Collections.Generic;

namespace LawyerSys.Data.ScaffoldedModels;

public partial class Customer
{
    public int Id { get; set; }

    public int Users_Id { get; set; }

    public virtual ICollection<Billing_Pay> Billing_Pays { get; set; } = new List<Billing_Pay>();

    public virtual ICollection<Billing_Receipt> Billing_Receipts { get; set; } = new List<Billing_Receipt>();

    public virtual ICollection<Consltitions_Custmor> Consltitions_Custmors { get; set; } = new List<Consltitions_Custmor>();

    public virtual ICollection<Custmors_Case> Custmors_Cases { get; set; } = new List<Custmors_Case>();

    public virtual ICollection<Judicial_Document> Judicial_Documents { get; set; } = new List<Judicial_Document>();

    public virtual User Users { get; set; } = null!;
}
