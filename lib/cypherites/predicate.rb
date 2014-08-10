module Cypherites
  class Predicate
    attr_accessor :predicate

    def initialize predicate
      self.predicate = predicate
    end

    def generate *opts
      send("generate_from_#{predicate.class.to_s.downcase}", *opts)
    end

    def self.build predicate, *opts
      self.new(predicate).generate(*opts)
    end

    private

    # parses of predicates    
    def generate_from_string *params
      counter = 0
      p = predicate
        .gsub(/%/, '%%')
        .gsub(/([^\\])\?/){|m| counter +=1; "#{m[0]}%s"} # interrogante no escapado
        .gsub(/^\?/){counter +=1; '%s'} # interrogante al inicio
        .gsub(/\\\?/, '?')

      number_of_params = params.count

      opts = (counter == (params.count - 1)) ? params.pop : {}

      p = apply_opts_to_string(p, opts)

      p % params.map{|prop| to_prop_string(prop)}
    end

    def apply_opts_to_string(p, opts)
      p << " AS #{opts[:as]}" if opts.has_key? :as
      p
    end

    def generate_from_fixnum
      predicate.to_s
    end

    def generate_from_symbol
      predicate.to_s
    end

    def generate_from_hash
      predicates = predicate.fetch(:or){predicate.fech("or")}
      predicates = predicates.map do |args|
        built = self.class.build(*args)
        "(#{built})"
      end
      "(#{predicates.join(' OR ')})"
    end

    # parses of arguments

    def to_prop_string(props)
      if props.is_a? Hash
        hash_to_prop_string(props)
      elsif props.is_a? String
        string_to_prop_string(props)
      else
        props.to_s
      end
    end

    def string_to_prop_string(value, raw=false)
      escaped_string = value.gsub(/['"]/) { |s| "\\#{s}" } if value.is_a?(String) && !raw
      val = value.is_a?(String) && !raw ? "'#{escaped_string}'" : value
    end

    def hash_to_prop_string(props)
      key_values = props.keys.map do |key|
        raw = key.to_s[0, 1] == '_'
        value = props[key]
        val = string_to_prop_string(value, raw)
        "#{raw ? key.to_s[1..-1] : key} : #{val}"
      end
      "{#{key_values.join(', ')}}"
    end

  end
end