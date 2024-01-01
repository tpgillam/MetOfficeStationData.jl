module MetOfficeStationData

using Cascadia: @sel_str
using CSV: CSV
using DataFrames: DataFrame, Not, select!
using Downloads: download
using Gumbo: Gumbo
using Gumbo: parsehtml

function _data_url(short_name::AbstractString)
    return "https://www.metoffice.gov.uk/pub/data/weather/uk/climate/stationdata/$(short_name)data.txt"
end

_parse_value(::Missing) = missing
_parse_value(x::Number) = x
_parse_value(x::AbstractString) = parse(Float64, replace(x, "*" => ""))

function get_frame(short_name::AbstractString)
    # Download the file to an in-memory buffer, and seek back to the start so
    # that we can read from the buffer.
    buf = download(_data_url(short_name), IOBuffer())
    seekstart(buf)

    for l in readlines(buf)
        println(l)
    end
    return

    # PERF: We could improve the parsing performance below, and remove some of the hacks, by
    #   eliminating some of the undesired characters from the bytestream before they are read
    #   by CSV.

    # TODO: parse some of the header information.
    # NOTE: we cannot use threaded parsing here, since splitting the file into chunks results in us
    #   failing to find the correct number of columns sometimes.
    # FIXME: these values work for "cambridge", but fail for "whitby" due to different formatting.
    frame = CSV.read(
        buf, DataFrame; header=[6], skipto=8, delim=' ', ignorerepeated=true, threaded=false
    )

    # '---' is used in the data file to mean 'missing'.
    frame = ifelse.(isequal.(frame, "---"), missing, frame)

    println(frame)
    # Drop the last column, which is mostly missing but has "Provisional" for the most recent
    # few readings.
    select!(frame, Not([:Column8]))

    return _parse_value.(frame)
end

_get_value(x::Gumbo.HTMLText) = x.text
_get_value(x::Gumbo.HTMLElement{:a}) = x.attributes["href"]
_get_value(x::Gumbo.HTMLElement{:th}) = _get_value(only(x.children))
_get_value(x::Gumbo.HTMLElement{:td}) = _get_value(only(x.children))

"""
    get_stations()

Get a list of the known stations.
"""
function get_stations()
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
    return DataFrame(map(eachmatch(sel"tbody tr", table)) do row
        name, lon_lat, year_str, url = map(_get_value, eachmatch(sel"td", row))
        year_start = parse(Int, year_str)
        lon, lat = split(lon_lat, ", ")

        short_name = only(
            match(
                r"https://www\.metoffice\.gov\.uk/pub/data/weather/uk/climate/stationdata/([a-z]+)data\.txt",
                url,
            ),
        )

        (; name, lat, lon, year_start, short_name)
    end)
end

end
