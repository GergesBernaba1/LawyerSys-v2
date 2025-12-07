using System;
using System.Collections.Generic;

namespace LawyerSys.Data.ScaffoldedModels;

public partial class App_Page
{
    public int Id { get; set; }

    public string Page_Name { get; set; } = null!;

    public virtual ICollection<App_Sitting> App_Sittings { get; set; } = new List<App_Sitting>();
}
