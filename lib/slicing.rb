require "slicing/version"
require 'thor'
require 'csv'

module Slicing
  class Base < Thor
    check_unknown_options!
    package_name 'slicing'
    default_task :hello

    desc :rm, ""
    def rm path, column_name, output
      data = CSV.read(path, :headers=> false, :encoding => "ISO8859-1:utf-8") #2014
      data.delete(column_name)
      CSV.open(output,"a+") do |csv|
        data.each_with_index do |row,index|
          csv << row
        end
      end
    end


    desc :first, ""
    def first csv_file #, value=100
      stop = 100
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

    desc :head, ""
    def head csv_file
      CSV.foreach(csv_file, :headers => false, encoding: "ISO8859-1:utf-8") do |row|
        puts row
        puts "----"
        puts "#{row.count} columns"
        exit
      end
    end


    desc :count, ""
    def count csv_file
      data = CSV.read(csv_file)
      puts "#{data.count} rows"
    end

    desc :subset, ""
    def subset csv_file, output, value=10
      path = csv_file
      output_directory =  output #"/Users/ytbryan/Desktop/output/subset-2015.csv" #output directory
      stop = value
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

  end
end
