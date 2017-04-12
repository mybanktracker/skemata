# frozen_string_literal: true
module Schemata
  class DSL
    # Make a new type
    class NodeMethodChain < Array; end

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
        dsl = new(Node.new(opts))
        dsl.instance_eval(&block)
        opts.fetch(:is_root, true) ? dsl.node.data.to_json : dsl.node.data
      end
    end

    #
    # Prepares DSL instance by assigning Node
    # @param node [Node] Data object
    #
    # @return [DSL] A DSL class.
    def initialize(node)
      raise(
        ArgumentError, 'DSL must be provided with a Schemata::Node type!'
      ) unless node.is_a?(Node)

      @node = node
    end

    # rubocop:disable Style/MethodMissing
    # TODO: special token so we can define respond_to_missing?
    def method_missing(name, *args, &block)
      node.decorate(name, *args, &block)
    end
    # rubocop:enable Style/MethodMissing

    #
    # Delegator to NodeMethodChain.new
    # @param *args [varargs]
    #
    # @return [NodeMethodChain]
    def nested(*args)
      NodeMethodChain.new(args)
    end

    attr_reader :node
  end
end
