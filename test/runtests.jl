using Aqua
using DataFrames
using MetOfficeStationData
using Mocking
using Test

Mocking.activate()

function _mock_download(short_name::AbstractString)
    return String(
        open(read, joinpath(dirname(@__FILE__), "reference", "$(short_name)data.txt"))
    )
end

@testset "MetOfficeStationData.jl" begin
    Aqua.test_all(MetOfficeStationData; ambiguities=false)
    Aqua.test_ambiguities(MetOfficeStationData)

    patch = @patch MetOfficeStationData._download_as_string(short_name::AbstractString) =
        _mock_download(short_name)
    apply(patch) do
        for short_name in ("aberporth", "cambridge", "lowestoft", "nairn", "whitby")
            df = MetOfficeStationData.get_frame(short_name)
            @test isa(df, DataFrame)
            @test ncol(df) == 7
            @test names(df) == ["yyyy", "mm", "tmax", "tmin", "af", "rain", "sun"]
        end
    end
end
