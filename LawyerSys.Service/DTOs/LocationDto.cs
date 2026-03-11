namespace LawyerSys.DTOs;

public class LocationCatalogCountryDto
{
    public int Id { get; set; }
    public string NameEn { get; set; } = string.Empty;
    public string NameAr { get; set; } = string.Empty;
    public int CityCount { get; set; }
    public IReadOnlyList<LocationCatalogCityDto> Cities { get; set; } = Array.Empty<LocationCatalogCityDto>();
}

public class LocationCatalogCityDto
{
    public int Id { get; set; }
    public int CountryId { get; set; }
    public string NameEn { get; set; } = string.Empty;
    public string NameAr { get; set; } = string.Empty;
}

public class UpdateLocationCityDto
{
    public int CountryId { get; set; }
    public string NameEn { get; set; } = string.Empty;
    public string NameAr { get; set; } = string.Empty;
}
