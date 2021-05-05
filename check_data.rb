#!/usr/bin/env ruby
# frozen_string_literal: true

require "yaml"
require "relaton_iso_bib"

def compare(src, dest) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
  if src.is_a? Array
    result = src.map.with_index { |s, i| compare s, array(dest)[i] }
    compact result
  elsif src.is_a? String
    src != dest && "- #{src}\n+ #{dest}"
  elsif src.is_a? Hash
    result = src.map do |k, v|
      if v.is_a?(String) then message(k, v, dest)
      else
        res = compare v, dest[k]
        { k => res } if res&.any?
      end
    end
    compact result
  end
end

def message(key, val, dest)
  return unless !dest || dest[key] != val

  msg = "- #{key}: #{val}"
  msg += "\n+ #{key}: #{dest[key]}" if dest && dest[key]
  msg
end

def compact(arr)
  result = arr.select { |v| v }
  return unless result.any?

  result
end

def array(arg)
  arg.is_a?(Array) ? arg : [arg]
end

def print_msg(messages) # rubocop:disable Metrics/MethodLength,Metrics/PerceivedComplexity
  if messages.is_a? Hash
    messages.each do |k, v|
      puts k + ":"
      if v.is_a?(String)
        puts "  #{v}"
      else
        print_msg v
      end
    end
  else
    messages.each do |msg|
      if msg.is_a? String
        puts msg
      else print_msg msg
      end
    end
  end
end

path = ARGV.first || "data/*.{yaml,yml}"

errors = false
Dir[path].each do |f|
  begin
    yaml = YAML.load_file(f)
    hash = RelatonIsoBib::HashConverter.hash_to_bib yaml
    item = RelatonIsoBib::IsoBibliographicItem.new hash
    if (messages = compare(yaml, item.to_hash))&.any?
      errors = true
      puts "Parsing #{f} failed. Parsed content doesn't match to source."
      print_msg messages
      puts
    end
  rescue ArgumentError, NoMethodError, TypeError => e
    errors = true
    puts "Parsing #{f} failed. Error: #{e.message}."
    puts e.backtrace
    puts
  end
end

exit(1) if errors
