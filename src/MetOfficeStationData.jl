module MetOfficeStationData

using Cascadia: @sel_str
using CSV: CSV
using DataFrames: DataFrame, Not, select!
using Downloads: download
using Gumbo: Gumbo
using Gumbo: parsehtml
using Mocking

function _data_url(short_name::AbstractString)
    return "https://www.metoffice.gov.uk/pub/data/weather/uk/climate/stationdata/$(short_name)data.txt"
end

"""Download the file for `short_name` to an in-memory buffer."""
function _download_as_string(short_name::AbstractString)
    return String(take!(download(_data_url(short_name), IOBuffer())))
end

function get_frame(short_name::AbstractString)
    csv_str = (@mock _download_as_string(short_name))

    # Skip the prelude, and jump to where the data starts. 
    # TODO: We then remove known "annotations" that means we can parse the data smoothly.
    #   Potentially it would be desirable to maintain these annotations somehow.
    i_start = first(findfirst(r"\s+yyyy", csv_str))
    cleaned_csv_str = replace(
        csv_str[i_start:end],
        r"\s+Provisional" => "",
        "*" => "",
        "#" => "",
        "\$" => "",
        "|" => "",  # This appears in `nairndata.txt`... no explanation given.
        r"all\s+data\s+from\s+[\S\s]+" => "",
        r"Change\s+to[\S\s]+" => "",
    )

    # TODO: parse some of the header information.
    # NOTE: we cannot use threaded parsing here, since splitting the file into chunks results in us
    #   failing to find the correct number of columns sometimes.
    # HACK: silencing warnings is a bit disgusting. The problem is that some stations, e.g. aberporth,
    #   don't have any 'sun' data, so there is a whole missing column, even though the header is present.
    #   CSV.jl doesn't see a delimeter after the value for the penultimate column, and hence complains.
    return CSV.read(
        IOBuffer(cleaned_csv_str),
        DataFrame;
        header=[1],  # Skip the units... if we try to parse them it goes wrong.
        skipto=3,
        delim=' ',
        ignorerepeated=true,
        missingstring="---",
        ntasks=1,
        silencewarnings=true,
    )
end

_get_value(x::Gumbo.HTMLText) = x.text
_get_value(x::Gumbo.HTMLElement{:a}) = x.attributes["href"]
_get_value(x::Gumbo.HTMLElement{:th}) = _get_value(only(x.children))
_get_value(x::Gumbo.HTMLElement{:td}) = _get_value(only(x.children))

"""
    get_station_metadata() -> DataFrame

Get all known stations along with metadata as a DataFrame.
"""
function get_station_metadata()
    doc = parsehtml(
        String(
            take!(
                download(
                    "https://www.metoffice.gov.uk/research/climate/maps-and-data/historic-station-data",
                    IOBuffer(),
                ),
            ),
        ),
    )

    table = only(eachmatch(sel"table", doc.root))
    return DataFrame(
        map(eachmatch(sel"tbody tr", table)) do row
            name, lon_lat, year_str, url = map(_get_value, eachmatch(sel"td", row))
            year_start = parse(Int, year_str)
            lon, lat = map(split(lon_lat, ", ")) do x
                parse(Float64, x)
            end

            short_name = only(
                match(
                    r"https://www\.metoffice\.gov\.uk/pub/data/weather/uk/climate/stationdata/([a-z]+)data\.txt",
                    url,
                ),
            )

            (; name, lat, lon, year_start, short_name)
        end,
    )
end

end
