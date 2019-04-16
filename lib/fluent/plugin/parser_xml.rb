require 'fluent/parser'
require 'rexml/document'
module Fluent
  class TextParser
    class XmlParser < Parser
      # Register this parser as "xml"
      Plugin.register_parser("xml", self)

      # How to specify the target attributes and values
      # The followings are an example description for Libelium SmartCity sensor data.
      #
      # time_xpath '["cap:alert/cap:info/cap:onset", "text"]'
      # attr_xpaths '[[null, "description"], ["cap:alert/cap:info/cap:parameter/cap:valueName", "text"]]'
      # value_xpaths '[["cap:alert/cap:info/cap:description", "text"], ["cap:alert/cap:info/cap:parameter/cap:value", "text"]]'
      #
      # attr_xpaths indicates attribute name of the target value. Each array with two strings
      # means xpath of the attribute name and the attribute of the XML element (name, text etc).
      # XPath can be omitted as 'null' and specify your own attribute name as the second
      # parameter.
      # 
      # value_xpaths indicates the target value to be extracted. Each array with two strings
      # means xpath of the target value and the attribute of the XML element (name, text etc).
      # XPath can be omitted as 'null' and specify your own value as the second parameter.
      #
      # You can check your own XML data structure by using irb or pry
      #
      # require 'rexml/document'
      # doc = REXML::Document.new(open("test.xml"))
      # doc.elements['cap:alert/cap:info'].children
      #
      config_param :time_xpath, :string, :default => nil
      config_param :time_key, :string, :default => nil
      config_param :time_format, :string, :default => nil # time_format is configurable
      config_param :attr_xpaths, :string, :default => '[]'
      config_param :value_xpaths, :string, :default => '[]'
      # This method is called after config_params have read configuration parameters
      def configure(conf)
        super

        if conf['time_xpath'].nil?
          @time_xpath = nil
        else
          @time_xpath = json_parse(conf['time_xpath'])
        end
        @time_key = conf['time_key']
        @time_format = conf['time_format']
        @time_parser = TimeParser.new(@time_format)
        @attr_xpaths = json_parse(conf['attr_xpaths'])
        @value_xpaths = json_parse(conf['value_xpaths'])
        # TimeParser class is already given. It takes a single argument as the time format
        # to parse the time string with.
      end

      # This is the main method. The input "text" is the unit of data to be parsed.
      # If this is the in_tail plugin, it would be a line. If this is for in_syslog,
      # it is a single syslog message.
      def parse(text)
        begin
          doc = REXML::Document.new(text)
          $log.debug doc
          # parse time field
          if @time_xpath.nil?
            time = Fluent::Engine.now
          else
            time = @time_parser.parse(doc.elements[@time_xpath[0]].method(@time_xpath[1]).call)
          end
          record = {}
          if !@time_key.nil?
            record = {@time_key => format_time(@time)}
          end
          attrs = @attr_xpaths.map do |attr_xpath|
            if attr_xpath[0].nil? # when null is specified
              attr_xpath[1] # second parameter is used as the attribute name
            else # otherwise, the target attribute name is extracted from XML
              el = doc.elements[attr_xpath[0]]
              unless el.nil? and attr_xpath.size > 2 
                el.method(attr_xpath[1]).call
              else # unless it's not in the XML and we have a third parameter
                attr_xpath[2] # then the third parameter is used as the target value
              end
            end
          end
          values = @value_xpaths.map do |value_xpath|
            if value_xpath[0].nil? # when null is specified
              value_xpath[1] # second parameter is used as the target value
            else # otherwise, the target value is extracted from XML
              el = doc.elements[value_xpath[0]]
              unless el.nil? and value_xpath.size > 2 
                el.method(value_xpath[1]).call
              else # unless it's not in the XML and we have a third parameter
                value_xpath[2] # then the third parameter is used as the target value
              end
            end
          end
          attrs.size.times do |i|
            record[attrs[i]] = values[i]
          end
          yield time, record
        rescue REXML::ParseException => e
          $log.warn "Parse error", :error => e.to_s
          $log.debug_backtrace(e.backtrace)
        rescue Exception => e
          $log.warn "error", :error => e.to_s
          $log.debug_backtrace(e.backtrace)
        end
      end

      def format_time(time)
        if @time_format.nil?
          Time.at(time).iso8601
        else
          Time.at(time).strftime(@time_format)
        end
      end

      def json_parse message
        begin
          y = Yajl::Parser.new
          y.parse(message)
        rescue
          $log.error "JSON parse error", :error => $!.to_s, :error_class => $!.class.to_s
          $log.warn_backtrace $!.backtrace         
        end
      end
    end
  end
end
