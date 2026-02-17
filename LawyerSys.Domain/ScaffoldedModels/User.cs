using System;
using System.Collections.Generic;

namespace LawyerSys.Data.ScaffoldedModels;

public partial class User
{
    public int Id { get; set; }

    public string Full_Name { get; set; } = null!;

    public string? Address { get; set; }

    public string Job { get; set; } = null!;

    public int Phon_Number { get; set; }

    public DateOnly Date_Of_Birth { get; set; }

    public int SSN { get; set; }

    public string User_Name { get; set; } = null!;

    public string Password { get; set; } = null!;

    public virtual ICollection<App_Sitting> App_Sittings { get; set; } = new List<App_Sitting>();

    public virtual ICollection<Customer> Customers { get; set; } = new List<Customer>();

    public virtual ICollection<Employee> Employees { get; set; } = new List<Employee>();
}
