require "slicing/version"
require 'digest/md5'
require 'thor'
require 'csv'

module Slicing
  class Base < Thor
    check_unknown_options!
    package_name 'slicing'
    default_task :help


    desc :produce, "produce output.csv with the column value equal to given value"
    def produce path, column_name, value, output
      index = 0
      str = ""
      CSV.foreach(path, :headers => true, encoding: "ISO8859-1:utf-8") do |row|
        str = row
        break
      end
      index = str.index(column_name)
      answer = 0
      CSV.open(output, "a+") do |csv|
        CSV.foreach(path) do |row|
          csv << row if row[index] == value
        end
      end
    end


    desc :replace, "replace original string with new string in file"
    def replace path, output, original, new_string
      File.open(output, 'w') { |file|
        File.readlines(path).each do |line|
          # file.write(line) if line.strip != ""
          new_line = line.gsub(original, new_string) if line != nil
          file.write(new_line)
        end
      }
    end


    desc :cleanup, "clean up by removing rows no value"
    def cleanup path, output
      File.open(output, 'w') { |file|
        File.readlines(path).each do |line|
          file.write(line) if line.strip != ""
        end
      }
    end

    desc :merge, "merge two csv files either horizontally or vertically"
    def merge path, path2, side
      File.open(path, 'a+') { |file|
        File.readlines(path2).each do |line|
          file.write(line)
        end
      }
    end

    desc :clean, "clean up by removing rows with column value"
    def clean path, output, name, value

      index = -1
      str = ""
      CSV.foreach(path, :headers => false, encoding: "ISO8859-1:utf-8") do |row|
        str = row
        break
      end
      # puts str
      index = str.index(name)
      # puts index
      File.open(output, 'w') { |file|
        file.write(str.join(",") + "\n")
        CSV.foreach(path,:headers=> true, :encoding => "ISO8859-1:utf-8") do |line|
          file.write(line) if line[index] == value
        end
      }
    end

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

    # desc :cat, "cat two csv files and keep the headers using the first csv"
    # def cat path, path_column, path2, path2_column, output
    #
    # end
    #
    # desc :combine, "combine"
    # def combine path, path_column, path2, path2_column, output
    #
    # end

    desc :append, "append a value to all rows"
    def append path, output, value
      data_to_merge = CSV.read(path,:headers=> true, :encoding => "ISO8859-1:utf-8") #TODO: is this a data
      CSV.open(output, "a+") do |csv|
        data_to_merge.each_with_index do |data,index|
          csv << data.push(value)
        end
      end
    end

    desc :keep, "keep the columns"
    def keep path, output, *column
      data = CSV.read(path, :headers=> true, :encoding => "ISO8859-1:utf-8") #2014
      header = data[0]
      column_array = []
      column.size.times do |index|
        column_array.push(header.index(column[index]))
      end
      CSV.open(output,"a+") do |csv|
        data.each_with_index do |row,index|
          array = []
          column.size.times do |value|
            array.push(row[column[value]])
          end
          csv << array
        end
      end
    end


    desc :equal, "calculate the value equal to given value"
    def equal path, column_name, value
      index = 0
      str = ""
      CSV.foreach(path, :headers => true, encoding: "ISO8859-1:utf-8") do |row|
        str = row
        break
      end
      # array = str.to_s.split(",")
      index = str.index(column_name)
      #get the number
      answer = 0
      CSV.foreach(path) do |row|
        answer = answer + 1 if row[index] == value
      end
      puts answer
    end



    desc :remove, "remove a header"
    def remove path, output
      index = 0
      CSV.foreach(path) do |row|
        CSV.open(output, "a+") do |csv|
          if index != 0
            csv << row
          end
        end
        index = index +1
      end
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
        puts "----"
        print_header_with_quote(row)
        exit
      end
    end

    desc :unique, "calculate number of unique values in column"
    def unique path, column_name
      data = CSV.read(path, :headers => true, return_headers: true, encoding: "ISO8859-1:utf-8")
      array = data[column_name]
      puts array.uniq.count if array != nil
    end

    # desc :countagain, "count the number of rows and columns"
    # method_option :utf, type: :string, aliases: '-u', default: "ISO8859-1:utf-8"
    # method_option :headers, type: :boolean, aliases: '-h', default: true
    # method_option :rowsep, type: :string, aliases: '-r', default: nil
    # def countagain path
    #     counter = 0
    #     if options[:rowsep] != nil
    #       CSV.foreach(path, :headers => false, encoding: "ISO8859-1:utf-8", :row_sep => "\r\n" ) do |row|
    #       # CSV.foreach(path, { headers: options[:headers], return_headers: options[:headers], :row_sep=> options[:rowsep], :encoding => options[:utf]}) do |row|
    #         STDOUT.write "\r #{counter}"
    #         counter = counter + 1
    #       end
    #     else
    #       CSV.foreach(path, :headers => false, encoding: "ISO8859-1:utf-8", :row_sep => "\r\n" ) do |row|
    #         STDOUT.write "\r #{counter}"
    #         counter = counter + 1
    #       end
    #     end
    #   # data = CSV.read(csv_file, :headers => false, encoding: "ISO8859-1:utf-8")
    #   # puts "#{data.count} rows #{data[0].count} columns"
    #   puts "---"
    #   # puts "#{data[0]}"
    #   puts "---"
    #   # print_header(data[0])
    #   puts "---"
    #   # print_header_with_quote(data[0])
    # end


    desc :count, "count the number of rows and columns"
    def count csv_file
      data = CSV.read(csv_file, :headers => false, encoding: "ISO8859-1:utf-8")
      puts "#{data.count} rows #{data[0].count} columns"
      # puts "---"
      # puts "#{data[0]}"
      # puts "---"
      # print_header(data[0])
      puts "---"
      print_header_with_quote(data[0])
      puts "---"
      print_header_with_no_quote(data[0])
    end

    desc :subset, "create a subset of the data"
    method_option :line, type: :numeric, aliases: '-l', default: 1000
    def subset(csv_file, output)
      path = csv_file
      output_directory =  output #"/Users/ytbryan/Desktop/output/subset-2015.csv" #output directory
      stop = options[:line]
      counter = 0
      CSV.foreach(path, :headers => false, encoding: "ISO8859-1:utf-8") do |row|
        puts row
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

    private

    def print_header array
      puts array.join(",") if array != nil
    end

    def print_header_with_no_quote array
      puts "#{array.join(" ")}" if array != nil
    end

    def print_header_with_quote array
      puts "'#{array.join("' '")}'" if array != nil
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

    # def print_progress2 current
    #   percent = current/total * 100
    #   STDOUT.write "\r #{index} - #{percent}% completed."
    # end

  end
end
