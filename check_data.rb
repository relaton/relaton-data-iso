#!/usr/bin/env ruby
# frozen_string_literal: true

require "yaml"
require "relaton_iso_bib"

def fix_doctype(hash)
  if hash["doctype"].is_a? String
    hash["doctype"] = { "type" => hash["doctype"] }
  end
end

#
# Compare elements of source and destination
#
# @param [Array, String, Hash] src source element
# @param [Array, String, Hash] dest destination element
#
# @return [Array<Hash, Array, String, false>, false] not equal elements
#
def compare(src, dest) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  if !src.is_a?(dest.class) && !(dest.is_a?(Array) || src.is_a?(Array)) &&
      !((dest.is_a?(Hash) && dest["content"]) || (src.is_a?(Hash) && src["content"]))
    return ["- #{src.to_s[0..70]}#{src.to_s.size > 70 ? '...' : ''}",
            "+ #{dest.to_s[0..70]}#{dest.to_s.size > 70 ? '...' : ''}"]
  elsif dest.is_a?(Array)
    return compare src, dest.first
  elsif src.is_a?(Array)
    return compare src.first, dest
  elsif dest.is_a?(Hash) && dest["content"] && src.is_a?(String)
    return compare src, dest["content"]
  elsif src.is_a?(Hash) && src["content"] && dest.is_a?(String)
    return compare src["content"], dest
  end
  case src
  when Array
    result = src.map.with_index { |s, i| compare s, array(dest)[i] }
    compact result
  when String
    src != dest && ["- #{src}", "+ #{dest}"]
  when Hash
    result = src.map do |k, v|
      res = compare v, dest[k]
      { k => res } if res && !res.empty?
    end
    compact result
  end
end

#
# Remove falsey values from array
#
# @param [Array<Hash, Array, String, false>] arr error messages
#
# @return [Array<Hash, Array, String>] error messages without falsey values
#
def compact(arr)
  result = arr.select { |v| v }
  return unless result.any?

  result
end

def array(arg)
  arg.is_a?(Array) ? arg : [arg]
end

#
# Prints diff between source and destination
#
# @param [Hash, Array] messages diff messages
# @param [String] indent indentation
#
# @return [<Type>] <description>
#
def print_msg(messages, indent = '') # rubocop:disable Metrics/MethodLength, Metrics/PerceivedComplexity
  if messages.is_a? Hash
    messages.each do |k, v|
      puts "#{indent}#{k}:"
      if v.is_a?(String)
        puts "#{indent}  #{v}"
      else
        print_msg v, "#{indent}  "
      end
    end
  else
    messages.each do |msg|
      if msg.is_a? String
        puts "#{indent}#{msg}"
      else
        print_msg msg, indent
      end
    end
  end
end

path = ARGV.first || "static/*.{yaml,yml}"

errors = false
Dir[path].each do |f|
  yaml = YAML.load_file(f)
  fix_doctype yaml
  hash = RelatonIsoBib::HashConverter.hash_to_bib yaml
  item = RelatonIsoBib::IsoBibliographicItem.new(**hash)
  if (messages = compare(yaml, item.to_hash))&.any?
    errors = true
    puts "Parsing #{f} failed. Parsed content doesn't match to source."
    print_msg messages
    puts
  end
  primary_id = item.docidentifier.detect(&:primary)
  unless primary_id
    errors = true
    puts "Parsing #{f} failed. No primary id."
  end
rescue ArgumentError, NoMethodError, TypeError => e
  errors = true
  puts "Parsing #{f} failed. Error: #{e.message}."
  puts e.backtrace
  puts
end

exit(1) if errors
