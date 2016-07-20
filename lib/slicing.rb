require "slicing/version"
require 'digest/md5'
require 'thor'
require 'csv'

module Slicing
  class Base < Thor
    check_unknown_options!
    package_name 'slicing'
    default_task :help

    # desc :gsub, ""
    # def gsub path, output, first, second
    #   CSV.foreach(path,:headers=> true, :encoding => "ISO8859-1:utf-8") do |row|
    #     puts row
    #     row.map {|n| n.gsub(first,second) if n !=nil}
    #     CSV.open(output, "a+") do |csv|
    #       csv << row
    #     end
    #   end
    #
    # end
    #
    # desc :trim, "clean up by removing rows with column value"
    # def trim path, output#, name, value
    #   CSV.foreach(path) do |row|
    #     row.map {|n| n.strip! || n}
    #     CSV.open(output, "a+") do |csv|
    #       csv << row
    #     end
    #   end
    # end

    desc :clean, "clean up by removing rows with column value"
    def clean path, output, name, value
      # puts "add header"
    end

    desc :add, "add a header"
    def add path, output, *headers
      index = 0
      CSV.foreach(path) do |row|
        CSV.open(output, "a+") do |csv|
          if index == 0
            csv << headers
          end
          csv << row
        end
        index = index +1
      end
    end

    desc :show, "show a specific row"
    def show path, output, start
      index = 1
      CSV.foreach(path) do |csv|
        if index == start.to_i
          puts csv
          break
        end
        index = index + 1
      end
    end

    desc :list, "list unique items in a column"
    def list path, name
      file_csv = CSV.read(path,:headers=> true, :encoding => "ISO8859-1:utf-8")
      array = file_csv[name]
      puts array.uniq
      puts "--"
      puts "#{array.uniq.count} items"
    end

    desc :reduce, "reduce csv to smaller rows"
    def reduce path, output, start
      index = 0
      CSV.foreach(path) do |csv|
        CSV.open(output, "a+") do |row|
          if start.to_i > index #dangerous
            csv << row
          end
        end
        index = index +1
      end
    end

    desc :sample, "create a sample output"
    def sample path, output_path, size
      file_csv = CSV.read(path,:headers=> true, :encoding => "ISO8859-1:utf-8")
      sample = file_csv.sample(size)
      CSV.open(output_path, "a+") do |csv|
        sample.each do |value|
          csv << value
        end
      end
    end

    desc :freq, "calculate item frequencies"
    def freq path, column_name, output_path
      file_to_count = "./#{path}.csv"
      output = "./#{path}-counted.csv"
      file_to_count_csv = CSV.read(file_to_count,:headers=> true, :encoding => "ISO8859-1:utf-8")
      unique_nric_array = file_to_count_csv[column_name]
      unique_nric = []
      unique_nric_array.each_with_index do |value, index|
        unique_nric.push(value) if index !=0
      end

      final_hash = score(unique_nric)
      CSV.open(output, "a+") do |csv|
        final_hash.each do |value|
          csv << [value[0], value[1]]
        end
      end
    end

    desc :mask, "mask a particular column"
    def mask path, column_name, output_path
      original = CSV.read(path, { headers: true, return_headers: true, :encoding => "ISO8859-1:utf-8"})
      CSV.open(output_path, 'a+') do |csv|
        original.each do |row|
          csv << array
        end
      end
    end

    desc :retain, "retain only these column"
    def retain path, output, *names
      value = ""
      CSV.foreach(path) do |data|
        value = data
        break
      end

      array = []
      names.each do |each_name|
        if value.index(each_name) == nil
          puts "#{each_name} is not a column name."
          puts "--"
          puts value
          exit
        end
        array.push(value.index(each_name)) if value.index(each_name) != nil
      end
      # puts array.count
      answer =
      CSV.open(output,"a+") do |csv|
        CSV.foreach(path) do |row|
          answer = []
          array.each do |each|
            answer.push(row[each])
          end
          csv << answer
        end
      end

    end

    desc :rm, "remove a column"
    method_option :utf, type: :string, aliases: '-u', default: "ISO8859-1:utf-8"
    method_option :headers, type: :boolean, aliases: '-h', default: true
    method_option :rowsep, type: :string, aliases: '-r', default: nil
    def rm path, column_name, output
      # headers, rowsep, utf = process_options(options[:headers], options[:rowsep], options[:utf])
      if options[:rowsep] != nil
        original = CSV.read(path, { headers: options[:headers], return_headers: options[:headers], :row_sep=> options[:rowsep], :encoding => options[:utf]})
      else
        original = CSV.read(path, { headers: options[:headers], return_headers: options[:headers], :encoding => options[:utf]})
      end
      original.delete(column_name)
      CSV.open(output, 'a+') do |csv|
        original.each do |row|
          csv << row
        end
      end
    end

    desc :first, "display the first numbers of line"
    method_option :line, type: :numeric, aliases: '-l', default: 100
    def first csv_file #, value=100
      stop = options[:line]
      counter = 0
      CSV.foreach(csv_file, :headers => false, encoding: "ISO8859-1:utf-8") do |row|
        exit if counter == stop
        begin
          counter = counter + 1
          puts row
        rescue
        end
      end
    end

    desc :head, "show the headers"
    def head csv_file
      CSV.foreach(csv_file, :headers => false, encoding: "ISO8859-1:utf-8") do |row|
        puts row
        puts "----"
        puts "#{row.count} columns"
        puts "----"
        print_header(row)
        exit
      end
    end

    desc :unique, "calculate number of unique values in column"
    def unique path, column_name
      data = CSV.read(path, :headers => true, return_headers: true, encoding: "ISO8859-1:utf-8")
      array = data[column_name]
      puts array.uniq.count if array != nil
    end


    desc :count, "count the number of rows and columns"
    def count csv_file
      data = CSV.read(csv_file, :headers => false, encoding: "ISO8859-1:utf-8")
      puts "#{data.count} rows #{data[0].count} columns"
      puts "---"
      puts "#{data[0]}"
      puts "---"
      print_header(data[0])
    end

    desc :subset, "create a subset of the data"
    method_option :line, type: :numeric, aliases: '-l', default: 1000
    def subset(csv_file, output)
      path = csv_file
      output_directory =  output #"/Users/ytbryan/Desktop/output/subset-2015.csv" #output directory
      # options[:num] == nil ? (stop = 10) : (stop = options[:num])
      stop = options[:line]
      counter = 0
      CSV.foreach(path, :headers => false, encoding: "ISO8859-1:utf-8") do |row|
        exit if counter == stop
        begin
          counter = counter + 1
          CSV.open(output_directory, "a+") do |csv|
            csv << row
          end
        rescue
        end
      end
    end

    # desc :subsetagain, ""
    # def subsetagain csv_file, output, value=10
    #   path = csv_file
    #   output_directory =  output #"/Users/ytbryan/Desktop/output/subset-2015.csv" #output directory
    #   stop = value
    #   counter = 0
    #   CSV.foreach(path, :headers => false, :row_sep => "\r\n", encoding: "ISO8859-1:utf-8") do |row|
    #     exit if counter == stop
    #     begin
    #       counter = counter + 1
    #       CSV.open(output_directory, "a+") do |csv|
    #         csv << row
    #       end
    #     rescue
    #     end
    #   end
    # end

    private

    def print_header array
      puts array.join(",") if array != nil
    end

    def process_options headers, rowsep, utf
      if headers == nil
        headers = true
      else
        headers = headers
      end
      return true, "\r\n" , "ISO8859-1:utf-8"
    end

    def masking(value)
      value != nil ? answer = Digest::MD5.hexdigest(value) : answer
    end

    def score( array )
      hash = Hash.new(0)
      array.each{|key| hash[key] += 1}
      hash
    end

    def print_progress current, total
      percent = current/total * 100
      STDOUT.write "\r #{index} - #{percent}% completed."
    end

  end
end
