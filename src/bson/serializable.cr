module BSON::Serializable
  # This annotation can be used to ignore or rename properties.
  #
  # ```
  # @[BSON::Prop(ignore: true)]
  # property ignored_property : Type
  # @[BSON::Prop(key: new_name)]
  # property renamed_property
  # ```
  annotation BSON::Prop
  end

  macro included
    {% verbatim do %}

    # Allocate an instance and copies data from a BSON struct.
    #
    # ```
    # class User
    #   include BSON::Serializable
    #   property name : String
    # end
    #
    # data = BSON.new
    # data["name"] = "John"
    # User.new(data)
    # ```
    def self.new(bson : BSON::Field)
      self.from_bson bson
    end

    # NOTE: See `self.new`.
    def self.from_bson(bson : BSON::Field)
      instance = allocate

      unless bson.is_a? BSON
        raise "Invalid bson"
      end

      bson = bson.as(BSON)

      {% for ivar in @type.instance_vars %}
        {% ann = ivar.annotation(BSON::Prop) %}
        {% types = ivar.type.union_types.select { |t| t != Nil } %}
        {% key = ivar.name %}
        {% bson_key = ann && ann[:key] || ivar.name %}

        {% unless ann && ann[:ignore] %}
          if bson.has_key?("{{ bson_key }}") && !bson["{{ bson_key }}"].nil?
            bson_value = bson["{{ bson_key }}"]

            case bson_value
            {% for typ in types %}
            {% if typ <= BSON::Serializable || typ.class.has_method? :from_bson %}
            when BSON::Field
              instance.{{ key }} = {{ typ }}.from_bson(bson_value)
            {% else %}
            when {{ typ }}
              instance.{{ key }} = bson_value.as({{ typ }})
            {% end %}
            {% end %}
            else
              raise Exception.new "Unable to deserialize key '#{{{key.stringify}}}' for type '#{{{@type.stringify}}}'."
            end
          {% if !ivar.type.nilable? %}
          else
            # The key is required but was not found - or nil.
            raise Exception.new "Unable to deserialize key '#{{{key.stringify}}}' for type '#{{{@type.stringify}}}'."
          {% else %}
          else
            instance.{{ key }} = nil
          {% end %}
          end
        {% end %}
      {% end %}

      instance
    end

    # Converts to a BSON representation.
    #
    # ```
    # user = User.new name: "John"
    # bson = user.to_bson
    # ```
    def to_bson(bson = BSON.new, prefix = "")
      {% for ivar in @type.instance_vars %}
        {% ann = ivar.annotation(BSON::Prop) %}
        {% typ = ivar.type.union_types.select { |t| t != Nil }[0] %}
        {% key = ivar.name %}
        {% bson_key = ann && ann[:key] || ivar.name %}
        {% unless ann && ann[:ignore] %}
          {% unless ann && ann[:emit_null] %}
            unless self.{{ key }}.nil?
          {% end %}
            {% if typ <= Array %}
              bson.append_array("#{prefix}{{ bson_key }}") do |_, child|
                self.{{ key }}.try &.to_bson(child)
              end
            {% elsif typ <= Hash || typ <= NamedTuple %}
              bson.append_document("#{prefix}{{ bson_key }}") do |child|
                self.{{ key }}.try &.to_bson(child)
              end
            {% elsif typ.has_method? :to_bson %}
              bson["#{prefix}{{ bson_key }}"] = self.{{ key }}.to_bson
            {% else %}
              bson["#{prefix}{{ bson_key }}"] = self.{{ key }}
            {% end %}
          {% unless ann && ann[:emit_null] %}
            end
          {% end %}
        {% end %}
      {% end %}
      bson
    end

    {% end %}
  end
end
