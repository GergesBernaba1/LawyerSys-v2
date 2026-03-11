using System.Collections.Generic;

public class Country
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string NameAr { get; set; } = string.Empty;

    public ICollection<City> Cities { get; set; } = new List<City>();
    public ICollection<Tenant> Tenants { get; set; } = new List<Tenant>();
    public ICollection<ApplicationUser> Users { get; set; } = new List<ApplicationUser>();
}
