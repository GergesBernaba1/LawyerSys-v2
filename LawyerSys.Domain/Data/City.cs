public class City
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string NameAr { get; set; } = string.Empty;
    public int CountryId { get; set; }
    public int? TenantId { get; set; }
    public string? CreatedByUserId { get; set; }

    public Country? Country { get; set; }
    public Tenant? Tenant { get; set; }
}
