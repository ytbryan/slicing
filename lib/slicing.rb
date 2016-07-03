require "slicing/version"
require 'thor'
require 'csv'
require 'digest/md5'

module Slicing
  class Base < Thor
    check_unknown_options!
    package_name 'slicing'
    default_task :hello

    desc :mask, ""
    def mask path, column_name, output_path
      # array = [1,2,3,4,5,6] #great, this works
      original = CSV.read(path, { headers: true, return_headers: true, :encoding => "ISO8859-1:utf-8"})
      #is there a way to figure out
      #loop through and find the column name. if you cannot find it, exit.

      CSV.open(output_path, 'w') do |csv|
        original.each do |row|
          #apply mask on the column
          #save it back to the csv
          csv << array
        end
      end
    end


    desc :rm, ""
    method_option :encoding, type: :boolean, aliases: '-e'
    def rm path, column_name, output
      original = CSV.read(path, { headers: true, return_headers: true, :encoding => "ISO8859-1:utf-8"})
      original.delete(column_name)
      # data = CSV.read(path, :headers=> false, :encoding => "ISO8859-1:utf-8") #2014
      # data.delete(column_name)
      CSV.open(output, 'w') do |csv|
        original.each do |row|
          csv << row
        end
      end

      # CSV.open(output,"a+") do |csv|
      #   data.each_with_index do |row,index|
      #     csv << row
      #   end
      # end
    end

    desc :rmagain, ""
    def rmagain path, column_name, output
      # original = CSV.read(path,{ headers: true, return_headers: true, encoding: "ISO8859-1:utf-8", row_sep: "\r\n"})
      original = CSV.read(path, :headers=> false, :return_headers => true, :row_sep => "\r\n", :encoding => "ISO8859-1:utf-8") #2014
      original.delete(column_name)
      CSV.open(output, 'w') do |csv|
        original.each do |row|
          csv << row
        end
      end

      # CSV.open(output,"a+") do |csv|
      #   data.each_with_index do |row,index|
      #     csv << row
      #   end
      # end
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
      data = CSV.read(csv_file, :headers => false, encoding: "ISO8859-1:utf-8")
      puts "#{data.count} rows"
    end

    desc :subset, ""
    method_options :num, type: :numeric, aliases: '-n'
    def subset(csv_file, output)
      path = csv_file
      output_directory =  output #"/Users/ytbryan/Desktop/output/subset-2015.csv" #output directory
      options[:num] == nil ? (stop = 10) : (stop = options[:num])
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


    desc :subsetagain, ""
    def subsetagain csv_file, output, value=10
      path = csv_file
      output_directory =  output #"/Users/ytbryan/Desktop/output/subset-2015.csv" #output directory
      stop = value
      counter = 0
      CSV.foreach(path, :headers => false, :row_sep => "\r\n", encoding: "ISO8859-1:utf-8") do |row|
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

    def masking(value)
      value != nil ? answer = Digest::MD5.hexdigest(value) : answer
      # if value != nil
      #   return Digest::MD5.hexdigest(value)
      # else
      #   return ""
      # end
    end

  end
end
