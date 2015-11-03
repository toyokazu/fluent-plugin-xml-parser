require 'rexml/document'
module Fluent
  class TextParser
    class XmlParser < Parser
      # Register this parser as "xml"
      Plugin.register_parser("xml", self)

      # How to specify the target attributes and values
      # The followings are an example description for Libelium SmartCity sensor data.
      #
      # attr_xpaths '[[null, "@timestamp"], ["cap:alert/cap:info/cap:parameter/cap:valueName", "text"], [null, "location"]]'
      # value_xpaths '[["cap:alert/cap:info/cap:onset", "text"], ["cap:alert/cap:info/cap:parameter/cap:value", "text"], [null, "Kyoto"]]'
      #
      # attr_xpaths indicates attribute name of the target value. Each array with two strings
      # means xpath of the attribute name and the attribute of the XML element (name, text etc).
      # XPath can be omitted as 'nil' and specify your own attribute name as the second
      # parameter.
      # 
      # value_xpaths indicates the target value to be extracted. Each array with two strings
      # means xpath of the target value and the attribute of the XML element (name, text etc).
      # XPath can be omitted as 'nil' and specify your own value as the second parameter.
      #
      # You can check your own XML data structure by using irb or pry
      # require 'rexml/document'
      # doc = REXML::Document.new(open("test.xml"))
      # doc.elements['cap:alert/cap:info'].children
      #
      config_param :attr_xpaths, :string, :default => '[]'
      config_param :value_xpaths, :string, :default => '[]'
      config_param :time_format, :string, :default => nil # time_format is configurable
      # This method is called after config_params have read configuration parameters
      def configure(conf)
        super

        @attr_xpaths = json_parse(conf['attr_xpaths'])
        @value_xpaths = json_parse(conf['value_xpaths'])
        @time_format = conf['time_format']
        # TimeParser class is already given. It takes a single argument as the time format
        # to parse the time string with.
        @time_parser = TimeParser.new(@time_format)
      end

      # This is the main method. The input "text" is the unit of data to be parsed.
      # If this is the in_tail plugin, it would be a line. If this is for in_syslog,
      # it is a single syslog message.
      def parse(text)
        doc = REXML::Document.new(text)
        record = {}
        attrs = @attr_xpaths.map do |attr_xpath|
          if attr_xpath[0].nil? # when null is specified
            attr_xpath[1] # second parameter is used as the attribute name
          else # otherwise, the target attribute name is extracted from XML
            doc.elements[attr_xpath[0]].method(attr_xpath[1]).call
          end
        end
        values = @value_xpaths.map do |value_xpath|
          if attr_xpath[0].nil? # when null is specified
            attr_xpath[1] # second parameter is used as the target value
          else # otherwise, the target value is extracted from XML
            doc.elements[value_xpath[0]].method(value_xpath[1]).call
          end
        end
        attrs.size.times do |i|
          if i == 0 # time value
            @time = @time_parser.parse(values[i])
            record[attrs[i]] = @time
          else
            record[attrs[i]] = values[i]
          end
        end
        yield @time, record
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
