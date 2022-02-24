export exportImage, exportMovie, exportMovies

exportImage(filename, im::ImageMeta; kargs...) = exportImage(filename, arraydata(im); kargs...)

#old syntax
function exportImage(filename, im::AbstractMatrix{T}; 
                    colormap::Union{Array, String}="grays", kargs...) where {T<:Real}
  exportImage(filename, im, colormap; kargs...)
end

function exportImage(filename, im::AbstractMatrix{T}, colorm::String;kargs...) where {T<:Real}
  return exportImage(filename, im, cmap(colorm); kargs...)
end

"""
    exportImage(filename, im, colorm; vmin, vmax, normalize, pixelResizeFactor)

Exports image-data (twodimensional Colorant Array) `im` as `filename` (path) colored with the colormap `colorm` (default: grays).

Colormaps can be given directly as a Vector of Colorants.
Alternatively a colormap from ColorSchemes (with added alpha gradient from 0 to 1) can be used by giving a String with the name of the colormap.
All existing colormaps can be found using `existing_cmaps()`.
Frequently used colormaps can be found using `important_cmaps()`.
Colormaps with customized alpha gradients can be build using `RGBAGradient()`.

Further keyword arguments:
- `vmin` and `vmax` (default: 0.0 and 1.0): floating numbers, left and right limits for coloring
- `normalize` (default: true): boolean, normalize data to [0,1] if true
- `pixelResizeFactor` (default: 1): integer number, amount of multiple pixels plotted for each datapoint

"""
function exportImage(filename, im::AbstractMatrix{T}, colorm::Vector{C}; vmin=0.0, vmax=1.0,
                    normalize=true, pixelResizeFactor=1) where {T<:Real, C<:Colorant}
  imC = colorize( im, vmin, vmax, colorm, normalize=normalize )
  exportImage(filename, imC; pixelResizeFactor=pixelResizeFactor)
end

function exportImage(filename, im::AbstractMatrix{T}; pixelResizeFactor=1) where {T<:Colorant}
  file, ext = splitext(filename)

  imR = repeat(im, inner=[pixelResizeFactor,pixelResizeFactor])

  minPxSpacing = minimum(pixelspacing(im))
  newSize = ceil.(Int64, collect(pixelspacing(im)) / minPxSpacing .* collect(size(imR)) )

  dataResized = Images.imresize(imR,(newSize[1],newSize[2]))
  rgbdata = RGB.(dataResized)
  ImageMagick.save(filename, rgbdata)
end

function exportImage(filename, data::Vector{T}; kargs...) where {T<:AbstractMatrix}
    file, ext = splitext(filename)
    exportImage(file*"_xy.png", data[1]; kargs...)
    exportImage(file*"_xz.png", data[2]; kargs...)
    exportImage(file*"_yz.png", data[3]; kargs...)
end

### export movies ###

exportMovie(filename, data::ImageMeta; kargs...) = exportMovie(filename, data.data; kargs...)

#old syntax
function exportMovie(filename, data::AbstractArray{T,3};
                    colormap::Union{Array, String}="grays", kargs...) where {T<:Real}
  exportMovie(filename, data, colormap; kargs...)
end

function exportMovie(filename, data::AbstractArray{T,3}, colorm::String; kargs...) where {T<:Real}
  return exportMovie(filename, data, cmap(colorm); kargs...)
end

"""
    exportMovie(filename, data, colorm; vmin, vmax, normalize, pixelResizeFactor)

Exports video-data (threedimensional Colorant Array) `data` as `filename` (path) colored with the colormap `colorm` (default: grays).

Colormaps can be given directly as a Vector of Colorants.
Alternatively a colormap from ColorSchemes (with added alpha gradient from 0 to 1) can be used by giving a String with the name of the colormap.
All existing colormaps can be found using `existing_cmaps()`.
Frequently used colormaps can be found using `important_cmaps()`.
Colormaps with customized alpha gradients can be build using `RGBAGradient()`.

Further keyword arguments:
- `vmin` and `vmax` (default: 0.0 and 1.0): floating numbers, left and right limits for coloring
- `normalize` (default: true): boolean, normalize data to [0,1] if true
- `pixelResizeFactor` (default: 1): integer number, amount of multiple pixels plotted for each datapoint

"""
function exportMovie(filename, data::AbstractArray{T,3}, colorm::Vector{C}; vmin=0.0, vmax=1.0,
                    normalize=true, pixelResizeFactor=1) where {T<:Real, C<:Colorant}
    imC = colorize( data, vmin, vmax, colorm, normalize=normalize )
    exportMovie(filename, imC; pixelResizeFactor=pixelResizeFactor)
end

function exportMovie(filename, data::AbstractArray{T,3}; pixelResizeFactor=1) where {T<:Colorant}
  file, ext = splitext(filename)

  if pixelResizeFactor > 1
    data = repeat(data, inner=[pixelResizeFactor,pixelResizeFactor,1])
  end

  minPxSpacing = minimum(pixelspacing(data))
  newSize = ceil.(Int64, collect(pixelspacing(data)[1:2]) / minPxSpacing .* collect(size(data)[1:2]) )

  datai = similar(data, (newSize[1],newSize[2],size(data,3)))

  for l=1:size(data,3)
    datai[:,:,l] = Images.imresize(data[:,:,l],(newSize[1],newSize[2]))
  end

  rgbdata = RGB.(datai)
  @debug "saving $filename"
  ImageMagick.save(file*".gif", rgbdata)
end


function exportMovies(filename, data::Vector; kargs...)
  file, ext = splitext(filename)

  exportMovie(file*"_xy.gif", data[1]; kargs...)
  exportMovie(file*"_xz.gif", data[2]; kargs...)
  exportMovie(file*"_yz.gif", data[3]; kargs...)
end
