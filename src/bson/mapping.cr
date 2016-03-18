class BSON
  macro mapping(properties, strict = false)
    {% for key, value in properties %}
      {% properties[key] = {type: value} unless value.is_a?(HashLiteral) %}
    {% end %}

    {% for key, value in properties %}
      @{{key.id}} : {{value[:type]}} {{ (value[:nilable] ? "?" : "").id }}

      def {{key.id}}=(_{{key.id}} : {{value[:type]}} {{ (value[:nilable] ? "?" : "").id }})
        @{{key.id}} = _{{key.id}}
      end

      def {{key.id}}
        @{{key.id}}
      end
    {% end %}

    def self.new(bson_value : BSON::Value)
      %value = bson_value.value
      unless %value.is_a?(BSON)
        raise "expected value to be a bson object. was #{typeof(%value)}"
      end

      new(%value)
    end

    def initialize(%bson : BSON)
      {% for key, value in properties %}
        %var{key.id} = nil
        %found{key.id} = false
      {% end %}

      %bson.each_pair do |key, value|
        case key
        {% for key, value in properties %}
          when {{(value[:key] || key).id.stringify}}
            %found{key.id} = true
            %var{key.id} =
              {% if value[:nilable] || value[:default] != nil %}
                value.value.try {
              {% end %}
              {% if value[:converter] %}
                {{value[:converter]}}.from_bson(value)
              {% else %}
                {{value[:type]}}.new(value)
              {% end %}
            {% if value[:nilable] || value[:default] != nil %}
            }
            {% end %}
        {% end %}
        else
          {% if strict %}
            raise "unknown bson attribute: #{key}"
          {% end %}
        end
      end

      {% for key, value in properties %}
        {% unless value[:nilable] || value[:default] != nil %}
          if %var{key.id}.is_a?(Nil) && !%found{key.id}
            raise "missing bson attribute: {{(value[:key] || key).id}}"
          end
        {% end %}
      {% end %}

      {% for key, value in properties %}
        {% if value[:nilable] %}
          {% if value[:default] != nil %}
            @{{key.id}} = %found{key.id} ? %var{key.id} : {{value[:default]}}
          {% else %}
            @{{key.id}} = %var{key.id}
          {% end %}
        {% elsif value[:default] != nil %}
          @{{key.id}} = %var{key.id}.is_a?(Nil) ? {{value[:default]}} : %var{key.id}
        {% else %}
          @{{key.id}} = %var{key.id}.not_nil!
        {% end %}
      {% end %}
    end

    def to_bson
      BSON.build do |doc|
        append_to_bson_document(doc)
      end
    end

    def to_bson(appender)
      appender.document do |doc|
        append_to_bson_document(doc)
      end
    end

    private def append_to_bson_document(doc)
      {% for key, value in properties %}
        _{{key.id}} = @{{key.id}}

        {% unless value[:emit_null] %}
          unless _{{key.id}}.is_a?(Nil)
        {% end %}

          doc.field({{value[:key] || key.id.stringify}}) do |appender|
            {% if value[:converter] %}
              if _{{key.id}}
                {{value[:converter]}}.to_bson(_{{key.id}}, appender)
              else
                appender << nil
              end
            {% else %}
              _{{key.id}}.to_bson(appender)
            {% end %}
          end

        {% unless value[:emit_null] %}
          end
        {% end %}
      {% end %}
    end
  end
end
