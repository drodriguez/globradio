#
#  update_build_number.rb
#  radio3
#
#  Created by Daniel Rodríguez Troitiño on 16/12/08.
#  Copyright (c) 2008 Daniel Rodríguez and Javier Quevedo. All rights reserved.
#
require 'osx/cocoa'

class InvalidRepository < Exception; end

class GitInfo
  def initialize(path)
    unless File.exist?(File.join(path, '.git'))
      raise InvalidRepository.new(path)
    end
    @path = File.join(path, '.git')
  end
  
  def build_number
    result = `git --git-dir=#{@path} svn info`
    if $?.success?
      result = result.split("\n").inject({}) do |memo, item|
        pair = item.split(':', 2)
        memo[pair.first] = pair.last.strip
        memo
      end
      
      result = result["Revision"]
      return nil if result.nil?
      begin
        Integer(result)
      rescue ArgumentError => e
        result = result[0..-2]
        if result.length > 0
          retry
        else
          nil
        end
      end
    else
      nil
    end
  end
end

class SVNInfo
  def initialize(path)
    unless File.exist?(File.join(path, '.svn'))
      raise InvalidRepository.new(path)
    end
    @path = path
  end
  
  def build_number
    result = `svnversion #{@path}`
    if $?.success?
      result = result.split(':').last
      begin
        Integer(result)
      rescue ArgumentError => e
        result = result[0..-2]
        if result.length > 0
          retry
        else
          nil
        end
      end
    else
      nil
    end
  end
end

def main
  begin
    info = SVNInfo.new(ARGV[0])
  rescue InvalidRepository => e
    begin
      info = GitInfo.new(ARGV[0])
    rescue InvalidRepository => e
      return
    end
  end
  
  build_number = info.build_number
  
  plist = OSX::NSMutableDictionary.dictionaryWithContentsOfFile_(ARGV[1])
  main_version = plist['CFBundleVersion'].split('.')[0..-2]
  plist['CFBundleVersion'] = (main_version << build_number).join('.')
  plist.writeToFile_atomically_(ARGV[1], true)
end

if __FILE__ == $0
  main
end
