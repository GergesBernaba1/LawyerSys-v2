using System;
using System.Collections.Generic;

namespace LawyerSys.Data.ScaffoldedModels;

public partial class Employee
{
    public int id { get; set; }

    public int Salary { get; set; }

    public int Users_Id { get; set; }

    public virtual ICollection<AdminstrativeTask> AdminstrativeTasks { get; set; } = new List<AdminstrativeTask>();

    public virtual ICollection<Cases_Employee> Cases_Employees { get; set; } = new List<Cases_Employee>();

    public virtual ICollection<Consulations_Employee> Consulations_Employees { get; set; } = new List<Consulations_Employee>();

    public virtual User Users { get; set; } = null!;
}
