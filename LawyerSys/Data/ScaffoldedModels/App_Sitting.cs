using System;
using System.Collections.Generic;

namespace LawyerSys.Data.ScaffoldedModels;

public partial class App_Sitting
{
    public int Id { get; set; }

    public int User_Id { get; set; }

    public int App_PageID { get; set; }

    public bool? IsVaild { get; set; }

    public virtual App_Page App_Page { get; set; } = null!;

    public virtual User User { get; set; } = null!;
}
