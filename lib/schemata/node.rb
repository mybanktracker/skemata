# frozen_string_literal: true

module Schemata
  class Node
    ALLOWED_OPTS = %i[type root_object].freeze

    class << self
      #
      # Draw a schema.org node. Creates a new DSL class for each child node.
      # @param opts = {} [Hash] Options hash
      #   root_object (required): Object you wish to serialize
      #   type        (required): schema.org type
      #   is_root     (optional): Is this the top level object
      # @param &block [Block] DSL schema definition
      #
      # @return [String] schema.org JSON structure
      def draw(opts = {}, &block)
        raise(
          ArgumentError, 'Options must include schema.org type,'\
          ' and a root_object to serialize'
        ) unless (opts.keys & ALLOWED_OPTS).count > 1

        opts[:is_root] = true unless opts.key?(:is_root)

        node = new(opts)
        node.instance_eval(&block)
        opts[:is_root] ? node.data.to_json : node.data
      end
    end

    # Make a new type
    class NodeMethodChain < Array; end

    #
    # Prepares internal data hash and assigns locals
    # @param opts = {} [Hash] See self.draw for valid opts
    #
    # @return [DSL] A schema.org DSL class.
    def initialize(opts = {})
      ALLOWED_OPTS.each { |o| instance_variable_set("@#{o}", opts[o]) }
      @data = { '@type' => type }
      @data['@context'] = 'https://schema.org' if opts[:is_root]
    end

    #
    # Delegator to NodeMethodChain.new
    # @param *args [varargs]
    #
    # @return [NodeMethodChain]
    def nested(*args)
      NodeMethodChain.new(args)
    end

    # TODO: special token so we can define respond_to_missing?
    def method_missing(name, *args, &block)
      # Draw another node
      return route_block(name, *args, &block) if block.present?
      # Or populate the hash
      data[attify_token(name)] = extract(args.first || name.to_sym)
    end

    attr_reader :data

    private

    attr_reader :root_object, :type

    RESERVED_SCHEMA_TOKENS = %w[id type context].freeze
    #
    # Interpolate @ into string of reserved schema.org names
    # @param token [String] Key
    #
    # @return [String]
    def attify_token(token)
      RESERVED_SCHEMA_TOKENS.include?(token) ? "@#{token}" : token
    end

    #
    # Driver for #fetch_property. If passed an NodeMethodChain (Array), fold
    # the chain of methods until the final value. If passed a Symbol,
    # just extract that single method.
    #
    # @param property [Symbol|NodeMethodChain] Propert(ies) to extract
    #
    # @return [Object] Serializable value
    def extract(property)
      case property
      when NodeMethodChain
        property.inject(root_object, &method(:fetch_property))
      when Symbol
        fetch_property(root_object, property)
      else property
      end
    rescue NoMethodError, ArgumentError
      nil
    end

    #
    # Extract property from object, if Hash, look up via #[]
    #
    # @param object [Object] Object to serialize
    # @param property [Symbol] Accessor signature
    #
    # @return [Object] Serializable value
    def fetch_property(object, property)
      object.send(object.is_a?(Hash) ? :fetch : :send, property)
    end

    def find_property(*props)
      props.inject(nil) do |m, e|
        next m if m.present?
        extract(e.to_s.underscore.to_sym)
      end
    end

    #
    # Draw a new schema.org node and merge it into the current serializable
    # hash.
    #
    # @param token [String] Name of DSL / Hash entry
    # @param type [String] schema.org type
    # @param property [Object] Anything, but if symbol,
    #   will extract from #root_object
    # @param &block [Block] DSL definition
    #
    # @return [Hash] Hash#merge! return value with new node
    def internal_draw(token, type, property, &block)
      property = root_object.send(property) if property.is_a?(Symbol)
      data.merge!(
        token.to_s => self.class.draw(
          { type: type, root_object: property, is_root: false },
          &block
        )
      ) if property.present?
    end

    #
    # If a schema entry is passed a block, extract the child's root_object
    # attribute and draw a new node. Attempts to infer the attribute name.
    #
    # The token is the schema definition key (e.g. a function invocation),
    # the type is the schema.org object type, and the last key is the explicit
    # attribute on the current node's root object. If only the token is
    # provided, or if both the token and the type are provided, we try to
    # extract an attribute with either of those names before falling back to
    # null.
    #
    # @param token [String] Invoked method name in DSL.draw block body
    # @param *args [Array] Contains [type, token]
    # @param &block [Block] The DSL definition of the child object
    #
    # @return [Hash] A copy of the data hash as returned by Hash#merge!
    def route_block(token, *args, &block)
      type, prop = args.shift(2)

      # Explicitly defined property
      child_root = extract(prop) if prop.is_a?(Symbol)

      # Hash key / token is type
      child_root = extract(token.titleize.to_sym) if type.nil? && prop.nil?

      # If we still have no data, fold to the first present
      # property by using token and type as keys
      child_root = find_property(token, type) unless child_root.present?

      internal_draw(token, type, child_root, &block)
    end
  end
end
