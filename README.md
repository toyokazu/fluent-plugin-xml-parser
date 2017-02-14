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

Fluent::Plugin::XmlParser provides input data conversion from simple XML data
like sensor data into Ruby hash structure for emitting next procedure in fluentd.
In order to enable Fluent::Plugin::XmlParser, 'format xml' option needs to be
specified at 'source' directive.

The followings are an example configuration for reformatting Libelium SmartCity sensor data to fit ElasticSearch received via MQTT protocol([fluent-plugin-mqtt-io](https://github.com/toyokazu/fluent-plugin-mqtt-io)).

```

<source>
  type mqtt
  bind 127.0.0.1
  port 11883
  topic 'Libelium/+/#'
  format xml
  time_xpath '["cap:alert/cap:info/cap:onset", "text"]'
  time_key '@timestamp'
  attr_xpaths '[["cap:alert/cap:info/cap:parameter/cap:valueName", "text"]]'
  value_xpaths '[["cap:alert/cap:info/cap:parameter/cap:value", "text"]]'
  @label @MQTT_OUT
</source>

```

The target XML file of this example is as follows (an old style of Libelium sensor data):

```
<?xml version="1.0" encoding="UTF-8"?>
<cap:alert xmlns:cap="urn:oasis:names:tc:emergency:cap:1.2" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:oasis:names:tc:emergency:cap:1.2 CAP-v1.2-os.xsd">
  <cap:identifier>Libelium_2015-09-21T18:54:24+:00:00495</cap:identifier>
  <cap:sender>Libelium_SmartCity_387243170</cap:sender>
  <cap:sent>2015-09-21T18:54:24+:00:00</cap:sent>
  <cap:status>Actual</cap:status>
  <cap:msgType>Alert</cap:msgType>
  <cap:scope>Public</cap:scope>
  <cap:code>KPI</cap:code>
  <cap:info>
    <cap:category>Other</cap:category>
    <cap:event>Libelium</cap:event>
    <cap:urgency>Inmediate</cap:urgency>
    <cap:severity>Unknown</cap:severity>
    <cap:certainty>Observed</cap:certainty>
    <cap:onset>2015-09-21T18:54:24+:00:00</cap:onset>
    <cap:senderName>Libelium</cap:senderName>
    <cap:headline>Waspmote sensors</cap:headline>
    <cap:description>Sensor data from Waspmote devices: MCP</cap:description>
    <cap:parameter>
      <cap:valueName>MCP</cap:valueName>
      <cap:value>50</cap:value>
    </cap:parameter>
  </cap:info>
</cap:alert>
```

Configurable options are the following:

- **time_xpath**: A value for fluentd time field. An array with two strings means xpath of
  the value and the attribute of the XML element (name, text etc). If this option is
  omitted, current time is used.
- **time_key**: An attribute name of extra timestamp field appended to the record. If Output
  Plugin does not provide timestamp configuration, you can specify field name by this option.
  If this option is omitted, extra timestamp field is not appended.
- **time_format**: You can specify time format. If this is omitted, ISO8601 format is used.
- **attr_xpaths**: indicates attribute name of the target value. Each array with two strings
  means xpath of the attribute name and the attribute of the XML element (name, text etc).
  XPath can be omitted as 'null' and specify your own attribute name as the second
  parameter.
- **value_xpaths**: indicates the target value to be extracted. Each array with two strings
  means xpath of the target value and the attribute of the XML element (name, text etc) and
  each value is stored into the Hash with the key specified at an array instance in the
  **attr_xpaths** with the same index. XPath can be omitted as 'null' and specify your own
  value as the second parameter.

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

