#!/usr/bin/env ruby
# frozen_string_literal: true

# Check that each file parses with the v2 relaton-iso model: load it, write it
# back to YAML, and compare the two. A difference means the model drops or
# changes data. Usage: check_data.rb [glob] (default: the static files).

require "yaml"
require "relaton/iso"

#
# Compare elements of source and destination
#
# @param [Array, Hash, Object] src source element
# @param [Array, Hash, Object] dest destination element
# @param [String] path location of the elements in the document
#
# @return [Array<Hash, Array, String>, false, nil] not equal elements
#
def compare(src, dest, path = "") # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  if src == dest
    return
  elsif dest.nil?
    return ["- #{short(src)} (at #{path})", "+ nil (at #{path})"]
  elsif src.is_a?(Array) != dest.is_a?(Array)
    return compare(src.first, dest, path) if src.is_a?(Array)

    return compare(src, dest.first, path)
  elsif src.is_a?(String) && dest.is_a?(Hash) && dest.key?("content")
    # The model writes a plain string as `content: <string>`.
    return compare src, dest["content"], path
  elsif src.is_a?(Hash) != dest.is_a?(Hash)
    return ["- #{short(src)} (at #{path})", "+ #{short(dest)} (at #{path})"]
  end

  case src
  when Array
    compact(src.map.with_index { |s, i| compare s, dest[i], "#{path}[#{i}]" })
  when Hash
    result = src.map do |k, v|
      res = compare v, dest[k], path.empty? ? k.to_s : "#{path}.#{k}"
      { k => res } if res && !res.empty?
    end
    compact result
  else
    src.to_s != dest.to_s && ["- #{src} (at #{path})", "+ #{dest} (at #{path})"]
  end
end

def short(obj)
  str = obj.to_s
  str.size > 70 ? "#{str[0..70]}..." : str
end

#
# Remove falsey values from array
#
# @param [Array<Hash, Array, String, false, nil>] arr error messages
#
# @return [Array<Hash, Array, String>, nil] error messages without falsey values
#
def compact(arr)
  result = arr.select { |v| v }
  return unless result.any?

  result
end

#
# Prints diff between source and destination
#
# @param [Hash, Array] messages diff messages
# @param [String] indent indentation
#
def print_msg(messages, indent = "")
  if messages.is_a? Hash
    messages.each do |k, v|
      puts "#{indent}#{k}:"
      v.is_a?(String) ? puts("#{indent}  #{v}") : print_msg(v, "#{indent}  ")
    end
  else
    messages.each do |msg|
      msg.is_a?(String) ? puts("#{indent}#{msg}") : print_msg(msg, indent)
    end
  end
end

#
# Remove the differences that come from a newer gem, not from a parse error
#
# @param [Hash] src source hash
# @param [Hash] dest destination hash
#
def normalize!(src, dest)
  [src, dest, src["ext"], dest["ext"]].each do |h|
    h.delete "schema_version" if h.is_a?(Hash)
  end
end

path = ARGV.first || "static/*.{yaml,yml}"

files = Dir[path]
abort "No files match #{path}" if files.empty?

errors = false
files.each do |f|
  yaml = File.read(f, encoding: "UTF-8")
  src = YAML.safe_load yaml, permitted_classes: [Date]
  item = Relaton::Iso::Item.from_yaml yaml
  dest = YAML.safe_load Relaton::Iso::Item.to_yaml(item),
                        permitted_classes: [Date]
  normalize! src, dest
  if (messages = compare(src, dest))&.any?
    errors = true
    puts "Parsing #{f} failed. Parsed content doesn't match to source."
    print_msg messages
    puts
  end
  unless item.docidentifier.detect(&:primary)
    errors = true
    puts "Parsing #{f} failed. No primary id."
  end
rescue StandardError => e
  errors = true
  puts "Parsing #{f} failed. Error: #{e.message}."
  puts e.backtrace
  puts
end

exit(1) if errors
