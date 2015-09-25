#!/usr/bin/env ruby

require 'fileutils'

module OS
  def OS.windows?
    (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
  end

  def OS.mac?
   (/darwin/ =~ RUBY_PLATFORM) != nil
  end

  def OS.unix?
    !OS.windows?
  end

  def OS.linux?
    OS.unix? and not OS.mac?
  end
end

class ExtractFocal

  def initialize(inpDir, outDir)
    @inDir = inpDir
    @opDir = outDir
    @binDir = File.expand_path File.dirname(__FILE__)
  end

  def generate_list
    setExifTool
    getImageList
    writeFile
  end

  private
  def setExifTool
    @exifTool = "/usr/local/bin/exiftool"
    if OS.windows?
      @exifTool = File.join(binPath, "exiftool.exe")
    end
  end

  def getImageList
    vidDir = File.expand_path('..', @inDir)
    video = Dir.glob(vidDir + "/*.{MOV,MPG,AVI}")[0]
    a = %x(#{ @exifTool } #{ video })
    a = Hash[a.split("\n").map{ |x| x.split(/\s*: /) }]
    @cameraModel = {:make => a['Make'],
                    :model => a['Model'],
                    :ccd_width => getCCDWidth(a['Make'], a['Model']),
                    :focalLength => getFocalLength(a['Make'], a['Model'])
    }
    @imgList = []

    allfiles = Dir.glob(@inDir + "/*.jpg")
    allfiles.each do |f|
      metadata = %x(#{ @exifTool } #{ f })
      metadata = Hash[metadata.split("\n").map{|x| x.split(/\s*: /) }]
      width = metadata['Image Width'].to_f
      focalPixels = width * (@cameraModel[:focalLength]*1.0 / @cameraModel[:ccd_width])
      @imgList << "#{ f } 0 #{ focalPixels }"
    end
  end

  # returns focal length in standard mm
  def getFocalLength(make, model)
    # todo : use a file with configs to get this
    return 3.5
  end

  def getCCDWidth(make, model)
    # todo : use a file with configs to get this
    return 6.15
  end

  def writeFile
    unless File.directory?(@opDir)
      FileUtils.mkdir_p(@opDir)
    end
    File.open(File.join(@opDir,"list.txt"), "w+") do |f|
      f.puts(@imgList)
    end
  end

end

def main(argv)
  inpDir = argv[0]
  outDir = argv[1]
  puts "Using image directory: #{ inpDir} and output directory: #{ outDir }"
  f = ExtractFocal.new(inpDir, outDir)
  f.generate_list
end

if __FILE__ == $0
  if ARGV.length < 2
    puts "Usage #{ $0 } inpDir outDir "
    exit
  end
  main(ARGV)
end
