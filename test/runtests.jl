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
    @testset "aqua" begin
        Aqua.test_all(MetOfficeStationData; ambiguities=false)
        Aqua.test_ambiguities(MetOfficeStationData)
    end

    patch = @patch MetOfficeStationData._download_as_string(short_name::AbstractString) =
        _mock_download(short_name)
    apply(patch) do
        for short_name in
            ("aberporth", "cambridge", "lowestoft", "nairn", "ringway", "whitby")
            @testset "check $short_name" begin
                df = MetOfficeStationData.get_frame(short_name)
                @test isa(df, DataFrame)
                @test ncol(df) == 7
                @test names(df) == ["yyyy", "mm", "tmax", "tmin", "af", "rain", "sun"]
                @test eltype(df[!, :yyyy]) == Int64
                @test eltype(df[!, :mm]) == Int64
                @test eltype(df[!, :tmax]) <: Union{Float64,Missing}
                @test eltype(df[!, :tmin]) <: Union{Float64,Missing}
                @test eltype(df[!, :af]) <: Union{Int64,Missing}
                @test eltype(df[!, :rain]) <: Union{Float64,Missing}
                @test eltype(df[!, :sun]) <: Union{Float64,Missing}
            end
        end
    end
end
