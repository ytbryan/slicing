require "slicing/version"
require 'digest/md5'
require 'thor'
require 'csv'
require 'pg'
require 'sequel'
require 'open3'

module Slicing
  class Base < Thor
    check_unknown_options!
    package_name 'slicing'
    default_task :help

    desc :import, "import"
    def import path
      conn = PG.connect( dbname: 'sales' )

      conn.exec( "SELECT * FROM stat_activity" ) do |result|
        puts "     PID | User             | Query"
        result.each do |row|
          puts " %7d | %-16s | %s " %
            row.values_at('procpid', 'usename', 'current_query')
        end
      end
    end

    desc :megalist, "mega list"
    def megalist path
      puts "hello"

      file_csv = CSV.read(path,:headers=> false, :encoding => "ISO8859-1:utf-8")
      # puts file_csv[0]
      headers = file_csv[0].to_a if file_csv != nil
      if headers != nil
        headers.each_with_index do |each_column,index|
          array = file_csv[each_column]
          puts array.uniq
          puts "--"
          puts "#{array.uniq.count} items"
        end
      end

    end


    desc :createtest, "test"
    def createtest path

    end

    desc :test, "test"
    def test path
      # conn = PG.connect( dbname: 'sales' )

      # db = Sequel.postgres("sales")
      db = Sequel.connect("postgres://ytbryan:workhard@localhost:5432/sales",
  :max_connections => 10, :logger => nil)
      db.copy_into(:stat_activity, format: :csv, opts: "HEADER", data: File.read(path))

    end

    desc :sum, "compute the sum of a column"
    def sum path, column
      array = Slicing.read(path)
      specific_column_array = array[column] if column != nil
      answer = Slicing.sum(specific_column_array,column)
      puts "#{answer}"
    end

    desc :distinct, "find distinct count of a column"
    def distinct path, column
      array = Slicing.read(path)
      specific_column_array = array[column] if column != nil
      answer = Slicing.distinct_count(specific_column_array)
      puts "#{answer}"
      puts "#{column}:#{answer}"
    end

    desc :dimension, "set two dimensions of a csv file"
    def dimension path, column1, column2
      #
    end

    desc :quick, "use wc -l to count"
    def quick path
      output = Open3.popen3("wc -l #{path}") { |stdin, stdout, stderr, wait_thr| stdout.read }
      puts "#{output.split(" ")[0]} rows" if output != nil
      Slicing.head(path)
    end

    desc :sample, "generate a sample file"
    def sample output, row, *columns
      #HEADERS
      CSV.open(output, "a+") do |csv|
        csv << columns
      end

      #produce a file based on hte path
      CSV.open(output, "a+") do |csv|
        row.to_i.times do
          array = generate_random_array(columns.count)
          csv << array
        end
      end

    end

    desc :info, "provide file size info"
    def info path
      compressed_file_size = File.size(path).to_f / 2**20
      formatted_file_size = '%.6f' % compressed_file_size
      puts "Estimated #{formatted_file_size} mb"
    end

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
    def merge path, path2, output # side
      File.open(output, 'w') { |file|
          File.readlines(path).each do |line|
            file.write(line)
          end

          File.readlines(path2).each do |line|
            file.write(line)
          end

          # index = 0

          # CSV.foreach(path,:headers=> true, :encoding => "ISO8859-1:utf-8") do |line|
          #   file.write("#{line}\n")
          # end
          #
          # CSV.foreach(path2,:headers=> true, :encoding => "ISO8859-1:utf-8") do |line|
          #   file.write("#{line}\n")
          # end
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

      index = str.index(name)

      File.open(output, 'w') { |file|
        file.write(str.join(",") + "\n")
        CSV.foreach(path,:headers=> true, :encoding => "ISO8859-1:utf-8") do |line|
          file.write(line) if line[index] == value
        end
      }
    end

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

      index = str.index(column_name)

      answer = 0
      CSV.foreach(path) do |row|
        answer = answer + 1 if row[index] == value
      end
      puts answer
    end

    desc :remove, "remove a header"
    def remove path, output
      index = 0
      CSV.foreach(path, encoding: "ISO8859-1:utf-8") do |row|
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
      CSV.foreach(path, encoding: "ISO8859-1:utf-8") do |row|
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
      Slicing.head(csv_file)
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
      Slicing.print_header_with_quote(data[0])
      puts "---"
      Slicing.print_header_with_no_quote(data[0])
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

    def generate_random_array value
      answer = []
      value.times do
        answer.push(randomise())
      end
      return answer
    end


    def randomise
      return (0...8).map { (65 + rand(26)).chr }.join
    end
    # def print_progress2 current
    #   percent = current/total * 100
    #   STDOUT.write "\r #{index} - #{percent}% completed."
    # end

  end

  def self.read path
    return CSV.read(path, :headers => true, encoding: "ISO8859-1:utf-8")
  end


  def self.head csv_file
    CSV.foreach(csv_file, :headers => false, encoding: "ISO8859-1:utf-8") do |row|
      # puts row
      puts "----"
      puts "#{row.count} columns"
      puts "----"
      print_header(row)
      puts "----"
      print_header_with_quote(row)
      exit
    end
  end

  def self.print_header array
    puts array.join(",") if array != nil
  end

  def self.print_header_with_no_quote array
    puts "#{array.join(" ")}" if array != nil
  end

  def self.print_header_with_quote array
    puts "'#{array.join("' '")}'" if array != nil
  end

  def self.golang
    system("awk ")
  end

  def self.awk
    system("awk ")
  end

  ######################
  ### SLICING 2.0
  ######################

  def self.distinct array
    return array.uniq
  end

  def self.distinct_count array
    return array.uniq.count
  end

  def self.sum array, column
    answer = 0
    array.each do |each_integer|
      if each_integer != nil && self.is_number?(each_integer) == true
        answer = answer + each_integer.to_f
      end
    end
    return answer
  end

  def self.is_number? string
    true if Float(string) rescue false
  end

  def self.import path

  end

end
