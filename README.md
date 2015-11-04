# Fluent::Plugin::XmlParser

Fluent plugin for Parsing XML Input

## Installation

Add this line to your application's Gemfile:

    gem 'fluent-plugin-xml-parser'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fluent-plugin-xml-parser

## Usage

fluent-plugin-xml-parser provides input data conversion from XML to JSON for
simple case, like sensor data. It can be specified at source directive as
'format' option.

The followings are an example description for Libelium SmartCity sensor data.

```

<source>
  type mqtt
  bind 127.0.0.1
  port 1883
  format xml
  time_xpath '["cap:alert/cap:info/cap:onset", "text"]'
  attr_xpaths '[[null, "description"], ["cap:alert/cap:info/cap:parameter/cap:valueName", "text"]]'
  value_xpaths '[["cap:alert/cap:info/cap:description", "text"], ["cap:alert/cap:info/cap:parameter/cap:value", "text"]]'
</source>

```

time_xpath specifies timestamp filed value. An array with two strings means xpath of
the value and the attribute of the XML element (name, text etc).

attr_xpaths indicates attribute name of the target value. Each array with two strings
means xpath of the attribute name and the attribute of the XML element (name, text etc).
XPath can be omitted as 'null' and specify your own attribute name as the second
parameter.

value_xpaths indicates the target value to be extracted. Each array with two strings
means xpath of the target value and the attribute of the XML element (name, text etc).
XPath can be omitted as 'null' and specify your own value as the second parameter.

The extracted fields are packed into Hash structure (record field) to emit the next procedure in fluentd.

You can check your own XML data structure by using irb or pry

```

require 'rexml/document'
doc = REXML::Document.new(open("test.xml"))
doc.elements['cap:alert/cap:info'].children

```

## Contributing

1. Fork it ( http://github.com/toyokazu/fluent-plugin-xml-parser/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

